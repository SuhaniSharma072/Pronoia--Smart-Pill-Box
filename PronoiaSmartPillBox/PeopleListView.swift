//
//  PeopleListView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

// PeopleListView.swift
import SwiftUI

struct PeopleListView: View {

    @StateObject private var firebase = FirebaseManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {

                    ZStack(alignment: .bottomLeading) {
                        LinearGradient.coralToMint
                            .frame(height: 160)
                            .ignoresSafeArea()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Who I'm Caring For")
                                .font(.appBody(AppFont.bodyMedium))
                                .foregroundColor(.white.opacity(0.8))
                            Text("People")
                                .font(.appTitle(AppFont.displayMedium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 24)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {

                            if let elder = firebase.linkedElder {
                                NavigationLink {
                                    PatientDetailView(elder: elder)
                                } label: {
                                    LinkedElderCard(elder: elder)
                                }
                                .padding(.horizontal, 20)
                            } else {
                                VStack(spacing: 12) {
                                    Text("👤").font(.system(size: 40))
                                    Text("No connected elder yet")
                                        .font(.appBodyBold(AppFont.bodyMedium))
                                        .foregroundColor(.darkText)
                                    Text("The older adult you're caring for will appear here once they sign up with your email.")
                                        .font(.appBody(AppFont.bodySmall))
                                        .foregroundColor(.grayText)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(30)
                                .background(Color.white)
                                .cornerRadius(18)
                                .padding(.horizontal, 20)
                            }

                            Spacer().frame(height: 100)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Linked Elder Card

struct LinkedElderCard: View {
    let elder: AppUser

    var elderInitials: String {
        let parts = elder.name.components(separatedBy: " ")
        return parts.compactMap { $0.first }.prefix(2).map { String($0) }.joined().uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.mintLight).frame(width: 52, height: 52)
                Text(elderInitials)
                    .font(.appBodyBold(AppFont.titleMedium))
                    .foregroundColor(.mintDark)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(elder.name)
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.darkText)
                Text(elder.email)
                    .font(.appCaption())
                    .foregroundColor(.grayText)
                Text("Connected ✓")
                    .font(.appCaption(AppFont.tiny))
                    .foregroundColor(.mintDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.mintLight)
                    .cornerRadius(99)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.grayText)
                .font(.system(size: 14))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
    }
}

// MARK: - Patient Detail View

struct PatientDetailView: View {

    let elder: AppUser
    @StateObject private var firebase = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        VStack(spacing: 10) {
                            Text(elder.name)
                                .font(.appTitle(AppFont.titleLarge))
                                .foregroundColor(.darkText)
                            Text(elder.email)
                                .font(.appCaption())
                                .foregroundColor(.grayText)
                        }
                        .padding(.top, 20)

                        Button {
                            firebase.sendAlert(
                                caretakerEmail: elder.caretakerEmail,
                                elderID:        elder.id,
                                elderName:      elder.name,
                                message:        "Gentle reminder: please take your medication 💊",
                                type:           "reminder"
                            ) { _ in }
                        } label: {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text("Send Gentle Reminder")
                                    .font(.appButton(AppFont.bodyLarge))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.mintDark)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle(elder.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.mintDark)
                    }
                }
            }
        }
    }
}

#Preview {
    PeopleListView()
}
