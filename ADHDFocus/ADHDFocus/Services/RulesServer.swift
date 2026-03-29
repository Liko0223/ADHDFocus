import Foundation
import Network

/// Lightweight local HTTP server that serves focus rules to the Chrome Extension
final class RulesServer {
    private var listener: NWListener?
    private let engine: FocusEngine
    private let port: UInt16 = 52836

    init(engine: FocusEngine) {
        self.engine = engine
    }

    func start() {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
        do {
            let params = NWParameters.tcp
            listener = try NWListener(using: params, on: nwPort)
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("RulesServer failed to start: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            guard let self, let data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }

            // Parse HTTP request path
            let firstLine = request.components(separatedBy: "\r\n").first ?? ""
            let parts = firstLine.components(separatedBy: " ")
            let path = parts.count > 1 ? parts[1] : "/"

            let responseBody: Data
            if path == "/rules" {
                responseBody = self.rulesJSON()
            } else {
                responseBody = Data("{}".utf8)
            }

            let headers = [
                "HTTP/1.1 200 OK",
                "Content-Type: application/json",
                "Access-Control-Allow-Origin: *",
                "Access-Control-Allow-Methods: GET",
                "Content-Length: \(responseBody.count)",
                "Connection: close",
                "", ""
            ].joined(separator: "\r\n")

            let response = Data(headers.utf8) + responseBody
            connection.send(content: response, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func rulesJSON() -> Data {
        var dict: [String: Any] = ["active": false]

        if let rules = engine.currentURLRules() {
            dict = rules
        }

        return (try? JSONSerialization.data(withJSONObject: dict)) ?? Data("{}".utf8)
    }
}
