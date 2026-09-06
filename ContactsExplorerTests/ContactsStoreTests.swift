//
//  ContactsStoreTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@MainActor
struct ContactsStoreTests {
    @Test("Losing access drops the address book the store was holding")
    func revokedAccessClearsTheLoadedContacts() async throws {
        let provider = RevocableContactsProvider()
        let store = ContactsStore(provider: provider)

        try await store.load()
        #expect(store.contacts.count == SampleContacts.all.count)

        provider.hasAccess = false
        await #expect(throws: ContactsError.accessDenied) {
            try await store.load()
        }

        #expect(store.contacts.isEmpty)
    }

    @Test("A load that fails for any other reason keeps what was already there")
    func aGenericFailureKeepsTheLoadedContacts() async throws {
        let provider = RevocableContactsProvider()
        let store = ContactsStore(provider: provider)
        try await store.load()

        provider.failure = SomeOtherFailure()
        _ = try? await store.load()

        #expect(store.contacts.count == SampleContacts.all.count)
    }

    @Test("Two loads at once make one pass over the address book, not two")
    func concurrentLoadsJoinASingleFetch() async throws {
        let provider = RevocableContactsProvider()
        provider.delay = .milliseconds(50)
        let store = ContactsStore(provider: provider)

        let first = Task { try await store.load() }
        let second = Task { try await store.load() }
        try await first.value
        try await second.value

        #expect(provider.fetchCount == 1)
        #expect(store.contacts.count == SampleContacts.all.count)
    }
}

// MARK: - Doubles

private struct SomeOtherFailure: Error {}

/// Serves the sample address book until access is taken away mid-session, which
/// is what iOS lets a user do from Settings while the app is running.
private final class RevocableContactsProvider: ContactsProviding, @unchecked Sendable {
    var hasAccess = true
    var failure: (any Error)?
    var delay: Duration = .zero
    private(set) var fetchCount = 0

    func fetchContacts() async throws -> [Contact] {
        fetchCount += 1
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        if let failure { throw failure }
        guard hasAccess else { throw ContactsError.accessDenied }
        return SampleContacts.all
    }

    func loadFullImage(for contactID: String) async throws -> Data? { nil }
}
