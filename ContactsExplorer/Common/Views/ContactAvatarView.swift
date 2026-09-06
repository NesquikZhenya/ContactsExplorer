//
//  ContactAvatarView.swift
//  ContactsExplorer
//

import SwiftUI

struct ContactAvatarView: View {
    enum Size {
        case thumbnail
        case full

        fileprivate var points: CGFloat {
            switch self {
            case .thumbnail: Metrics.thumbnailSize
            case .full: Metrics.fullSize
            }
        }
    }

    let imageData: Data?
    let initials: String
    let size: Size

    var body: some View {
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                initialsAvatar
            }
        }
        .frame(width: size.points, height: size.points)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}

// MARK: - Subviews

private extension ContactAvatarView {
    var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.gray.gradient)
            Text(initials)
                .font(.system(size: size.points * Metrics.initialsFontRatio, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Constants

private extension ContactAvatarView {
    enum Metrics {
        static let initialsFontRatio: CGFloat = 0.4
        static let thumbnailSize: CGFloat = 44
        static let fullSize: CGFloat = 120
    }
}
