//
//  AlertsView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


// AlertsView.swift
import SwiftUI

struct AlertsView: View {

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
                            Text("Notifications")
                                .font(.appBody(AppFont.bodyMedium))
                                .foregroundColor(.white.opacity(0.8))

                            HStack {
                                Text("Alerts")
                                    .font(.appTitle(AppFont.displayMedium))
                                    .foregroundColor(.white)

                                if firebase.unreadAlertCount > 0 {
                                    Text("\(firebase.unreadAlertCount)")
                                        .font(.appBodyBold(AppFont.bodySmall))
                                        .foregroundColor(.coralDark)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.white)
                                        .cornerRadius(99)
                                }
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 24)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {

                            if firebase.alerts.isEmpty {
                                VStack(spacing: 16) {
                                    Text("🔔").font(.system(size: 50))
                                    Text("No alerts yet")
                                        .font(.appBodyBold(AppFont.titleMedium))
                                        .foregroundColor(.darkText)
                                    Text("Alerts will appear here when your loved ones need attention")
                                        .font(.appBody(AppFont.bodyMedium))
                                        .foregroundColor(.grayText)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                                .background(Color.white)
                                .cornerRadius(20)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)

                            } else {

                                HStack {
                                    Text("Today")
                                        .font(.appBodyBold(AppFont.bodyMedium))
                                        .foregroundColor(.grayText)
                                    Spacer()
                                    Button { dismissAllAlerts() } label: {
                                        Text("Clear All")
                                            .font(.appBodyBold(AppFont.bodySmall))
                                            .foregroundColor(.coralDark)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(Color(hex: "#FFE8E4"))
                                            .cornerRadius(99)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                                ForEach(firebase.alerts) { alert in
                                    FullAlertCard(alert: alert) {
                                        dismissAlert(alert)
                                    } onRemind: {
                                        sendReminder(for: alert)
                                    }
                                    .padding(.horizontal, 20)
                                    .transition(.asymmetric(
                                        insertion: .opacity,
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                                }
                            }

                            Spacer().frame(height: 100)
                        }
                        .animation(.easeInOut(duration: 0.3), value: firebase.alerts.map { $0.id })
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                for alert in firebase.alerts where !alert.isRead {
                    firebase.markAlertRead(alertID: alert.id)
                }
            }
        }
    }

    private func dismissAlert(_ alert: AppAlert) {
        firebase.deleteAlert(alertID: alert.id)
    }

    private func dismissAllAlerts() {
        for alert in firebase.alerts {
            firebase.deleteAlert(alertID: alert.id)
        }
    }

    // ✅ Key fix: elderID = alert.elderID so the elder's fetchAlerts listener picks it up.
    // caretakerEmail is set to the caretaker's own email so it also appears in their feed.
    private func sendReminder(for alert: AppAlert) {
        guard let caretaker = firebase.currentUser else { return }
        firebase.sendAlert(
            caretakerEmail: caretaker.email,
            elderID:        alert.elderID,
            elderName:      alert.elderName,
            message:        "🔔 Gentle reminder from \(caretaker.name): please take your medication 💊",
            type:           "missed_med"
        ) { _ in }
    }
}

// MARK: - Full Alert Card

struct FullAlertCard: View {
    let alert:     AppAlert
    let onDismiss: () -> Void
    let onRemind:  () -> Void

    @State private var offset:       CGFloat = 0
    @State private var isDismissing          = false
    @State private var remindSent            = false

    var alertColor: Color {
        switch alert.type {
        case "sos":        return .coralDark
        case "ride":       return .mintDark
        case "missed_med": return .coral
        case "refill":     return .amber
        default:           return .mintDark
        }
    }

    var alertBg: Color {
        switch alert.type {
        case "sos":        return Color(hex: "#FFE8E4")
        case "ride":       return Color.mintLight
        case "missed_med": return Color(hex: "#FFE8E4")
        case "refill":     return Color.amber.opacity(0.2)
        default:           return Color.mintLight
        }
    }

    var alertIcon: String {
        switch alert.type {
        case "sos":        return "🆘"
        case "ride":       return "🚗"
        case "missed_med": return "💊"
        case "refill":     return "⚠️"
        default:           return "🔔"
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {

            RoundedRectangle(cornerRadius: 18)
                .fill(Color.coralDark)
                .overlay(
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(.trailing, 20),
                    alignment: .trailing
                )

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(alertBg)
                        .frame(width: 52, height: 52)
                    Text(alertIcon)
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(alert.elderName)
                            .font(.appBodyBold(AppFont.bodyMedium))
                            .foregroundColor(.darkText)
                        Spacer()
                        Text(timeAgo(from: alert.timestamp))
                            .font(.appCaption(AppFont.tiny))
                            .foregroundColor(.grayText)

                        Button { triggerDismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.grayText)
                        }
                    }

                    Text(alert.message)
                        .font(.appBody(AppFont.bodySmall))
                        .foregroundColor(.darkText)
                        .lineLimit(2)

                    Button {
                        guard !remindSent else { return }
                        remindSent = true
                        onRemind()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: remindSent ? "checkmark.circle.fill" : "bell.fill")
                                .font(.system(size: 11))
                            Text(remindSent ? "Sent!" : "Remind")
                                .font(.appBodyBold(AppFont.tiny))
                        }
                        .foregroundColor(remindSent ? .mintDark : .coralDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(remindSent ? Color.mintLight : Color(hex: "#FFE8E4"))
                        .cornerRadius(99)
                    }
                    .disabled(remindSent)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(alert.isRead ? Color.clear : alertColor, lineWidth: 2)
            )
            .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 { offset = value.translation.width }
                    }
                    .onEnded { value in
                        if value.translation.width < -80 {
                            triggerDismiss()
                        } else {
                            withAnimation(.spring()) { offset = 0 }
                        }
                    }
            )
            .opacity(isDismissing ? 0 : 1)
        }
        .clipped()
    }

    private func triggerDismiss() {
        withAnimation(.easeInOut(duration: 0.25)) {
            offset       = -400
            isDismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60    { return "Just now" }
        if seconds < 3600  { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

#Preview {
    AlertsView()
}
