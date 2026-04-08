import Foundation
import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Note.self,
            Tag.self,
            ChecklistItem.self
        ])

        let configuration = ModelConfiguration(
            "LiquidNotes",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }()
}
