////
//  ElderHomeView.swift
//  ArgyleTech

///
/////// ElderHomeView.swift


// ElderHomeView.swift
import SwiftUI

struct ElderHomeView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @State private var showAddMed  = false
    @State private var showReport  = false

    // ✅ Any unread reminder alerts from the caretaker
    var reminderAlerts: [AppAlert] {
        firebase.alerts.filter { !$0.isRead && $0.type == "missed_med" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        HeaderView(
                            firebase:   firebase,
                            showAddMed: $showAddMed,
                            showReport: $showReport
                        )

                        VStack(spacing: 16) {

                            // ✅ Show caretaker reminder banners first
                            ForEach(reminderAlerts) { alert in
                                ReminderAlertBanner(alert: alert) {
                                    firebase.markAlertRead(alertID: alert.id)
                                }
                                .padding(.horizontal, 20)
                            }

                            // Next med due banner
                            if let nextMed = firebase.nextMedDue {
                                AlertBanner(medication: nextMed)
                                    .padding(.horizontal, 20)
                            }

                            PillBoxStatusCard(firebase: firebase)
                                .padding(.horizontal, 20)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Today's Medications")
                                    .sectionTitle()
                                    .padding(.horizontal, 20)

                                if firebase.medications.isEmpty {
                                    EmptyMedsCard()
                                        .padding(.horizontal, 20)
                                } else {
                                    ForEach(firebase.medications.filter { !$0.asNeeded }) { med in
                                        MedCard(medication: med)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }

                            if let appt = firebase.appointments.first {
                                UpcomingApptCard(appointment: appt)
                                    .padding(.horizontal, 20)
                            }

                            Spacer().frame(height: 100)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddMed) { AddMedicationView() }
            .sheet(isPresented: $showReport) { HealthReportView() }
        }
    }
}

// MARK: - Reminder Alert Banner (from caretaker)

struct ReminderAlertBanner: View {
    let alert:     AppAlert
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 44, height: 44)
                Text("🔔")
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Reminder from your caretaker")
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.white)
                Text(alert.message)
                    .font(.appBody(AppFont.bodySmall))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            Spacer()
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(16)
        .background(Color.mintDark)
        .cornerRadius(20)
        .shadow(color: Color.mintDark.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Header

struct HeaderView: View {
    @ObservedObject var firebase: FirebaseManager
    @Binding var showAddMed: Bool
    @Binding var showReport: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.mintHeader
                .frame(height: 220)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                     
                        Text("\(firebase.currentUser?.name ?? "Friend") ")
                            .font(.appTitle(AppFont.displayMedium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    ProgressRing(
                        progress: firebase.adherenceProgress,
                        taken:    firebase.takenCount,
                        total:    firebase.medications.filter { !$0.asNeeded }.count
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Today's progress")
                            .font(.appCaption())
                            .foregroundColor(.mintLight)
                        Spacer()
                        Text("\(Int(firebase.adherenceProgress * 100))%")
                            .font(.appBodyBold(AppFont.caption))
                            .foregroundColor(.white)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .frame(width: geo.size.width * firebase.adherenceProgress, height: 10)
                                .animation(.easeInOut, value: firebase.adherenceProgress)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.top, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        QuickActionChip(label: "💊 Add Med", color: .white.opacity(0.25)) { showAddMed = true }
                        QuickActionChip(label: "📋 Report",  color: .white.opacity(0.25)) { showReport = true }
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
    }


}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let taken:    Int
    let total:    Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.2))
                .frame(width: 88, height: 88)

            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 7)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            VStack(spacing: 0) {
                Text("\(taken)/\(total)")
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.white)
                Text("MEDS")
                    .font(.appCaption(AppFont.tiny))
                    .foregroundColor(.mintLight)
            }
        }
    }
}

// MARK: - Quick Action Chip

struct QuickActionChip: View {
    let label:  String
    let color:  Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.appBodyBold(AppFont.bodySmall))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(color)
                .cornerRadius(99)
                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
        }
    }
}

// MARK: - Alert Banner (next med due)

struct AlertBanner: View {
    let medication: Medication

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 44, height: 44)
                Text("!")
                    .font(.appBodyBold(AppFont.titleMedium))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Reminder!")
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.white)
                Text("\([medication.name, medication.dose].filter { !$0.isEmpty }.joined(separator: " ")) due at \(medication.nextTime)")
                    .font(.appBody(AppFont.bodySmall))
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.coral)
        .cornerRadius(20)
        .shadow(color: Color.coral.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Med Card

struct MedCard: View {

    @StateObject private var firebase = FirebaseManager.shared
    let medication: Medication

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(medication.taken ? Color.mintLight : Color(hex: "#FFF0EC"))
                    .frame(width: 48, height: 48)
                Text("Rx")
                    .font(.appBodyBold(AppFont.bodySmall))
                    .foregroundColor(medication.taken ? .mintDark : .coralDark)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(medication.taken ? .grayText : .darkText)
                    .strikethrough(medication.taken, color: .grayText)

                Text([medication.dose, medication.nextTime].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                    .font(.appCaption())
                    .foregroundColor(.grayText)

                if medication.isLowOnPills {
                    Text("⚠ \(medication.pillCount) pills left")
                        .font(.appCaption(AppFont.tiny))
                        .foregroundColor(.coralDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#FFE8E4"))
                        .cornerRadius(99)
                }
            }

            Spacer()

            Button { markTaken() } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(medication.taken ? Color.mintDark : Color.lightGray)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(medication.taken ? Color.mintDark : Color.clear, lineWidth: 2)
        )
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
    }

    private func markTaken() {
        guard let userID = firebase.currentUser?.id else { return }
        firebase.markMedicationTaken(userID: userID, medID: medication.id, taken: !medication.taken) { _ in }
    }
}

// MARK: - Empty Meds Card

struct EmptyMedsCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("💊").font(.system(size: 40))
            Text("No medications added yet")
                .font(.appBodyBold(AppFont.bodyMedium))
                .foregroundColor(.darkText)
            Text("Tap \"Add Med\" above to get started")
                .font(.appBody(AppFont.bodySmall))
                .foregroundColor(.grayText)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
    }
}

// MARK: - Upcoming Appointment Card

struct UpcomingApptCard: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#FFF5F3"))
                    .frame(width: 48, height: 48)
                Text("+")
                    .font(.appBodyBold(AppFont.titleMedium))
                    .foregroundColor(.coral)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.type)
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.darkText)
                Text(appointment.doctor)
                    .font(.appCaption())
                    .foregroundColor(.grayText)
                HStack(spacing: 8) {
                    AmberBadge(text: appointment.date.formatted(date: .abbreviated, time: .omitted))
                    AmberBadge(text: appointment.time)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
    }
}

// MARK: - Pill Box Status Card

struct PillBoxStatusCard: View {
    @ObservedObject var firebase: FirebaseManager

    private var isClosed: Bool { firebase.pillBoxLidStatus == "closed" }
    private var isOpen:   Bool { firebase.pillBoxLidStatus == "open" }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isClosed ? Color.mintLight : Color(hex: "#FFF0EC"))
                    .frame(width: 48, height: 48)
                Text(isClosed ? "📦" : "📭")
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Pill Box")
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.darkText)
                Text(statusText)
                    .font(.appCaption())
                    .foregroundColor(.grayText)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
    }

    private var statusText: String {
        switch firebase.pillBoxLidStatus {
        case "closed": return "Lid closed"
        case "open":   return "Lid open"
        default:       return "Waiting for pill box…"
        }
    }
}

#Preview {
    ElderHomeView()
}
