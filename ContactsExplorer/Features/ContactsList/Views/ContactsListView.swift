//
//  ContactsListView.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import SwiftUI

struct ContactsListView: View {
    @Environment(\.openURL) private var openURL

    @Bindable var viewModel: ContactsListViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Strings.title)
                .searchable(text: $viewModel.searchText, prompt: Strings.searchPrompt)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .navigationDestination(for: String.self) { contactID in
                    ContactDetailView(viewModel: viewModel.contactDetailViewModel(for: contactID))
                }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

// MARK: - Subviews

private extension ContactsListView {
    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView(Strings.loading)
        case .permissionDenied:
            permissionDeniedView
        case .failed:
            failedView
        case .noContacts:
            noContactsView
        case .noResults(let query):
            ContentUnavailableView.search(text: query)
        case .content(let contacts):
            contactsList(contacts)
        }
    }

    func contactsList(_ contacts: [ContactRowModel]) -> some View {
        List(contacts) { contact in
            NavigationLink(value: contact.id) {
                ContactRow(
                    model: contact,
                    isFavorite: viewModel.isFavorite(id: contact.id),
                    onToggleFavorite: { viewModel.toggleFavorite(id: contact.id) }
                )
            }
        }
        .refreshable {
            await viewModel.reload()
        }
    }

    var noContactsView: some View {
        ScrollView {
            ContentUnavailableView {
                Label(Strings.noContactsTitle, systemImage: Icons.noContacts)
            } description: {
                Text(Strings.noContactsMessage)
            }
            .containerRelativeFrame(.vertical)
        }
        .refreshable {
            await viewModel.reload()
        }
    }

    var permissionDeniedView: some View {
        ContentUnavailableView {
            Label(Strings.noAccessTitle, systemImage: Icons.noAccess)
        } description: {
            Text(Strings.noAccessMessage)
        } actions: {
            Button(Strings.openSettings) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    var failedView: some View {
        ContentUnavailableView {
            Label(Strings.failedTitle, systemImage: Icons.failed)
        } description: {
            Text(Strings.failedMessage)
        } actions: {
            Button(Strings.tryAgain) {
                Task { await viewModel.reload() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Constants

private extension ContactsListView {
    enum Icons {
        static let noContacts = "person.crop.circle"
        static let noAccess = "lock"
        static let failed = "exclamationmark.triangle"
    }

    enum Strings {
        static let title: LocalizedStringKey = "Contacts"
        static let loading: LocalizedStringKey = "Loading Contacts…"
        static let searchPrompt: LocalizedStringKey = "Name or phone number"

        static let noContactsTitle: LocalizedStringKey = "No Contacts"
        static let noContactsMessage: LocalizedStringKey = "Add contacts to this device, or choose which ones to share."

        static let noAccessTitle: LocalizedStringKey = "No Access to Contacts"
        static let noAccessMessage: LocalizedStringKey = "Allow access to your contacts in Settings to see them here."
        static let openSettings: LocalizedStringKey = "Open Settings"

        static let failedTitle: LocalizedStringKey = "Something Went Wrong"
        static let failedMessage: LocalizedStringKey = "Your contacts could not be loaded. Please try again."
        static let tryAgain: LocalizedStringKey = "Try Again"
    }
}
