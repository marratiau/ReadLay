//
//  ReadLayApp.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI
// MARK: - Firebase Import (Uncomment when Firebase is added)
// import FirebaseCore

@main //entry point of the app
struct ReadLayApp: App {
    @StateObject private var authManager: AuthenticationManager
    let persistence = PersistenceController.shared

    init() {
        // MARK: - Initialize Firebase (Uncomment when Firebase is added)
        // FirebaseApp.configure()

        // Initialize AuthenticationManager
        let authManager = AuthenticationManager(persistenceController: PersistenceController.shared)
        _authManager = StateObject(wrappedValue: authManager)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    // Show loading screen while checking auth state
                    LoadingView()
                } else if authManager.currentUser != nil {
                    // User is authenticated or in guest mode
                    MainTabView()
                        .environmentObject(authManager)
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                } else {
                    // No user - show authentication
                    AuthenticationView()
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                authManager.checkAuthenticationState()
            }
        }
    }
}


#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager(persistenceController: PersistenceController.shared))
}
