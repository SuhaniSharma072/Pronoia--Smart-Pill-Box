//
//  ContentView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.

//  ArgyleTech//  ArgyleTech
//
import SwiftUI
import FirebaseAuth
struct ContentView: View {
    @StateObject private var firebase = FirebaseManager.shared
    var body: some View {
        Group {
            if firebase.isLoggedIn {
                if let user = firebase.currentUser {
                    if user.isOlderAdult {
                        ElderTabView()
                    } else {
                        CaretakerTabView()
                    }
                } else if firebase.profileFetchFailed {
                    ProfileErrorView()
                } else {
                    LoadingView()
                }
            } else {
                SplashView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: firebase.isLoggedIn)
    }
}
struct ProfileErrorView: View {
    @StateObject private var firebase = FirebaseManager.shared
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("Couldn't load your profile")
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.darkText)
                Text("This account signed in, but no profile data was found for it. Check the Xcode console for details.")
                    .font(.appCaption())
                    .foregroundColor(.grayText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Sign Out") {
                    try? firebase.auth.signOut()
                }
                .font(.appButton(AppFont.bodyMedium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.mintDark)
                .cornerRadius(12)
            }
        }
    }
}
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .mintDark))
                    .scaleEffect(1.4)
                Text("Loading...")
                    .font(.appBody(AppFont.bodyMedium))
                    .foregroundColor(.grayText)
            }
        }
    }
}
#Preview {
    ContentView()
}
