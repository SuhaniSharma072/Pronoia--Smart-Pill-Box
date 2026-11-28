//
//  SplashView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


// SplashView.swift
import SwiftUI

struct SplashView: View {
    @State private var showSignUp = false
    @State private var showSignIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.mintSubtle.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // ── Logo from Assets.xcassets ─────────────────────
                    Image("thelogo")
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 180, height: 180)
                        .shadow(color: .shadowColor, radius: 20, x: 0, y: 8)
                        .padding(.bottom, 32)

                    // ── Branding ──────────────────────────────────────
                    Text("PRONOIA")
                        .font(.appTitle(AppFont.displayLarge))
                        .foregroundColor(.darkText)
                        .kerning(4)

                    Text("pro  ·  noy  ·  ah")
                        .font(.appTitleItalic(AppFont.bodyMedium))
                        .foregroundColor(.grayText)
                        .padding(.top, 6)

                    Rectangle()
                        .fill(Color.gold)
                        .frame(width: 160, height: 1.5)
                        .padding(.vertical, 16)

                    Text("When care aligns with you")
                        .font(.appTitleRegular(AppFont.titleSmall))
                        .foregroundColor(.darkText)
                        .multilineTextAlignment(.center)

                    Spacer()

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

                    Spacer()

                    // ── Buttons ───────────────────────────────────────
                    VStack(spacing: 14) {
                        Button { showSignUp = true } label: {
                            Text("Get Started")
                                .font(.appButton(AppFont.bodyLarge))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.mintDark)
                                .cornerRadius(16)
                        }

                        Button { showSignIn = true } label: {
                            Text("I already have an account")
                                .font(.appButton(AppFont.bodyMedium))
                                .foregroundColor(.mintDark)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.mintDark, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showSignUp) { SignUpView() }
            .navigationDestination(isPresented: $showSignIn) { SignInView() }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SplashView()
}
