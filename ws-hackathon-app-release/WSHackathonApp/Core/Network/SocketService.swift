import Foundation
import SocketIO

final class SocketService {

    static let shared = SocketService()

    private let manager: SocketManager
    let socket: Socket
    private var sessionStarted = false

    private var userId: String = ""
    private var displayName: String = ""

    static var temporaryUserId: String {
        UUID().uuidString
    }

    private init() {

        manager = SocketManager(
            socketURL: URL(string: "http://127.0.0.1:3001")!,
            config: [
                .log(true),
                .compress,
                .reconnects(true),
                .reconnectAttempts(-1),
                .forceWebsockets(true)
            ]
        )

        socket = manager.defaultSocket
    }

    func startSession(
        userId: String = SocketService.temporaryUserId,
        displayName: String = "Guest123"
    ) {

        guard !sessionStarted else {
            print("⚠️ Session already started")
            return
        }

        sessionStarted = true

        self.userId = userId
        self.displayName = displayName

        print("🟢 Starting session")
        print("👤 USER ID:", userId)

        socket.on(clientEvent: .connect) { [weak self] _, _ in

            guard let self = self else { return }

            print("✅ Socket connected")

            self.socket.emit("connect_user", [
                "userId": self.userId,
                "displayName": self.displayName
            ])
        }

        socket.on(clientEvent: .disconnect) { _, _ in
            print("❌ Socket disconnected")
        }

        socket.connect()
    }

    func disconnect() {
        sessionStarted = false
        socket.disconnect()
    }
}
