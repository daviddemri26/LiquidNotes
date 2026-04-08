import SwiftUI

struct NoteRowView: View {
    let note: Note
    private let maxInlineTags = 3

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

            let tags = note.tagNames
            if !tags.isEmpty {
                HStack(spacing: LNTheme.Spacing.xSmall) {
                    ForEach(Array(tags.prefix(maxInlineTags)), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, LNTheme.Spacing.small)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.14), in: Capsule(style: .continuous))
                    }
                    if tags.count > maxInlineTags {
                        Text("+\(tags.count - maxInlineTags)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Tags")
            }
        }
        .padding(.vertical, LNTheme.Spacing.xSmall)
    }
}
