//
//  HealthProfileView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


// HealthProfileView.swift
import SwiftUI
import FirebaseFirestore

struct HealthProfileView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @State private var isEditing        = false
    @State private var name             = ""
    @State private var caretakerPhone   = ""
    @State private var isSaving         = false

    var initials: String {
        let parts = (firebase.currentUser?.name ?? "U").components(separatedBy: " ")
        return parts.compactMap { $0.first }.prefix(2).map { String($0) }.joined().uppercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        ZStack {
                            LinearGradient.mintHeader
                                .frame(height: 200)
                                .ignoresSafeArea()

                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 90, height: 90)
                                    Text(initials)
                                        .font(.appBodyBold(AppFont.displayMedium))
                                        .foregroundColor(.white)
                                }
                                Text(firebase.currentUser?.name ?? "")
                                    .font(.appTitle(AppFont.titleLarge))
                                    .foregroundColor(.white)
                                Text(firebase.currentUser?.email ?? "")
                                    .font(.appCaption())
                                    .foregroundColor(.mintLight)
                            }
                        }

                        VStack(spacing: 16) {

                            // ── Personal Info ────────────────────────────
                            ProfileSection(title: "Personal Information") {
                                if isEditing {
                                    AppTextField(
                                        label: "Full Name",
                                        placeholder: "Your name",
                                        icon: "person.fill",
                                        text: $name
                                    )
                                } else {
                                    ProfileRow(
                                        label: "Full Name",
                                        value: firebase.currentUser?.name ?? "Not set",
                                        icon: "person.fill"
                                    )
                                    ProfileRow(
                                        label: "Email",
                                        value: firebase.currentUser?.email ?? "Not set",
                                        icon: "envelope.fill"
                                    )
                                }
                            }

                            // ── Caretaker Info ───────────────────────────
                            ProfileSection(title: "Connected Caretaker") {
                                ProfileRow(
                                    label: "Caretaker Email",
                                    value: firebase.currentUser?.caretakerEmail ?? "Not set",
                                    icon: "heart.fill",
                                    valueColor: .mintDark
                                )

                                if isEditing {
                                    AppTextField(
                                        label: "Caretaker Phone",
                                        placeholder: "e.g. 5551234567",
                                        icon: "phone.fill",
                                        text: $caretakerPhone,
                                        keyboard: .phonePad
                                    )
                                } else {
                                    ProfileRow(
                                        label: "Caretaker Phone",
                                        value: firebase.currentUser?.caretakerPhone.isEmpty == false
                                               ? firebase.currentUser!.caretakerPhone
                                               : "Not set",
                                        icon: "phone.fill"
                                    )
                                }
                            }

                            // ── Edit / Save button ────────────────────────
                            Button {
                                if isEditing { saveProfile() }
                                else { loadCurrentValues(); isEditing = true }
                            } label: {
                                ZStack {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        HStack {
                                            Image(systemName: isEditing
                                                  ? "checkmark.circle.fill"
                                                  : "pencil.circle.fill")
                                            Text(isEditing ? "Save Profile" : "Edit Profile")
                                                .font(.appButton(AppFont.bodyLarge))
                                        }
                                        .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.mintDark)
                                .cornerRadius(16)
                            }

                            Button { firebase.signOut() } label: {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                    Text("Sign Out")
                                        .font(.appBodyBold(AppFont.bodyMedium))
                                }
                                .foregroundColor(.coralDark)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "#FFE8E4"))
                                .cornerRadius(16)
                            }

                            Spacer().frame(height: 40)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func loadCurrentValues() {
        guard let user = firebase.currentUser else { return }
        name           = user.name
        caretakerPhone = user.caretakerPhone
    }

    private func saveProfile() {
        guard let userID = firebase.currentUser?.id else { return }
        isSaving = true
        let data: [String: Any] = [
            "name":           name,
            "caretakerPhone": caretakerPhone
        ]
        firebase.db.collection("users").document(userID).updateData(data) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                if error == nil {
                    firebase.fetchUserProfile(userID: userID)
                    self.isEditing = false
                }
            }
        }
    }
}

// MARK: - Profile Section

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).sectionTitle()
            VStack(spacing: 12) { content }
                .padding(16)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let label:      String
    let value:      String
    let icon:       String
    var valueColor: Color = .darkText

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.grayText)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.appCaption()).foregroundColor(.grayText)
                Text(value).font(.appBodyBold(AppFont.bodyMedium)).foregroundColor(valueColor)
            }
            Spacer()
        }
    }
}

#Preview {
    HealthProfileView()
}
