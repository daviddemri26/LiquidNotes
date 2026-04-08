import Foundation

enum NoteSortOrder: String, CaseIterable, Identifiable, Codable {
    case updatedDescending
    case createdDescending
    case alphabetical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .updatedDescending:
            return "Recently Edited"
        case .createdDescending:
            return "Recently Created"
        case .alphabetical:
            return "Alphabetical"
        }
    }
}
