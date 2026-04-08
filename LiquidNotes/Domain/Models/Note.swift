import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var bodyText: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isFavorite: Bool
    var isArchived: Bool
    var isDeleted: Bool
    var colorMarkerHex: String?
    var reminderDate: Date?
    var metadataJSON: Data?

    var tags: [Tag]?
    var checklistItems: [ChecklistItem]?

    init(
        id: UUID = UUID(),
        title: String = "",
        bodyText: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false,
        isFavorite: Bool = false,
        isArchived: Bool = false,
        isDeleted: Bool = false,
        colorMarkerHex: String? = nil,
        reminderDate: Date? = nil,
        metadataJSON: Data? = nil,
        tags: [Tag]? = nil,
        checklistItems: [ChecklistItem]? = nil
    ) {
        self.id = id
        self.title = title
        self.bodyText = bodyText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.isDeleted = isDeleted
        self.colorMarkerHex = colorMarkerHex
        self.reminderDate = reminderDate
        self.metadataJSON = metadataJSON
        self.tags = tags
        self.checklistItems = checklistItems
    }
}

extension Note {
    var effectiveTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }

        let firstBodyLine = bodyText
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return firstBodyLine.isEmpty ? "Untitled" : firstBodyLine
    }

    var effectivePreview: String {
        let preview = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        return preview.isEmpty ? "No additional text" : preview
    }

    var isReminderActive: Bool {
        guard let reminderDate else { return false }
        return reminderDate > .now
    }

    var tagNames: [String] {
        (tags ?? []).map(\.name).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var asProjection: NoteProjection {
        NoteProjection(
            id: id,
            title: effectiveTitle,
            body: effectivePreview,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isPinned: isPinned,
            isFavorite: isFavorite,
            isArchived: isArchived,
            isDeleted: isDeleted,
            reminderDate: reminderDate,
            tags: tagNames
        )
    }
}
