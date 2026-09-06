//
//  ContactsExplorerApp.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import SwiftUI

@main
struct ContactsExplorerApp: App {
    @State private var viewModel = ContactsExplorerApp.buildContactsListViewModel()

    var body: some Scene {
        WindowGroup {
            ContactsListView(viewModel: viewModel)
        }
    }
}

// MARK: - Composition

private extension ContactsExplorerApp {
    static func buildContactsListViewModel() -> ContactsListViewModel {
        ContactsListViewModel(
            contactsStore: ContactsStore(provider: SystemContactsProvider()),
            favoritesStore: FavoritesStore(defaults: .standard)
        )
    }
}
