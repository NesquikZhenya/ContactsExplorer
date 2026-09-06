//
//  ContactDetailView.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import SwiftUI

struct ContactDetailView: View {
    @State private var viewModel: ContactDetailViewModel

    init(viewModel: ContactDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .task {
                await viewModel.loadFullImage()
            }
    }
}

// MARK: - Subviews

private extension ContactDetailView {
    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {
        case .unavailable:
            unavailableView
        case .content(let contact):
            detail(for: contact)
        }
    }

    var unavailableView: some View {
        ContentUnavailableView(Strings.unavailableTitle, systemImage: Icons.unavailable)
    }

    func detail(for contact: Contact) -> some View {
        List {
            header(contact)
            details(contact)
            info(contact)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                favoriteButton(contact)
            }
        }
    }

    func header(_ contact: Contact) -> some View {
        Section {
            VStack(spacing: Metrics.headerSpacing) {
                ContactAvatarView(
                    imageData: viewModel.fullImageData ?? contact.thumbnailData,
                    initials: contact.initials,
                    size: .full
                )
                Text(contact.displayName)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    func details(_ contact: Contact) -> some View {
        if contact.phoneNumbers.isEmpty && contact.emails.isEmpty {
            Section {
                Text(Strings.noPhoneOrEmail)
                    .foregroundStyle(.secondary)
            }
        } else {
            if !contact.phoneNumbers.isEmpty {
                Section(Strings.phoneNumbers) {
                    ForEach(contact.phoneNumbers) { phoneNumber in
                        LabeledContent(phoneNumber.label, value: phoneNumber.value)
                    }
                }
            }
            if !contact.emails.isEmpty {
                Section(Strings.emails) {
                    ForEach(contact.emails) { email in
                        LabeledContent(email.label, value: email.value)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func info(_ contact: Contact) -> some View {
        if !contact.organizationName.isEmpty || contact.birthday != nil {
            Section {
                if !contact.organizationName.isEmpty {
                    infoRow(label: Strings.organization, value: contact.organizationName)
                }
                if let birthday = viewModel.birthdayText(for: contact) {
                    infoRow(label: Strings.birthday, value: birthday)
                }
            } header: {
                Text(Strings.info)
                    .font(.subheadline)
            }
        }
    }

    func infoRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }

    func favoriteButton(_ contact: Contact) -> some View {
        FavoriteButton(isFavorite: viewModel.isFavorite(contact), action: { viewModel.toggleFavorite(contact) })
    }
}

// MARK: - Constants

private extension ContactDetailView {
    enum Metrics {
        static let headerSpacing: CGFloat = 12
    }

    enum Icons {
        static let unavailable = "person.crop.circle.badge.exclamationmark"
    }

    enum Strings {
        static let unavailableTitle: LocalizedStringKey = "Contact Unavailable"
        static let noPhoneOrEmail: LocalizedStringKey = "This contact has no phone numbers or emails."
        static let phoneNumbers: LocalizedStringKey = "Phone Numbers"
        static let emails: LocalizedStringKey = "Emails"
        static let organization: LocalizedStringKey = "Organization"
        static let birthday: LocalizedStringKey = "Birthday"
        static let info: LocalizedStringKey = "Info"
    }
}
