//
//  SignUpFormView.swift
//  ReadLay
//
//  Sign up form with display name, email, and password
//

import SwiftUI

struct SignUpFormView: View {
    @ObservedObject var authManager: AuthenticationManager

    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @FocusState private var focusedField: Field?

    enum Field {
        case displayName, email, password, confirmPassword
    }

    var body: some View {
        VStack(spacing: 20) {
            // Display Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)

                TextField("Your name", text: $displayName)
                    .font(.system(size: 16))
                    .autocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        focusedField == .displayName ?
                                            Color.goodreadsBrown.opacity(0.5) :
                                            Color.goodreadsAccent.opacity(0.3),
                                        lineWidth: focusedField == .displayName ? 2 : 1
                                    )
                            )
                    )
                    .focused($focusedField, equals: .displayName)
            }

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
                        TextField("At least 8 characters", text: $password)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("At least 8 characters", text: $password)
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

                // Password requirements
                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(password.count >= 8 ? .green : .goodreadsAccent.opacity(0.5))
                            Text("At least 8 characters")
                                .font(.system(size: 12))
                                .foregroundColor(.goodreadsAccent.opacity(0.7))
                        }

                        HStack(spacing: 6) {
                            Image(systemName: hasUppercase ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(hasUppercase ? .green : .goodreadsAccent.opacity(0.5))
                            Text("At least 1 uppercase letter")
                                .font(.system(size: 12))
                                .foregroundColor(.goodreadsAccent.opacity(0.7))
                        }

                        HStack(spacing: 6) {
                            Image(systemName: hasNumber ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(hasNumber ? .green : .goodreadsAccent.opacity(0.5))
                            Text("At least 1 number")
                                .font(.system(size: 12))
                                .foregroundColor(.goodreadsAccent.opacity(0.7))
                        }
                    }
                    .padding(.top, 4)
                }
            }

            // Confirm Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)

                HStack {
                    if isConfirmPasswordVisible {
                        TextField("Re-enter password", text: $confirmPassword)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Re-enter password", text: $confirmPassword)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }

                    Button(action: { isConfirmPasswordVisible.toggle() }) {
                        Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
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
                                    focusedField == .confirmPassword ?
                                        Color.goodreadsBrown.opacity(0.5) :
                                        Color.goodreadsAccent.opacity(0.3),
                                    lineWidth: focusedField == .confirmPassword ? 2 : 1
                                )
                        )
                )
                .focused($focusedField, equals: .confirmPassword)

                // Password match indicator
                if !confirmPassword.isEmpty && confirmPassword != password {
                    Text("Passwords do not match")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }

            // Error message
            if let error = authManager.authError {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            // Sign up button
            Button(action: signUp) {
                if authManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign Up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSignUp ? Color.goodreadsBrown : Color.goodreadsAccent.opacity(0.5))
            )
            .disabled(!canSignUp || authManager.isLoading)
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

    private var hasUppercase: Bool {
        password.rangeOfCharacter(from: .uppercaseLetters) != nil
    }

    private var hasNumber: Bool {
        password.rangeOfCharacter(from: .decimalDigits) != nil
    }

    private var isPasswordStrong: Bool {
        password.count >= 8 && hasUppercase && hasNumber
    }

    private var canSignUp: Bool {
        !displayName.isEmpty &&
        displayName.count >= 2 &&
        !email.isEmpty &&
        isPasswordStrong &&
        password == confirmPassword
    }

    // MARK: - Actions

    private func signUp() {
        focusedField = nil

        Task {
            do {
                try await authManager.signUpWithEmail(email, password: password, displayName: displayName)
            } catch {
                // Error is handled by authManager.authError
            }
        }
    }
}

#Preview {
    SignUpFormView(authManager: AuthenticationManager(persistenceController: PersistenceController.shared))
}
