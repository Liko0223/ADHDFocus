import Foundation

final class NativeMessagingHost {
    private let engine: FocusEngine
    private var inputPipe: FileHandle?
    private var outputPipe: FileHandle?
    private var isRunning = false

    init(engine: FocusEngine) {
        self.engine = engine
    }

    static func encodeMessage(_ message: [String: Any]) -> Data {
        let jsonData = try! JSONSerialization.data(withJSONObject: message)
        var length = UInt32(jsonData.count).littleEndian
        var result = Data(bytes: &length, count: 4)
        result.append(jsonData)
        return result
    }

    static func decodeMessage(from data: Data) -> [String: Any]? {
        guard data.count >= 4 else { return nil }
        let length = data.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
        guard data.count >= 4 + Int(length) else { return nil }
        let jsonData = data[4..<(4 + Int(length))]
        return try? JSONSerialization.jsonObject(with: Data(jsonData)) as? [String: Any]
    }

    func start() {
        isRunning = true
        inputPipe = FileHandle.standardInput
        outputPipe = FileHandle.standardOutput

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.readLoop()
        }
    }

    func stop() {
        isRunning = false
    }

    func sendRulesUpdate() {
        guard let rules = engine.currentURLRules() else {
            sendMessage(["type": "rules_update", "data": ["active": false]])
            return
        }
        sendMessage(["type": "rules_update", "data": rules])
    }

    private func readLoop() {
        while isRunning {
            guard let input = inputPipe else { break }

            let lengthData = input.readData(ofLength: 4)
            guard lengthData.count == 4 else { continue }

            let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
            guard length > 0, length < 1_000_000 else { continue }

            let messageData = input.readData(ofLength: Int(length))
            guard let message = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any] else { continue }

            handleMessage(message)
        }
    }

    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "get_rules":
            sendRulesUpdate()
        default:
            break
        }
    }

    private func sendMessage(_ message: [String: Any]) {
        let data = Self.encodeMessage(message)
        outputPipe?.write(data)
    }
}
