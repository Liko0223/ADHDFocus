import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var modeID: UUID
    var modeName: String
    var statsTag: String
    var startedAt: Date
    var endedAt: Date?
    var completedPomodoros: Int
    var totalWorkSeconds: Int

    init(modeID: UUID, modeName: String, statsTag: String) {
        self.id = UUID()
        self.modeID = modeID
        self.modeName = modeName
        self.statsTag = statsTag
        self.startedAt = Date()
        self.endedAt = nil
        self.completedPomodoros = 0
        self.totalWorkSeconds = 0
    }
}
