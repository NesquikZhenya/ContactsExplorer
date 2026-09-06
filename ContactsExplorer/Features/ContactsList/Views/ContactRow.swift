//
//  ContactRow.swift
//  ContactsExplorer
//

import SwiftUI

struct ContactRow: View {
    let model: ContactRowModel
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: Metrics.spacing) {
            ContactAvatarView(
                imageData: model.thumbnailData,
                initials: model.initials,
                size: .thumbnail
            )
            VStack(alignment: .leading, spacing: Metrics.nameSpacing) {
                Text(model.displayName)
                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
                .buttonStyle(.borderless)
        }
    }
}

// MARK: - Constants

private extension ContactRow {
    enum Metrics {
        static let spacing: CGFloat = 12
        static let nameSpacing: CGFloat = 2
    }
}
