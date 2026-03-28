import Testing
import Foundation
@testable import ADHDFocus

@Test func nativeMessageEncoding() {
    let message: [String: Any] = [
        "type": "rules_update",
        "data": ["active": true, "modeName": "Test"]
    ]
    let encoded = NativeMessagingHost.encodeMessage(message)
    let length = encoded.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self) }
    let jsonData = encoded.dropFirst(4)
    #expect(Int(length) == jsonData.count)

    let decoded = try! JSONSerialization.jsonObject(with: Data(jsonData)) as! [String: Any]
    #expect(decoded["type"] as? String == "rules_update")
}

@Test func nativeMessageDecoding() {
    let json = "{\"type\":\"get_rules\"}"
    let jsonData = json.data(using: .utf8)!
    var lengthBytes = UInt32(jsonData.count).littleEndian
    let lengthData = Data(bytes: &lengthBytes, count: 4)
    let fullMessage = lengthData + jsonData

    let decoded = NativeMessagingHost.decodeMessage(from: fullMessage)
    #expect(decoded?["type"] as? String == "get_rules")
}
