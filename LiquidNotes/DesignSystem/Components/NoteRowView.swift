import SwiftUI

struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: LNTheme.Spacing.xSmall) {
            HStack(spacing: LNTheme.Spacing.small) {
                Text(note.effectiveTitle)
                    .font(LNTypography.headline)
                    .lineLimit(1)
                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Favorite")
                }
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Pinned")
                }
                Spacer(minLength: 8)
                Text(note.updatedAt, style: .date)
                    .font(LNTypography.meta)
                    .foregroundStyle(.secondary)
            }

            Text(note.effectivePreview)
                .font(LNTypography.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if !note.tagNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LNTheme.Spacing.xSmall) {
                        ForEach(note.tagNames, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, LNTheme.Spacing.small)
                                .padding(.vertical, 4)
                                .background(.thinMaterial, in: Capsule(style: .continuous))
                        }
                    }
                }
                .accessibilityLabel("Tags")
            }
        }
        .padding(.vertical, LNTheme.Spacing.xSmall)
    }
}
