//
//  SignUpView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


//  SignUpView.swift
import SwiftUI

struct SignUpView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name           = ""
    @State private var email          = ""
    @State private var password       = ""
    @State private var caretakerName  = ""
    @State private var caretakerEmail = ""
    @State private var caretakerPhone = ""
    @State private var selectedRole   = "older_adult"
    @State private var showError      = false
    @State private var errorMsg       = ""
    @State private var isLoading      = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    Text("Create Account")
                        .font(.appTitle(AppFont.displaySmall))
                        .foregroundColor(.darkText)
                        .padding(.top, 32)

                    // Role picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("I am a...")
                            .font(.appBodyBold(AppFont.bodySmall))
                            .foregroundColor(.darkText)

                        HStack(spacing: 12) {
                            RoleChip(label: "Older Adult", selected: selectedRole == "older_adult") {
                                selectedRole = "older_adult"
                            }
                            RoleChip(label: "Caretaker", selected: selectedRole == "caretaker") {
                                selectedRole = "caretaker"
                            }
                        }
                    }

                    AppTextField(label: "Full Name", placeholder: "Your name",        icon: "person.fill",   text: $name)
                    AppTextField(label: "Email",     placeholder: "you@example.com",  icon: "envelope.fill", text: $email,    keyboard: .emailAddress)
                    AppTextField(label: "Password",  placeholder: "Min 6 characters", icon: "lock.fill",     text: $password)

                    if selectedRole == "older_adult" {
                        VStack(alignment: .leading, spacing: 12) {

                            

                            AppTextField(
                                label: "Caretaker Name",
                                placeholder: "Caretaker's name",
                                icon: "person.2.fill",
                                text: $caretakerName
                            )
                            AppTextField(
                                label: "Caretaker Email",
                                placeholder: "Caretaker's email",
                                icon: "envelope.fill",
                                text: $caretakerEmail,
                                keyboard: .emailAddress
                            )
                            // ✅ Phone number — used to call the caretaker
                            AppTextField(
                                label: "Caretaker Phone",
                                placeholder: "e.g. 5551234567",
                                icon: "phone.fill",
                                text: $caretakerPhone,
                                keyboard: .phonePad
                            )
                        }
                        .padding(16)
                        .background(Color.mintLight.opacity(0.5))
                        .cornerRadius(14)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.mintDark)
                            Text("The older adult you care for must also enter your email so you'll be connected automatically.")
                                .font(.appCaption(AppFont.bodySmall))
                                .foregroundColor(.darkText)
                        }
                        .padding(14)
                        .background(Color.mintLight)
                        .cornerRadius(12)
                    }

                    if showError {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(errorMsg).font(.appBody(AppFont.bodySmall))
                        }
                        .foregroundColor(.coralDark)
                        .padding(14)
                        .background(Color(hex: "#FFE8E4"))
                        .cornerRadius(12)
                    }

                    Button { createAccount() } label: {
                        ZStack {
                            if isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
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

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
            }
        }
    }

    private func createAccount() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMsg = "Please fill in all required fields."; showError = true; return
        }
        guard password.count >= 6 else {
            errorMsg = "Password must be at least 6 characters."; showError = true; return
        }
        if selectedRole == "older_adult" && caretakerEmail.isEmpty {
            errorMsg = "Please enter your caretaker's email so they can be connected to you."
            showError = true; return
        }

        isLoading = true
        firebase.signUp(
            name:           name,
            email:          email,
            password:       password,
            phone:          "",
            role:           selectedRole,
            caretakerName:  caretakerName,
            caretakerEmail: caretakerEmail,
            caretakerPhone: caretakerPhone
        ) { success, error in
            isLoading = false
            if !success { errorMsg = error ?? "Sign up failed."; showError = true }
        }
    }
}

// MARK: - Role Chip

private struct RoleChip: View {
    let label:    String
    let selected: Bool
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.appBodyBold(AppFont.bodySmall))
                .foregroundColor(selected ? .white : .mintDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.mintDark : Color.mintLight)
                .cornerRadius(12)
        }
    }
}

#Preview {
    SignUpView()
}
