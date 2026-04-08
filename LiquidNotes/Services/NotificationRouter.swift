import Foundation
import Observation

@Observable
@MainActor
final class NotificationRouter {
    static let shared = NotificationRouter()

    var pendingOpenNoteID: UUID?

    func routeToNote(with id: UUID) {
        pendingOpenNoteID = id
    }

    func consumePendingNoteID() -> UUID? {
        defer { pendingOpenNoteID = nil }
        return pendingOpenNoteID
    }
}
