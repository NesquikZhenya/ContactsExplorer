//
//  ContactTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

struct ContactTests {
    @Test("Display name prefers the formatted full name")
    func displayNamePrefersFullName() {
        #expect(SampleContacts.complete.displayName == "Emma Stone")
    }

    @Test("Display name falls back to the organization when there is no personal name")
    func displayNameFallsBackToOrganization() {
        #expect(SampleContacts.organizationOnly.displayName == "Pizza Palace")
    }

    @Test("Display name falls back to a phone number when there is no name at all")
    func displayNameFallsBackToPhoneNumber() {
        #expect(SampleContacts.nameless.displayName == "058-112-2334")
    }

    @Test("Initials come from the given and family names")
    func initialsUseBothNames() {
        #expect(SampleContacts.complete.initials == "ES")
        #expect(SampleContacts.givenNameOnly.initials == "O")
    }

    @Test("A birthday without a year keeps the year absent")
    func birthdayWithoutAYearStaysWithoutOne() {
        let birthday = SampleContacts.givenNameOnly.birthday

        #expect(birthday?.year == nil)
        #expect(birthday?.month == 11)
        #expect(birthday?.day == 6)
    }

    @Test("Two labeled values with the same label and value are interchangeable")
    func labeledValuesWithEqualContentsAreEqual() {
        let phoneNumber = Contact.LabeledValue(label: "mobile", value: "+972 54-123-4567")
        let sameNumberAgain = Contact.LabeledValue(label: "mobile", value: "+972 54-123-4567")

        #expect(phoneNumber == sameNumberAgain)
        #expect(phoneNumber.id == sameNumberAgain.id)
    }

    @Test("A contact rebuilt from identical values equals the one already on screen")
    func aRefetchedContactStaysEqual() {
        let onScreen = SampleContacts.complete
        let refetched = Contact(
            id: onScreen.id,
            givenName: onScreen.givenName,
            familyName: onScreen.familyName,
            fullName: onScreen.fullName,
            organizationName: onScreen.organizationName,
            phoneNumbers: onScreen.phoneNumbers.map { Contact.LabeledValue(label: $0.label, value: $0.value) },
            emails: onScreen.emails.map { Contact.LabeledValue(label: $0.label, value: $0.value) },
            birthday: onScreen.birthday,
            thumbnailData: onScreen.thumbnailData
        )

        #expect(refetched == onScreen)
        #expect(Set([onScreen, refetched]).count == 1)
    }
}
