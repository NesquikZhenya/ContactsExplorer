//
//  FavoriteButton.swift
//  ContactsExplorer
//

import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? Icons.favorite : Icons.notFavorite)
                .foregroundStyle(isFavorite ? .yellow : .secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(isFavorite ? Strings.remove : Strings.add)
    }
}

// MARK: - Constants

private extension FavoriteButton {
    enum Icons {
        static let favorite = "star.fill"
        static let notFavorite = "star"
    }

    enum Strings {
        static let add: LocalizedStringKey = "Add to Favorites"
        static let remove: LocalizedStringKey = "Remove from Favorites"
    }
}
