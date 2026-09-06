//
//  ContactRowModel.swift
//  ContactsExplorer
//

import Foundation

struct ContactRowModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    let subtitle: String?
    let initials: String
    let thumbnailData: Data?

    let foldedName: String
    let phoneDigits: [String]
}
