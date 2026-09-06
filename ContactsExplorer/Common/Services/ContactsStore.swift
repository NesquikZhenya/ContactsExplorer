//
//  ContactsStore.swift
//  ContactsExplorer
//
//  Created by Shai Balassiano on 17/08/2026.
//

import Foundation
import Observation

protocol ContactsStoring: AnyObject {
    var contacts: [Contact] { get }

    func load() async throws
    func loadFullImage(for contactID: String) async throws -> Data?
}

@Observable
final class ContactsStore: ContactsStoring {
    private(set) var contacts: [Contact] = []

    private let provider: any ContactsProviding
    private var loadTask: Task<[Contact], Error>?

    init(provider: any ContactsProviding) {
        self.provider = provider
    }

    func load() async throws {
        do {
            contacts = try await fetchOrJoin()
        } catch ContactsError.accessDenied {
            contacts.removeAll()
            throw ContactsError.accessDenied
        }
    }

    func loadFullImage(for contactID: String) async throws -> Data? {
        try await provider.loadFullImage(for: contactID)
    }
}

// MARK: - Fetching

private extension ContactsStore {
    func fetchOrJoin() async throws -> [Contact] {
        if let loadTask {
            return try await loadTask.value
        }

        let task = Task { [provider] in
            try await provider.fetchContacts()
        }
        loadTask = task
        defer { loadTask = nil }

        return try await task.value
    }
}
