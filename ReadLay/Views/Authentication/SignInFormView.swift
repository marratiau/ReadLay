//
//  SignInFormView.swift
//  ReadLay
//
//  Sign in form with email and password
//

import SwiftUI

struct SignInFormView: View {
    @ObservedObject var authManager: AuthenticationManager

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        VStack(spacing: 20) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)

                TextField("your@email.com", text: $email)
                    .font(.system(size: 16))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        focusedField == .email ?
                                            Color.goodreadsBrown.opacity(0.5) :
                                            Color.goodreadsAccent.opacity(0.3),
                                        lineWidth: focusedField == .email ? 2 : 1
                                    )
                            )
                    )
                    .focused($focusedField, equals: .email)
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)

                HStack {
                    if isPasswordVisible {
                        TextField("Enter your password", text: $password)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Enter your password", text: $password)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }

                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.goodreadsAccent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.goodreadsBeige)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    focusedField == .password ?
                                        Color.goodreadsBrown.opacity(0.5) :
                                        Color.goodreadsAccent.opacity(0.3),
                                    lineWidth: focusedField == .password ? 2 : 1
                                )
                        )
                )
                .focused($focusedField, equals: .password)
            }

            // Error message
            if let error = authManager.authError {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            // Sign in button
            Button(action: signIn) {
                if authManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSignIn ? Color.goodreadsBrown : Color.goodreadsAccent.opacity(0.5))
            )
            .disabled(!canSignIn || authManager.isLoading)
            .padding(.top, 8)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.goodreadsBrown)
            }
        }
    }

    // MARK: - Validation

    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }

    // MARK: - Actions

    private func signIn() {
        focusedField = nil

        Task {
            do {
                try await authManager.signInWithEmail(email, password: password)
            } catch {
                // Error is handled by authManager.authError
            }
        }
    }
}

#Preview {
    SignInFormView(authManager: AuthenticationManager(persistenceController: PersistenceController.shared))
}
