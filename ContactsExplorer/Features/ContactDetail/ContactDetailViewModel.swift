//
//  ContactDetailViewModel.swift
//  ContactsExplorer
//

import Foundation
import Observation
import os

@Observable
final class ContactDetailViewModel {
    enum ViewState {
        case unavailable
        case content(Contact)
    }

    private let contactID: String
    private let contactsStore: any ContactsStoring
    private let favoritesStore: any FavoritesStoring

    private(set) var fullImageData: Data?

    var viewState: ViewState {
        if let contact = contactsStore.contacts.first(where: { $0.id == contactID }) {
            .content(contact)
        } else {
            .unavailable
        }
    }

    init(
        contactID: String,
        contactsStore: any ContactsStoring,
        favoritesStore: any FavoritesStoring
    ) {
        self.contactID = contactID
        self.contactsStore = contactsStore
        self.favoritesStore = favoritesStore
    }

    func isFavorite(_ contact: Contact) -> Bool {
        favoritesStore.contains(id: contact.id)
    }

    func toggleFavorite(_ contact: Contact) {
        favoritesStore.toggle(id: contact.id)
    }

    func birthdayText(for contact: Contact) -> String? {
        guard var components = contact.birthday else { return nil }

        let hasYear = components.year != nil
        components.year = components.year ?? Constants.placeholderYear
        guard let date = Calendar.current.date(from: components) else { return nil }

        return hasYear
            ? date.formatted(.dateTime.year().month(.wide).day())
            : date.formatted(.dateTime.month(.wide).day())
    }

    func loadFullImage() async {
        do {
            fullImageData = try await contactsStore.loadFullImage(for: contactID)
        } catch {
            Logger().error("Loading contact image failed: \(String(describing: error))")
        }
    }
}

// MARK: - Constants

private extension ContactDetailViewModel {
    enum Constants {
        static let placeholderYear = 2000
    }
}
