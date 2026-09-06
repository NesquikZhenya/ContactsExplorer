//
//  ContactsListViewModel.swift
//  ContactsExplorer
//

import Foundation
import Observation

@Observable
final class ContactsListViewModel {
    enum ViewState {
        case loading
        case permissionDenied
        case failed
        case noContacts
        case noResults(query: String)
        case content([ContactRowModel])
    }

    var searchText = "" {
        didSet { scheduleSearch() }
    }

    private let contactsStore: any ContactsStoring
    private let favoritesStore: any FavoritesStoring

    private(set) var viewState = ViewState.loading

    private var rows: [ContactRowModel] = []
    private var hasLoaded = false
    private var searchTask: Task<Void, Never>?

    init(
        contactsStore: any ContactsStoring,
        favoritesStore: any FavoritesStoring
    ) {
        self.contactsStore = contactsStore
        self.favoritesStore = favoritesStore
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reload()
    }

    func reload() async {
        searchTask?.cancel()

        if rows.isEmpty {
            viewState = .loading
        }

        do {
            try await contactsStore.load()
            rows = makeRows(for: contactsStore.contacts)
            updateContent()
        } catch ContactsError.accessDenied {
            rows.removeAll()
            viewState = .permissionDenied
        } catch {
            if rows.isEmpty {
                viewState = .failed
            }
        }
    }

    func isFavorite(id: String) -> Bool {
        favoritesStore.contains(id: id)
    }

    func toggleFavorite(id: String) {
        favoritesStore.toggle(id: id)
    }

    func contactDetailViewModel(for contactID: String) -> ContactDetailViewModel {
        ContactDetailViewModel(
            contactID: contactID,
            contactsStore: contactsStore,
            favoritesStore: favoritesStore
        )
    }
}

// MARK: - View state

private extension ContactsListViewModel {
    func updateContent() {
        if rows.isEmpty {
            viewState = .noContacts
        } else {
            applySearch()
        }
    }

    func makeRows(for contacts: [Contact]) -> [ContactRowModel] {
        contacts.map {
            ContactRowModel(
                id: $0.id,
                displayName: $0.displayName,
                subtitle: subtitle(for: $0),
                initials: $0.initials,
                thumbnailData: $0.thumbnailData,
                foldedName: folded($0.displayName),
                phoneDigits: $0.phoneNumbers.map { $0.value.filter(\.isWholeNumber) }
            )
        }
    }

    func subtitle(for contact: Contact) -> String? {
        guard let phoneNumber = contact.phoneNumbers.first?.value,
              phoneNumber != contact.displayName else { return nil }
        return phoneNumber
    }
}

// MARK: - Search

private extension ContactsListViewModel {
    func scheduleSearch() {
        searchTask?.cancel()

        guard !rows.isEmpty else { return }

        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            updateContent()
        } else {
            searchTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(250))
                guard let self,
                      !Task.isCancelled,
                      !rows.isEmpty else { return }
                updateContent()
            }
        }
    }

    func applySearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return viewState = .content(rows) }

        let matched = search(for: query)
        viewState = matched.isEmpty ? .noResults(query: query) : .content(matched)
    }

    func search(for query: String) -> [ContactRowModel] {
        if let queryDigits = phoneDigits(in: query) {
            return rows.filter { row in
                row.phoneDigits.contains { $0.contains(queryDigits) }
            }
        }

        let foldedQuery = folded(query)
        return rows.filter { $0.foldedName.contains(foldedQuery) }
    }

    func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    func phoneDigits(in text: String) -> String? {
        guard !text.contains(where: \.isLetter) else { return nil }
        let digits = text.filter(\.isWholeNumber)
        return digits.isEmpty ? nil : digits
    }
}
