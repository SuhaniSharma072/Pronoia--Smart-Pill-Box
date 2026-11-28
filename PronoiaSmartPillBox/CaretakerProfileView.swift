//
//  CaretakerProfileView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

//  CaretakerProfileView.swift

//
import SwiftUI

struct CaretakerProfileView: View {

    @StateObject private var firebase     = FirebaseManager.shared
    @State private var showSignOutConfirm = false

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
                            LinearGradient.coralToMint
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
                                Text("Caretaker Account")
                                    .font(.appCaption())
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }

                        VStack(spacing: 16) {

                            MenuSection(title: "Account") {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(Color.mintLight).frame(width: 44, height: 44)
                                        Image(systemName: "envelope.fill").foregroundColor(.mintDark)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Email").font(.appCaption()).foregroundColor(.grayText)
                                        Text(firebase.currentUser?.email ?? "")
                                            .font(.appBodyBold(AppFont.bodyMedium))
                                            .foregroundColor(.darkText)
                                    }
                                    Spacer()
                                }
                                .padding(14)

                                
                            }

                            MenuSection(title: "Who I'm Monitoring") {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#FFE8E4")).frame(width: 44, height: 44)
                                        Image(systemName: "heart.fill").foregroundColor(.coral)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Connected Elder").font(.appCaption()).foregroundColor(.grayText)
                                        Text(firebase.linkedElder?.name ?? firebase.currentUser?.caretakerEmail ?? "Not set")
                                            .font(.appBodyBold(AppFont.bodyMedium))
                                            .foregroundColor(.darkText)
                                    }
                                    Spacer()
                                }
                                .padding(14)

                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(Color.mintLight).frame(width: 44, height: 44)
                                        Image(systemName: "bell.badge.fill").foregroundColor(.mintDark)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Unread Alerts").font(.appCaption()).foregroundColor(.grayText)
                                        Text("\(firebase.unreadAlertCount) alerts")
                                            .font(.appBodyBold(AppFont.bodyMedium))
                                            .foregroundColor(firebase.unreadAlertCount > 0 ? .coral : .mintDark)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                            }

                            MenuSection(title: "") {
                                VStack(spacing: 8) {
                                    Text("\"When the whole universe")
                                        .font(.appTitleItalic(AppFont.bodySmall))
                                        .foregroundColor(.darkText)
                                    Text("is conspiring to support you\"")
                                        .font(.appTitleItalic(AppFont.bodySmall))
                                        .foregroundColor(.darkText)
                                   
                                }
                                .multilineTextAlignment(.center)
                                .padding(20)

                                .padding(.top, 16)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                            }

                            Spacer()
                            
                            Button {
                                showSignOutConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.right.square.fill").font(.system(size: 20))
                                    Text("Sign Out").font(.appButton(AppFont.bodyLarge))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.coral)
                                .cornerRadius(16)
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
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    // FIX: proper method call, no $
                    firebase.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    CaretakerProfileView()
}
