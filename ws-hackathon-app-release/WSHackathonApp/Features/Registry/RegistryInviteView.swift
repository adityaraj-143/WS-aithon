import SwiftUI

struct RegistryInviteView: View {
    let registry: Registry?
    @StateObject private var socketService = SocketService.shared
    @Environment(\.dismiss) var dismiss
    
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
                        Text("Ask your friends to open the app!")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
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
                                Text("Online")
                                    .font(.caption)
                                    .foregroundColor(.wsSuccess)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                socketService.sendInvite(to: user.userId, registry: registry)
                                // Show a small feedback or just dismiss
                                dismiss()
                            }) {
                                Text("Send Invite")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.brandPrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Invite to Registry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
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
            .onAppear {
                socketService.connect()
            }
        }
    }
}
