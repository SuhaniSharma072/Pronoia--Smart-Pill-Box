//
//  SignInView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


//  SignInView.swift

//
import SwiftUI
import FirebaseAuth

struct SignInView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var email    = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMsg  = ""
    
    @State private var isLoading  = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    Text("Welcome Back")
                        .font(.appTitle(AppFont.displaySmall))
                        .foregroundColor(.darkText)
                        .padding(.top, 40)

                    VStack(spacing: 16) {
                        AppTextField(
                            label: "Email",
                            placeholder: "you@example.com",
                            icon: "envelope.fill",
                            text: $email,
                            keyboard: .emailAddress
                        )

                        AppTextField(
                            label: "Password",
                            placeholder: "Your password",
                            icon: "lock.fill",
                            text: $password
                        )
                    }

                    if showError {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(errorMsg)
                                .font(.appBody(AppFont.bodySmall))
                        }
                        .foregroundColor(.coralDark)
                        .padding(14)
                        .background(Color(hex: "#FFE8E4"))
                        .cornerRadius(12)
                    }

                    Button {
                        signIn()
                    } label: {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .font(.appButton(AppFont.bodyLarge))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.mintDark)
                        .cornerRadius(16)
                    }
                    .disabled(isLoading)

                }
                .padding(.horizontal, 28)
            }
        }
    }

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMsg  = "Please enter your email and password."
            showError = true
            return
        }
        isLoading = true
        // FIX: removed erroneous $ prefix on firebase
        firebase.signIn(email: email, password: password) { success, error in
            isLoading = false
            if !success {
                errorMsg  = error ?? "Sign in failed."
                showError = true
            }
        }
    }

    private func resetPassword() {
        // FIX: use firebase.auth, not FirebaseManager.shared.auth directly (same instance)
        firebase.auth.sendPasswordReset(withEmail: email) { _ in }
    }
}

#Preview {
    SignInView()
}
