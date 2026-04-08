import Foundation

enum NoteListScope: String, CaseIterable, Identifiable {
    case notes
    case favorites
    case archived
    case trash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notes: return "Notes"
        case .favorites: return "Favorites"
        case .archived: return "Archive"
        case .trash: return "Trash"
        }
    }
}
