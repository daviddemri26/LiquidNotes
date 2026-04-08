import Foundation
import os

enum LoggerService {
    static let app = Logger(subsystem: "LiquidNotes", category: "App")
    static let data = Logger(subsystem: "LiquidNotes", category: "Data")
    static let intents = Logger(subsystem: "LiquidNotes", category: "Intents")
}
