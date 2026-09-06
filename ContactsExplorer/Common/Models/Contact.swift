//
//  Contact.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Contacts
import Foundation

nonisolated struct Contact: Identifiable, Hashable {
    struct LabeledValue: Identifiable, Hashable {
        let label: String
        let value: String
        var id: String { "\(label)|\(value)" }
    }

    let id: String
    let givenName: String
    let familyName: String
    let fullName: String
    let organizationName: String
    let phoneNumbers: [LabeledValue]
    let emails: [LabeledValue]
    let birthday: DateComponents?
    let thumbnailData: Data?

    var displayName: String {
        if !fullName.isEmpty {
            return fullName
        }
        if !organizationName.isEmpty {
            return organizationName
        }
        return phoneNumbers.first?.value ?? emails.first?.value ?? Strings.noName
    }

    var initials: String {
        let nameInitials = [givenName.first, familyName.first].compactMap { $0 }
        if !nameInitials.isEmpty {
            return String(nameInitials).uppercased()
        }
        if let organizationInitial = organizationName.first {
            return String(organizationInitial).uppercased()
        }
        return "#"
    }
}

nonisolated extension Contact {
    init(_ cnContact: CNContact) {
        id = cnContact.identifier
        givenName = cnContact.givenName
        familyName = cnContact.familyName
        fullName = CNContactFormatter.string(from: cnContact, style: .fullName) ?? ""
        organizationName = cnContact.organizationName
        phoneNumbers = cnContact.phoneNumbers.map { phoneNumber in
            LabeledValue(
                label: phoneNumber.label.map { CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: $0) } ?? Strings.phone,
                value: phoneNumber.value.stringValue
            )
        }
        emails = cnContact.emailAddresses.map { email in
            LabeledValue(
                label: email.label.map { CNLabeledValue<NSString>.localizedString(forLabel: $0) } ?? Strings.email,
                value: email.value as String
            )
        }
        birthday = cnContact.birthday
        thumbnailData = cnContact.thumbnailImageData
    }
}

// MARK: - Constants

private nonisolated extension Contact {
    enum Strings {
        static let noName = String(
            localized: "No Name",
            comment: "Stands in for a contact with no name, organization, phone number or email"
        )
        static let phone = String(
            localized: "phone",
            comment: "Default label for a phone number the address book left unlabeled"
        )
        static let email = String(
            localized: "email",
            comment: "Default label for an email address the address book left unlabeled"
        )
    }
}
