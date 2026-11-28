//
//  FamilyView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


// FamilyView.swift
import SwiftUI

struct FamilyView: View {

    @StateObject private var firebase = FirebaseManager.shared

    var caretakerInitials: String {
        let parts = (firebase.currentUser?.caretakerName ?? "C")
            .components(separatedBy: " ")
        return parts.compactMap { $0.first }
            .prefix(2)
            .map { String($0) }
            .joined()
            .uppercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        ZStack(alignment: .bottomLeading) {
                            LinearGradient.mintHeader
                                .frame(height: 160)
                                .ignoresSafeArea()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Support Network")
                                    .font(.appBody(AppFont.bodyMedium))
                                    .foregroundColor(.mintLight)
                                Text("Family & Care")
                                    .font(.appTitle(AppFont.displayMedium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 22)
                            .padding(.bottom, 24)
                        }

                        VStack(spacing: 20) {

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Primary Caretaker")
                                    .sectionTitle()

                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.mintLight)
                                            .frame(width: 64, height: 64)
                                        Text(caretakerInitials)
                                            .font(.appBodyBold(AppFont.titleMedium))
                                            .foregroundColor(.mintDark)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(
                                            firebase.currentUser?.caretakerName.isEmpty == false
                                            ? (firebase.currentUser?.caretakerName ?? "")
                                            : "Your Caretaker"
                                        )
                                        .font(.appBodyBold(AppFont.bodyMedium))
                                        .foregroundColor(.darkText)

                                        Text(firebase.currentUser?.caretakerEmail ?? "")
                                            .font(.appCaption())
                                            .foregroundColor(.grayText)

                                        Text("Connected ✓")
                                            .font(.appCaption(AppFont.tiny))
                                            .foregroundColor(.mintDark)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 3)
                                            .background(Color.mintLight)
                                            .cornerRadius(99)
                                    }

                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                            VStack(spacing: 6) {
                                Text("\"When the universe is ")
                                    .font(.appTitleItalic(AppFont.bodySmall))
                                    .foregroundColor(.darkText)
                                Text("conspiring to support you\"")
                                    .font(.appTitleItalic(AppFont.bodySmall))
                                    .foregroundColor(.darkText)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .shadowColor, radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    FamilyView()
}
