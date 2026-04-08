import Foundation

enum NoteListScope: String, CaseIterable, Identifiable {
    case notes
    case favorites
    case trash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notes: return "Notes"
        case .favorites: return "Favorites"
        case .trash: return "Trash"
        }
    }
}
