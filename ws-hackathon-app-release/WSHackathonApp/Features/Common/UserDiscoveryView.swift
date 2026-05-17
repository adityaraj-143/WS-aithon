import SwiftUI

/**
 * Requirement 7: UI Requirements
 * Show active users list, guest names, send invite on tap, show popup on receive.
 */
struct UserDiscoveryView: View {
    @StateObject private var socketService = SocketService.shared
    @State private var showingInviteAlert = false
    @State private var inviteMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if !socketService.isConnected {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Connecting to server...")
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if socketService.activeUsers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No other users online")
                            .font(.headline)
                        Text("Share the app with friends to test the invite system!")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(socketService.activeUsers) { user in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.userId.prefix(8) + "...")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                socketService.sendInvite(to: user.userId)
                            }) {
                                Text("Invite")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.brandPrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Find Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading) {
                        Text(socketService.currentDisplayName)
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("Online")
                            .font(.system(size: 10))
                            .foregroundColor(.wsSuccess)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        socketService.fetchUsers()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            // Requirement 7: Show popup when invite received
            .alert(isPresented: $showingInviteAlert) {
                Alert(
                    title: Text("New Invite!"),
                    message: Text(inviteMessage),
                    primaryButton: .default(Text("Join Room"), action: {
                        if let invite = socketService.lastReceivedInvite {
                            print("Joining room: \(invite.inviteLink)")
                        }
                    }),
                    secondaryButton: .cancel()
                )
            }
            .onChange(of: socketService.lastReceivedInvite) { newInvite in
                if let invite = newInvite {
                    inviteMessage = "\(invite.fromDisplayName) invited you to join their room!"
                    showingInviteAlert = true
                }
            }
            .onAppear {
                socketService.connect()
            }
        }
    }
}

#Preview {
    UserDiscoveryView()
}
