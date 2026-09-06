//
//  ContactsListViewModelTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@MainActor
struct ContactsListViewModelTests {
    @Test("A successful load turns contacts into rows")
    func successfulLoadProducesRows() async {
        let viewModel = makeViewModel(outcome: .contacts(SampleContacts.all))

        await viewModel.loadIfNeeded()

        #expect(viewModel.viewState.rowIdentifiers == SampleContacts.all.map(\.id))
    }

    @Test("An empty address book is reported as having no contacts")
    func emptyAddressBookIsReported() async {
        let viewModel = makeViewModel(outcome: .contacts([]))

        await viewModel.loadIfNeeded()

        #expect(viewModel.viewState.isNoContacts)
    }

    @Test("Denied access is shown as a permission problem, not a failure")
    func deniedAccessIsDistinguishedFromFailure() async {
        let viewModel = makeViewModel(outcome: .accessDenied)

        await viewModel.loadIfNeeded()

        #expect(viewModel.viewState.isPermissionDenied)
    }

    @Test("Any other error is shown as a failure")
    func otherErrorsAreShownAsFailure() async {
        let viewModel = makeViewModel(outcome: .failure)

        await viewModel.loadIfNeeded()

        #expect(viewModel.viewState.isFailed)
    }

    @Test("A failed refresh keeps the contacts already on screen")
    func failedRefreshKeepsExistingRows() async {
        let provider = SwitchableContactsProvider(outcome: .contacts(SampleContacts.all))
        let viewModel = makeViewModel(provider: provider)
        await viewModel.loadIfNeeded()

        provider.outcome = .failure
        await viewModel.reload()

        #expect(viewModel.viewState.rowIdentifiers == SampleContacts.all.map(\.id))
    }

    @Test("Searching without access leaves the permission screen in place")
    func searchingWithoutAccessKeepsThePermissionScreen() async {
        let viewModel = makeViewModel(outcome: .accessDenied)
        await viewModel.loadIfNeeded()

        await search(for: "emma", in: viewModel)
        await search(for: "", in: viewModel)

        #expect(viewModel.viewState.isPermissionDenied)
    }

    @Test("Search matches a name whether or not the query carries diacritics")
    func searchIgnoresDiacritics() async {
        let viewModel = makeViewModel(outcome: .contacts(SampleContacts.all))
        await viewModel.loadIfNeeded()

        await search(for: "jose", in: viewModel)

        #expect(viewModel.viewState.rowIdentifiers == [SampleContacts.accentedName.id])
    }

    @Test("Search matches a phone number other than the one shown in the row")
    func searchMatchesPhoneNumberBeyondTheFirst() async {
        let viewModel = makeViewModel(outcome: .contacts(SampleContacts.all))
        await viewModel.loadIfNeeded()

        await search(for: "612", in: viewModel)

        #expect(viewModel.viewState.rowIdentifiers == [SampleContacts.complete.id])
    }

    @Test("A query containing letters is searched as a name, never as digits")
    func queryWithLettersIsNotTreatedAsPhoneNumber() async {
        let viewModel = makeViewModel(outcome: .contacts(SampleContacts.all))
        await viewModel.loadIfNeeded()

        await search(for: "Emma123", in: viewModel)

        #expect(viewModel.viewState.noResultsQuery == "Emma123")
    }

    @Test("Clearing the query restores every row")
    func clearingTheQueryRestoresAllRows() async {
        let viewModel = makeViewModel(outcome: .contacts(SampleContacts.all))
        await viewModel.loadIfNeeded()
        await search(for: "jose", in: viewModel)

        await search(for: "", in: viewModel)

        #expect(viewModel.viewState.rowIdentifiers == SampleContacts.all.map(\.id))
    }

    @Test("A contact with no name shows its number once, not as title and subtitle both")
    func namelessContactHasNoDuplicateSubtitle() async {
        let viewModel = makeViewModel(outcome: .contacts(SampleContacts.all))
        await viewModel.loadIfNeeded()

        let nameless = viewModel.viewState.rows?.first { $0.id == SampleContacts.nameless.id }
        let named = viewModel.viewState.rows?.first { $0.id == SampleContacts.complete.id }

        #expect(nameless?.displayName == "058-112-2334")
        #expect(nameless?.subtitle == nil)
        #expect(named?.subtitle == "+972 54-123-4567")
    }

    @Test("Favoriting is delegated to the favorites store")
    func favoritingGoesThroughTheFavoritesStore() async {
        let favoritesStore = InMemoryFavoritesStore()
        let viewModel = makeViewModel(outcome: .contacts(SampleContacts.all), favoritesStore: favoritesStore)
        let contactID = SampleContacts.complete.id

        #expect(viewModel.isFavorite(id: contactID) == false)
        viewModel.toggleFavorite(id: contactID)

        #expect(viewModel.isFavorite(id: contactID))
        #expect(favoritesStore.toggledIdentifiers == [contactID])
    }
}

// MARK: - Building the subject

@MainActor
private extension ContactsListViewModelTests {
    func makeViewModel(
        outcome: StubContactsProvider.Outcome,
        favoritesStore: any FavoritesStoring = InMemoryFavoritesStore()
    ) -> ContactsListViewModel {
        ContactsListViewModel(
            contactsStore: ContactsStore(provider: StubContactsProvider(outcome: outcome)),
            favoritesStore: favoritesStore
        )
    }

    func makeViewModel(
        provider: any ContactsProviding,
        favoritesStore: any FavoritesStoring = InMemoryFavoritesStore()
    ) -> ContactsListViewModel {
        ContactsListViewModel(
            contactsStore: ContactsStore(provider: provider),
            favoritesStore: favoritesStore
        )
    }

    /// Typing is debounced, so the result is only observable after the delay.
    func search(for query: String, in viewModel: ContactsListViewModel) async {
        viewModel.searchText = query
        try? await Task.sleep(for: .milliseconds(400))
    }
}

// MARK: - Doubles

private struct StubContactsProvider: ContactsProviding {
    enum Outcome: Sendable {
        case contacts([Contact])
        case accessDenied
        case failure
    }

    let outcome: Outcome

    func fetchContacts() async throws -> [Contact] {
        try outcome.resolve()
    }

    func loadFullImage(for contactID: String) async throws -> Data? {
        nil
    }
}

/// A provider whose outcome can change between loads, so a refresh can be made
/// to fail after a successful first load.
private final class SwitchableContactsProvider: ContactsProviding, @unchecked Sendable {
    var outcome: StubContactsProvider.Outcome

    init(outcome: StubContactsProvider.Outcome) {
        self.outcome = outcome
    }

    func fetchContacts() async throws -> [Contact] {
        try outcome.resolve()
    }

    func loadFullImage(for contactID: String) async throws -> Data? {
        nil
    }
}

private struct ContactsFetchFailure: Error {}

private nonisolated extension StubContactsProvider.Outcome {
    func resolve() throws -> [Contact] {
        switch self {
        case .contacts(let contacts): contacts
        case .accessDenied: throw ContactsError.accessDenied
        case .failure: throw ContactsFetchFailure()
        }
    }
}

private final class InMemoryFavoritesStore: FavoritesStoring {
    private(set) var toggledIdentifiers: [String] = []
    private var identifiers: Set<String> = []

    func contains(id: String) -> Bool {
        identifiers.contains(id)
    }

    func toggle(id: String) {
        toggledIdentifiers.append(id)
        if identifiers.contains(id) {
            identifiers.remove(id)
        } else {
            identifiers.insert(id)
        }
    }
}

// MARK: - Reading the view state

private extension ContactsListViewModel.ViewState {
    var rows: [ContactRowModel]? {
        if case .content(let rows) = self { rows } else { nil }
    }

    var rowIdentifiers: [String]? {
        rows?.map(\.id)
    }

    var noResultsQuery: String? {
        if case .noResults(let query) = self { query } else { nil }
    }

    var isNoContacts: Bool {
        if case .noContacts = self { true } else { false }
    }

    var isPermissionDenied: Bool {
        if case .permissionDenied = self { true } else { false }
    }

    var isFailed: Bool {
        if case .failed = self { true } else { false }
    }
}
