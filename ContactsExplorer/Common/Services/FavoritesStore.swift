//
//  FavoritesStore.swift
//  ContactsExplorer
//

import Foundation
import Observation

protocol FavoritesStoring: AnyObject {
    func contains(id: String) -> Bool
    func toggle(id: String)
}

@Observable
final class FavoritesStore: FavoritesStoring {
    private(set) var contactIDs: Set<String>

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        contactIDs = Set(defaults.stringArray(forKey: Keys.contactIDs) ?? [])
    }

    func contains(id: String) -> Bool {
        contactIDs.contains(id)
    }

    func toggle(id: String) {
        if contactIDs.contains(id) {
            contactIDs.remove(id)
        } else {
            contactIDs.insert(id)
        }
        defaults.set(Array(contactIDs), forKey: Keys.contactIDs)
    }
}

// MARK: - Constants

private extension FavoritesStore {
    enum Keys {
        /// Unchanged from the previous implementation so anyone who has already favorited contacts keeps them.
        static let contactIDs = "favoriteContactIDs"
    }
}
