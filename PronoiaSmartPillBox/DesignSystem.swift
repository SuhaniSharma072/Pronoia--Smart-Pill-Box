//
//  DesignSystem.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

//
//  DesignSystem.swift
//  ArgyleTech

//

import SwiftUI

// MARK: - Colors

extension Color {
    static let mintPrimary   = Color(hex: "#99D6B3")
    static let mintDark      = Color(hex: "#2E9E7A")
    static let mintLight     = Color(hex: "#D4EFE3")
    static let coral         = Color(hex: "#F4A896")
    static let coralDark     = Color(hex: "#C4614F")
    static let amber         = Color(hex: "#F7DFA0")
    static let amberDark     = Color(hex: "#8A6F20")
    static let appBackground = Color(hex: "#F8FDFB")
    static let darkText      = Color(hex: "#1E3A30")
    static let grayText      = Color(hex: "#8AA89C")
    static let lightGray     = Color(hex: "#E8F0EC")
    static let shadowColor   = Color(hex: "#D8EDE4")
    static let gold          = Color(hex: "#C9A84C")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let mintHeader = LinearGradient(
        colors: [.mintPrimary, .mintDark],
        startPoint: .top,
        endPoint: .bottom
    )
    static let coralToMint = LinearGradient(
        colors: [.coral, .mintDark],
        startPoint: .top,
        endPoint: .bottom
    )
    static let mintSubtle = LinearGradient(
        colors: [.mintLight, .appBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

struct AppFont {
    static let displayLarge:  CGFloat = 34
    static let displayMedium: CGFloat = 28
    static let displaySmall:  CGFloat = 22
    static let titleLarge:    CGFloat = 24
    static let titleMedium:   CGFloat = 20
    static let titleSmall:    CGFloat = 18
    static let bodyLarge:     CGFloat = 18
    static let bodyMedium:    CGFloat = 16
    static let bodySmall:     CGFloat = 14
    static let caption:       CGFloat = 13
    static let tiny:          CGFloat = 11
}

extension Font {
    static func appTitle(_ size: CGFloat = AppFont.titleLarge) -> Font {
        .custom("Georgia-Bold", size: size)
    }
    static func appTitleRegular(_ size: CGFloat = AppFont.titleMedium) -> Font {
        .custom("Georgia", size: size)
    }
    static func appTitleItalic(_ size: CGFloat = AppFont.bodyMedium) -> Font {
        .custom("Georgia-Italic", size: size)
    }
    static func appBody(_ size: CGFloat = AppFont.bodyMedium) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func appBodyBold(_ size: CGFloat = AppFont.bodyMedium) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func appCaption(_ size: CGFloat = AppFont.caption) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func appButton(_ size: CGFloat = AppFont.bodyLarge) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

// MARK: - Text Modifiers

struct AppTextStyle: ViewModifier {
    var font:  Font
    var color: Color
    func body(content: Content) -> some View {
        content.font(font).foregroundColor(color)
    }
}

extension View {
    func screenTitle() -> some View {
        modifier(AppTextStyle(font: .appTitle(AppFont.displayMedium), color: .white))
    }
    func sectionTitle() -> some View {
        modifier(AppTextStyle(font: .appTitle(AppFont.titleMedium), color: .darkText))
    }
    func bodyText() -> some View {
        modifier(AppTextStyle(font: .appBody(AppFont.bodyMedium), color: .darkText))
    }
    func captionText() -> some View {
        modifier(AppTextStyle(font: .appCaption(AppFont.caption), color: .grayText))
    }
    func cardTitle() -> some View {
        modifier(AppTextStyle(font: .appBodyBold(AppFont.bodyLarge), color: .darkText))
    }
}

// MARK: - Shared UI Components

/// Reusable labelled text field with icon
struct AppTextField: View {
    let label:       String
    let placeholder: String
    let icon:        String
    @Binding var text: String
    var keyboard:    UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.appBodyBold(AppFont.bodySmall))
                .foregroundColor(.darkText)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(.grayText)
                    .frame(width: 20)
                TextField(placeholder, text: $text)
                    .font(.appBody(AppFont.bodyMedium))
                    .keyboardType(keyboard)
                    // FIX: autocapitalization() is deprecated; use textInputAutocapitalization
                    .textInputAutocapitalization(.never)
            }
            .padding(16)
            .frame(height: 54)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.lightGray, lineWidth: 1)
            )
        }
    }
}

/// Amber-coloured pill badge
struct AmberBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.appCaption(AppFont.tiny))
            .foregroundColor(.amberDark)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.amber)
            .cornerRadius(99)
    }
}

/// Generic section wrapper used in profile / caretaker views
struct MenuSection<Content: View>: View {
    let title:   String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.appBodyBold(AppFont.bodySmall))
                .foregroundColor(.grayText)
                .padding(.horizontal, 4)

            VStack(spacing: 0) { content }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .shadowColor, radius: 4, x: 0, y: 2)
        }
    }
}

/// Row inside a MenuSection
struct MenuRow: View {
    let icon:     String
    let label:    String
    let subtitle: String
    let color:    Color
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.appBodyBold(AppFont.bodyMedium))
                        .foregroundColor(.darkText)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.appCaption())
                            .foregroundColor(.grayText)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.grayText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
