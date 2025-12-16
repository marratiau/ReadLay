//
//  AuthenticationView.swift
//  ReadLay
//
//  Main authentication screen with sign in, sign up, and guest mode
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab: AuthTab = .signIn

    enum AuthTab {
        case signIn, signUp
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo section
                    logoSection
                        .padding(.top, 40)

                    // Tab selector
                    tabSelector

                    // Form content
                    if selectedTab == .signIn {
                        SignInFormView(authManager: authManager)
                            .transition(.opacity)
                    } else {
                        SignUpFormView(authManager: authManager)
                            .transition(.opacity)
                    }

                    // OR divider
                    orDivider
                        .padding(.top, 8)

                    // Google Sign-In button (commented out until Firebase is added)
                    // googleSignInButton

                    // Continue as Guest button
                    guestModeButton
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
            .background(backgroundGradient)
            .navigationBarHidden(true)
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.pages")
                .font(.system(size: 56))
                .foregroundColor(.goodreadsBrown)

            Text("ReadLay")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundColor(.goodreadsBrown)

            Text("Track your reading goals")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.goodreadsAccent)
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            // Sign In tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .signIn
                }
            }) {
                Text("Sign In")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTab == .signIn ? .goodreadsBrown : .goodreadsAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == .signIn ? Color.goodreadsWarm : Color.clear)
                    )
            }

            // Sign Up tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .signUp
                }
            }) {
                Text("Sign Up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTab == .signUp ? .goodreadsBrown : .goodreadsAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == .signUp ? Color.goodreadsWarm : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsBeige)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - OR Divider

    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.goodreadsAccent.opacity(0.3))
                .frame(height: 1)

            Text("OR")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.goodreadsAccent)

            Rectangle()
                .fill(Color.goodreadsAccent.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: - Google Sign-In Button (Commented out until Firebase is added)

    // Uncomment this when Firebase is integrated
    /*
    private var googleSignInButton: some View {
        Button(action: {
            Task {
                try? await authManager.signInWithGoogle()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)

                Text("Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.goodreadsBrown)
            )
        }
        .disabled(authManager.isLoading)
    }
    */

    // MARK: - Guest Mode Button

    private var guestModeButton: some View {
        Button(action: {
            authManager.continueAsGuest()
        }) {
            Text("Continue as Guest")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.goodreadsAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.goodreadsBeige)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .disabled(authManager.isLoading)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.goodreadsBeige,
                Color.goodreadsWarm.opacity(0.5)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager(persistenceController: PersistenceController.shared))
}
