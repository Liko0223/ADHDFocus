import Foundation
import SwiftData

enum BlockEventType: String, Codable {
    case app
    case url
}

@Model
final class BlockEvent {
    var id: UUID
    var type: BlockEventType
    var target: String  // Bundle ID or URL domain
    var modeName: String
    var timestamp: Date

    init(type: BlockEventType, target: String, modeName: String) {
        self.id = UUID()
        self.type = type
        self.target = target
        self.modeName = modeName
        self.timestamp = Date()
    }
}
