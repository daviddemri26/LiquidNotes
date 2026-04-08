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
            // Recovery path for incompatible local stores after schema changes.
            if shouldResetStore(for: error) {
                resetStoreFiles(named: "LiquidNotes")
                do {
                    return try ModelContainer(for: schema, configurations: [configuration])
                } catch {
                    fatalError("Failed to recreate model container after reset: \(error.localizedDescription)")
                }
            }
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }()

    private static func shouldResetStore(for error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == 134110 {
            return true
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == NSCocoaErrorDomain, underlying.code == 134110 {
            return true
        }

        return false
    }

    private static func resetStoreFiles(named storeName: String) {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        let baseURL = appSupport.appendingPathComponent("\(storeName).store")
        let relatedPaths = [
            baseURL.path,
            baseURL.appendingPathExtension("shm").path,
            baseURL.appendingPathExtension("wal").path
        ]

        for path in relatedPaths where FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}
