//
//  ContactsProvider.swift
//  ContactsExplorer
//

import Contacts
import Foundation

enum ContactsError: Error {
    case accessDenied
}

nonisolated protocol ContactsProviding: Sendable {
    func fetchContacts() async throws -> [Contact]
    func loadFullImage(for contactID: String) async throws -> Data?
}

actor SystemContactsProvider: ContactsProviding {
    private let store = CNContactStore()

    func fetchContacts() async throws -> [Contact] {
        guard await requestAccessIfNeeded() else {
            throw ContactsError.accessDenied
        }

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .userDefault

        var fetched: [Contact] = []
        try store.enumerateContacts(with: request) { cnContact, stop in
            // Enumeration is synchronous and can run over thousands of records,
            // so cancellation is checked here rather than only at the end.
            guard !Task.isCancelled else {
                stop.pointee = true
                return
            }
            fetched.append(Contact(cnContact))
        }
        try Task.checkCancellation()

        return fetched
    }

    func loadFullImage(for contactID: String) async throws -> Data? {
        guard hasAccess else { return nil }
        let keysToFetch = [CNContactImageDataKey as CNKeyDescriptor]
        return try store.unifiedContact(withIdentifier: contactID, keysToFetch: keysToFetch).imageData
    }
}

// MARK: - Contacts framework

private extension SystemContactsProvider {
    var keysToFetch: [CNKeyDescriptor] {[
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactBirthdayKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]}

    var hasAccess: Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited: true
        default: false
        }
    }

    func requestAccessIfNeeded() async -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            _ = try? await store.requestAccess(for: .contacts)
            return hasAccess
        default:
            return hasAccess
        }
    }
}
