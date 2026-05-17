import Foundation

// Requirement 1 & 4
struct SocketUser: Codable, Identifiable, Equatable {
    var id: String { userId }
    let userId: String
    let displayName: String
}

// Requirement 4: send_invite Payload
struct InvitePayload: Codable {
    let fromUserId: String
    let toUserId: String
    let inviteLink: String
    let registryId: String?
    let registryName: String?
}

// Requirement 4: receive_invite Payload
struct ReceiveInvitePayload: Codable, Equatable {
    let fromUserId: String
    let fromDisplayName: String
    let inviteLink: String
    let registryId: String?
    let registryName: String?
}

extension Notification.Name {
    static let didReceiveRegistryCartSync = Notification.Name("didReceiveRegistryCartSync")
    static let didConnectSocket = Notification.Name("didConnectSocket")
}

// Requirement 8: Scalable Architecture - Socket Event Constants
enum SocketEvents {
    static let connectUser = "connect_user"
    static let getUsers = "get_users"
    static let sendInvite = "send_invite"
    
    static let usersList = "users_list"
    static let receiveInvite = "receive_invite"
    
    static let syncRegistry = "sync_registry"
    static let joinRegistryRoom = "join_registry_room"
    static let registryUpdated = "registry_updated"
    static let userRegistries = "user_registries"
    static let acceptInvite = "accept_invite"
    static let deleteRegistry = "delete_registry"
    
    // Collaborative shared cart sync events
    static let registryCartStateSynced = "registry_cart_state_synced"
}
