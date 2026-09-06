//
//  FavoritesStoreTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@MainActor
struct FavoritesStoreTests {
    @Test("Toggling adds and removes an identifier")
    func togglingAddsAndRemoves() {
        let store = makeStore()

        store.toggle(id: "contact-emma")
        #expect(store.contains(id: "contact-emma"))

        store.toggle(id: "contact-emma")
        #expect(store.contains(id: "contact-emma") == false)
    }

    @Test("Favorites are read back by a store built on the same defaults")
    func favoritesSurviveANewStore() {
        let defaults = makeDefaults()
        let store = FavoritesStore(defaults: defaults)
        store.toggle(id: "contact-emma")
        store.toggle(id: "contact-james")

        let reopened = FavoritesStore(defaults: defaults)

        #expect(reopened.contains(id: "contact-emma"))
        #expect(reopened.contains(id: "contact-james"))
        #expect(reopened.contains(id: "contact-maya") == false)
    }
}

private extension FavoritesStoreTests {
    func makeStore() -> FavoritesStore {
        FavoritesStore(defaults: makeDefaults())
    }

    /// A suite of its own, so the tests never touch the defaults the app uses.
    func makeDefaults() -> UserDefaults {
        let suiteName = "FavoritesStoreTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }
}
