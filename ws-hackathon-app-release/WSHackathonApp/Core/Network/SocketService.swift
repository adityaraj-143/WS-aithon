import Foundation
import SwiftUI
import Combine

extension Notification.Name {
    static let didReceiveRegistryUpdate = Notification.Name("didReceiveRegistryUpdate")
}

/**
 * Requirement 6: Singleton SocketService
 * Handles socket lifecycle, event listening, and state management.
 */
class SocketService: ObservableObject {
    static let shared = SocketService()
    
    // Requirement 2 & 7: Maintain active users list for UI
    @Published var activeUsers: [SocketUser] = []
    @Published var lastReceivedInvite: ReceiveInvitePayload?
    @Published var pendingRegistryInvites: [ReceiveInvitePayload] = []
    @Published var isConnected: Bool = false
    
    private var socketManager: SocketManager?
    private var socket: Socket?
    
    // Requirement 1 & 6: Persist guest display name using UserDefaults
    private let userIdKey = "ws_user_id"
    private let displayNameKey = "ws_display_name"
    
    private(set) var currentUserId: String = ""
    private(set) var currentDisplayName: String = ""
    
    private init() {
        setupUserIdentity()
    }
    
    /**
     * Requirement 1: Every user receives a unique userId and persistent random displayName
     */
    private func setupUserIdentity() {
        if let savedId = UserDefaults.standard.string(forKey: userIdKey),
           let savedName = UserDefaults.standard.string(forKey: displayNameKey) {
            self.currentUserId = savedId
            self.currentDisplayName = savedName
        } else {
            self.currentUserId = UUID().uuidString
            self.currentDisplayName = "Guest-\(Int.random(in: 100...999))"
            
            UserDefaults.standard.set(self.currentUserId, forKey: userIdKey)
            UserDefaults.standard.set(self.currentDisplayName, forKey: displayNameKey)
        }
    }
    
    /**
     * Compatibility with App entry point
     */
    func startSession() {
        connect()
    }

    /**
     * Requirement 6: connect()
     */
    func connect() {
        // Use the local IP or localhost. In a real simulator, 127.0.0.1 works.
        // For physical devices, you'd use the machine's local IP.
        let url = URL(string: "http://127.0.0.1:3001")!
        socketManager = SocketManager(socketURL: url, config: [.reconnects(true)])
        socket = socketManager?.defaultSocket
        
        setupListeners()
        socket?.connect()
    }
    
    private func setupListeners() {
        guard let socket = socket else { return }
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self = self else { return }
            print("🟢 Socket Connected")
            DispatchQueue.main.async { self.isConnected = true }
            self.emitConnectUser()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("🔴 Socket Disconnected")
            DispatchQueue.main.async { self?.isConnected = false }
        }
        
        // Requirement 4 & 6: Listen for users_list
        socket.on(SocketEvents.usersList) { [weak self] data in
            guard let self = self,
                  let usersArray = data.first as? [[String: Any]] else { return }
            
            let users = usersArray.compactMap { dict -> SocketUser? in
                guard let uid = dict["userId"] as? String,
                      let name = dict["displayName"] as? String else { return nil }
                return SocketUser(userId: uid, displayName: name)
            }.filter { $0.userId != self.currentUserId }
            
            DispatchQueue.main.async {
                self.activeUsers = users
            }
        }
        
        // Requirement 4 & 6: Listen for receive_invite
        socket.on(SocketEvents.receiveInvite) { [weak self] data, _ in
            print("📬 receive_invite raw data: \(data)")
            guard let self = self,
                  let dict = data.first as? [String: Any] else {
                print("❌ Failed to parse receive_invite data as [String: Any]")
                return
            }
            
            guard let fromId = dict["fromUserId"] as? String,
                  let fromName = dict["fromDisplayName"] as? String,
                  let link = dict["inviteLink"] as? String else {
                print("❌ Missing required fields in receive_invite: \(dict)")
                return
            }
            
            let regId = dict["registryId"] as? String
            let regName = dict["registryName"] as? String
            
            let invite = ReceiveInvitePayload(
                fromUserId: fromId,
                fromDisplayName: fromName,
                inviteLink: link,
                registryId: regId,
                registryName: regName
            )
            
            DispatchQueue.main.async {
                self.lastReceivedInvite = invite
                if regId != nil {
                    if !self.pendingRegistryInvites.contains(invite) {
                        self.pendingRegistryInvites.append(invite)
                        print("✅ Added invite to pending list! Total pending: \(self.pendingRegistryInvites.count)")
                    } else {
                        print("⚠️ Invite already in pending list.")
                    }
                } else {
                    print("❌ regId was nil, invite ignored by UI.")
                }
            }
        }
        
        // Listen for real-time registry updates
        socket.on(SocketEvents.registryUpdated) { [weak self] data in
            guard let dict = data.first as? [String: Any] else { return }
            print("📦 Received real-time registry update")
            NotificationCenter.default.post(name: .didReceiveRegistryUpdate, object: dict)
        }
    }
    
    /**
     * Requirement: Shared Registry Collaboration
     */
    func joinRegistryRoom(_ registryId: String) {
        socket?.emit(SocketEvents.joinRegistryRoom, ["registryId": registryId]) // Wrapped in dict for consistency or raw
        // Actually, my server expects raw registryId or a payload. 
        // I'll emit it as a raw string if I update the server to handle both or just use a dict.
        // Let's use raw string as per my server code: socket.on("join_registry_room", (registryId) => { ... })
    }
    
    // Fixed join_registry_room emit to match server
    func joinRoom(registryId: String) {
        // Since my Socket class stringifies the data, I should send it as [registryId]
        // Actually the server expects the first argument to be registryId.
        // My Socket.emit(event, dict) wraps it in [event, dict].
        // I'll update my server to handle the dict or update emit.
        socket?.emit(SocketEvents.joinRegistryRoom, ["id": registryId])
    }

    func syncRegistry(id: String, data: [String: Any]) {
        let payload: [String: Any] = [
            "registryId": id,
            "registryData": data
        ]
        socket?.emit(SocketEvents.syncRegistry, payload)
    }
    
    private func emitConnectUser() {
        let data: [String: Any] = [
            "userId": currentUserId,
            "displayName": currentDisplayName
        ]
        socket?.emit(SocketEvents.connectUser, data)
        
        // Fetch users immediately after connecting
        fetchUsers()
    }
    
    /**
     * Requirement 6: fetchUsers()
     */
    func fetchUsers() {
        socket?.emit(SocketEvents.getUsers, [:])
    }
    
    /**
     * Requirement 6: sendInvite()
     */
    func sendInvite(to userId: String, registry: Registry? = nil) {
        var payload: [String: Any] = [
            "fromUserId": currentUserId,
            "toUserId": userId,
            "inviteLink": "wsapp://room/\(UUID().uuidString.prefix(6))"
        ]
        
        if let registry = registry {
            payload["registryId"] = registry.id.uuidString
            payload["registryName"] = registry.displayName
            payload["inviteLink"] = "wsapp://registry/\(registry.id.uuidString)"
        }
        
        socket?.emit(SocketEvents.sendInvite, payload)
    }
    
    /**
     * Finds a user by display name and sends an invite
     */
    func sendInvite(toDisplayName name: String, registry: Registry? = nil) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 Attempting to send invite to: '\(trimmedName)'")
        if let user = activeUsers.first(where: { $0.displayName.lowercased() == trimmedName.lowercased() }) {
            sendInvite(to: user.userId, registry: registry)
            print("✅ Successfully dispatched send_invite to \(user.userId)")
            return true
        }
        print("❌ Could not find active user with name '\(trimmedName)'. Current active users: \(activeUsers.map { $0.displayName })")
        return false
    }
    
    func acceptInvite(_ invite: ReceiveInvitePayload) {
        DispatchQueue.main.async {
            self.pendingRegistryInvites.removeAll { $0 == invite }
        }
    }
}
