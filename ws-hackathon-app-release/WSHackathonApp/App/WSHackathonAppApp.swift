import SwiftUI

@main
struct WSHackathonAppApp: App {

    @StateObject private var registryRepo = RegistryRepository()
    @StateObject private var cartRepo = CartRepository()
    @StateObject private var tabBarVM = WSTabBarViewModel()
    @StateObject private var homeVM = HomeViewModel()

    var body: some Scene {
        WindowGroup {
            WSTabView()
                .environmentObject(registryRepo)
                .environmentObject(cartRepo)
                .environmentObject(tabBarVM)
                .environmentObject(homeVM)

                // ✅ Start socket ONLY when UI is ready
                .onAppear {
                    SocketService.shared.startSession()
                    
                    // Bind cooperative shared registry cart sync coordinator globally at startup
                    RegistryCartSyncManager.shared.bind(
                        cartRepository: cartRepo,
                        registryRepository: registryRepo
                    )
                }
        }
    }
}