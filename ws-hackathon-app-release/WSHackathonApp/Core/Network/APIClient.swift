//
//  APIClient.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
import UIKit

final class APIClient {
    static let shared = APIClient()
    private init() {}
    
    // MARK: - GET Request
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, _) = try await requestData(endpoint)
        return try decode(data: data)
    }
    
    // MARK: - POST / PUT / PATCH Request (With Body)
    func request<T: Decodable, Body: Encodable>(
        _ endpoint: Endpoint,
        body: Body
    ) async throws -> T {
        let (data, _) = try await requestData(endpoint, body: body)
        return try decode(data: data)
    }
    
    // MARK: - Core Request
    private func requestData(
        _ endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws -> (Data, URLResponse) {
        
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = AppConstants.API.timeout
        
        // Headers
        endpoint.headers?.forEach {
            request.addValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        // Body (only if present)
        if let body = body {
            if endpoint.method == .get {
                assertionFailure("GET request should not have body")
            }
            
            request.httpBody = try encode(body)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        return (data, response)
    }
    
    // MARK: - Encode Helper (Fix for `any Encodable`)
    private func encode(_ value: any Encodable) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(AnyEncodable(value))
    }
    
    // MARK: - Decode Helper
    private func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    // MARK: - Image Download
    func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw NetworkError.decodingError
        }
        
        return image
    }
}

// MARK: - Type Erasure for Encodable
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    
    init<T: Encodable>(_ value: T) {
        encodeFunc = value.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

// MARK: - Socket.IO Native Wrapper
enum SocketClientEvent {
    case connect
    case disconnect
    case reconnect
}

enum SocketConfig {
    case log(Bool)
    case compress
    case reconnects(Bool)
    case reconnectAttempts(Int)
}

enum SocketStatus {
    case notConnected
    case connecting
    case connected
    case disconnected
}

class SocketManager {
    let socketURL: URL
    let config: [SocketConfig]
    var defaultSocket: Socket { return self.socket }
    private let socket: Socket

    init(socketURL: URL, config: [SocketConfig]) {
        self.socketURL = socketURL
        self.config = config
        self.socket = Socket(baseURL: socketURL, config: config)
    }
}

class Socket {
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    private let session = URLSession(configuration: .default)

    // Callback arrays — multiple listeners accumulate, none overwrite
    private var connectCallbacks:    [() -> Void] = []
    private var disconnectCallbacks: [() -> Void] = []
    private var reconnectCallbacks:  [() -> Void] = []
    private var eventCallbacks:      [String: [([Any]) -> Void]] = [:]

    private(set) var status: SocketStatus = .notConnected
    private var shouldReconnect: Bool = true
    private var maxReconnectAttempts: Int = -1
    private var reconnectAttempt: Int = 0
    private var pingTimer: Timer?

    init(baseURL: URL, config: [SocketConfig] = []) {
        var string = baseURL.absoluteString
        if string.hasPrefix("http") {
            string = string.replacingOccurrences(of: "http", with: "ws")
        }
        string += "/socket.io/?EIO=4&transport=websocket"
        self.url = URL(string: string)!
        for c in config {
            switch c {
            case .reconnects(let val): self.shouldReconnect = val
            case .reconnectAttempts(let val): self.maxReconnectAttempts = val
            default: break
            }
        }
    }

    // MARK: - Event Registration

    /// Registers an additional listener for a client event.
    /// Calling this multiple times appends — it does NOT overwrite previous listeners.
    func on(clientEvent: SocketClientEvent, callback: @escaping ([Any], Any) -> Void) {
        let cb = { callback([], "") }
        switch clientEvent {
        case .connect:    connectCallbacks.append(cb)
        case .disconnect: disconnectCallbacks.append(cb)
        case .reconnect:  reconnectCallbacks.append(cb)
        }
    }

    /// Registers a listener for a custom Socket.IO event
    func on(_ event: String, callback: @escaping ([Any]) -> Void) {
        if eventCallbacks[event] == nil {
            eventCallbacks[event] = []
        }
        eventCallbacks[event]?.append(callback)
    }

    /// Remove all listeners for a given event (use before re-registering session handlers).
    func off(clientEvent: SocketClientEvent) {
        switch clientEvent {
        case .connect:    connectCallbacks.removeAll()
        case .disconnect: disconnectCallbacks.removeAll()
        case .reconnect:  reconnectCallbacks.removeAll()
        }
    }

    // MARK: - Connect / Disconnect

    func connect() {
        guard status == .notConnected || status == .disconnected else {
            print("⚠️ Socket: already \(status) — skipping duplicate connect()")
            return
        }
        status = .connecting
        openConnection()
    }

    private func openConnection() {
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }

    func disconnect() {
        shouldReconnect = false
        tearDown(fireCb: true)
    }

    private func tearDown(fireCb: Bool) {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        status = .disconnected
        if fireCb {
            DispatchQueue.main.async {
                self.disconnectCallbacks.forEach { $0() }
            }
        }
    }

    // MARK: - Receive Loop

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("🔴 Socket error: \(error.localizedDescription)")
                self.handleUnexpectedDisconnect()
            case .success(let message):
                if case .string(let text) = message {
                    self.handleEngineIOMessage(text)
                }
                // Keep reading only when alive
                if self.status == .connecting || self.status == .connected {
                    self.receiveMessage()
                }
            }
        }
    }

    // MARK: - Engine.IO Protocol

    private func handleEngineIOMessage(_ text: String) {
        if text.hasPrefix("0") {
            // OPEN — upgrade to Socket.IO namespace
            sendRaw("40")
        } else if text.hasPrefix("40") {
            // Socket.IO namespace connected
            status = .connected
            reconnectAttempt = 0
            startPingTimer()
            DispatchQueue.main.async {
                self.connectCallbacks.forEach { $0() }
            }
        } else if text.hasPrefix("42") {
            // Socket.IO Event: 42["event", data]
            let jsonPart = String(text.dropFirst(2))
            if let data = jsonPart.data(using: .utf8),
               let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
               array.count >= 1,
               let eventName = array[0] as? String {
                
                let eventData = Array(array.dropFirst())
                DispatchQueue.main.async {
                    self.eventCallbacks[eventName]?.forEach { $0(eventData) }
                    
                    // Also notify the Service if needed (using a bridge or another pattern)
                    // For simplicity, we'll just use the eventCallbacks.
                }
            }
        } else if text == "2" {
            // Server PING — reply with PONG
            sendRaw("3")
        } else if text.hasPrefix("41") || text == "1" {
            // Explicit server disconnect
            handleUnexpectedDisconnect()
        }
    }

    // MARK: - Ping Keepalive (prevents idle 25s server timeout)

    private func startPingTimer() {
        pingTimer?.invalidate()
        DispatchQueue.main.async {
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
                self?.sendRaw("2")
            }
        }
    }

    // MARK: - Auto-reconnect

    private func handleUnexpectedDisconnect() {
        guard status != .disconnected else { return }
        tearDown(fireCb: true)
        guard shouldReconnect,
              maxReconnectAttempts == -1 || reconnectAttempt < maxReconnectAttempts else { return }
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(reconnectAttempt - 1)), 30.0)
        print("🔄 Socket reconnecting in \(Int(delay))s (attempt \(reconnectAttempt))…")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.status == .disconnected else { return }
            self.status = .connecting
            self.openConnection()
            self.reconnectCallbacks.forEach { $0() }
        }
    }

    // MARK: - Emit

    func emit(_ event: String, _ data: Any) {
        guard status == .connected else {
            print("⚠️ emit('\(event)') skipped — socket not connected (status: \(status))")
            return
        }
        let array: [Any] = [event, data]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: array, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        sendRaw("42" + jsonString)
    }

    // MARK: - Raw Send

    private func sendRaw(_ string: String) {
        let msg = URLSessionWebSocketTask.Message.string(string)
        webSocketTask?.send(msg) { error in
            if let error = error {
                print("WebSocket send error: \(error.localizedDescription)")
            }
        }
    }
}

