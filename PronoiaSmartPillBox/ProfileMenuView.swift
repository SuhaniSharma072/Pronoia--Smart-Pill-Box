//
//  ProfileMenuView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

// ProfileMenuView.swift
import SwiftUI

struct ProfileMenuView: View {

    @StateObject private var firebase     = FirebaseManager.shared
    @State private var showSignOutConfirm = false
    @State private var showHealthProfile  = false
    @State private var showHealthReport   = false

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

                        // Header
                        ZStack {
                            LinearGradient.mintHeader
                                .frame(height: 200)
                                .ignoresSafeArea()

                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    Text(initials)
                                        .font(.appBodyBold(AppFont.displayMedium))
                                        .foregroundColor(.white)
                                }
                                Text(firebase.currentUser?.name ?? "")
                                    .font(.appTitle(AppFont.titleLarge))
                                    .foregroundColor(.white)
                                Text("Elder Account")
                                    .font(.appCaption())
                                    .foregroundColor(.mintLight)
                            }
                        }

                        VStack(spacing: 16) {

                            MenuSection(title: "My Account") {
                                MenuRow(
                                    icon: "person.fill",
                                    label: "Health Profile",
                                    subtitle: "",
                                    color: .mintDark
                                ) { showHealthProfile = true }

                                MenuRow(
                                    icon: "doc.text.fill",
                                    label: "Health Report",
                                    subtitle: "",
                                    color: .mintDark
                                ) { showHealthReport = true }
                            }

                            Button { showSignOutConfirm = true } label: {
                                HStack {
                                    Image(systemName: "arrow.right.square.fill")
                                        .font(.system(size: 20))
                                    Text("Sign Out").font(.appButton(AppFont.bodyLarge))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 56)
                                .background(Color.coral).cornerRadius(16)
                            }

                            Text("Made by Team Argyle Tech ♡")
                                .font(.appCaption(AppFont.tiny))
                                .foregroundColor(.grayText)
                                .padding(.bottom, 100)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showHealthProfile) { HealthProfileView() }
            .sheet(isPresented: $showHealthReport)  { HealthReportView()  }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm,
                                titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { firebase.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    ProfileMenuView()
}
