//// CaretakerDashboardView.swift
import SwiftUI
import FirebaseFirestore

struct CaretakerDashboardView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @State private var elderMeds:  [Medication]  = []
    @State private var elderAppts: [Appointment] = []
    @State private var isLoading   = false

    var unreadAlerts: [AppAlert] { firebase.alerts.filter { !$0.isRead } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Header ──────────────────────────────────────
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient.coralToMint
                                .frame(height: 220)
                                .ignoresSafeArea()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Caretaker View")
                                    .font(.appBody(AppFont.bodyMedium))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("Hello, \(firebase.currentUser?.name ?? "Caretaker") 🌿")
                                    .font(.appTitle(AppFont.displayMedium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 22)
                            .padding(.bottom, 24)
                        }

                        VStack(spacing: 20) {

                            // ── Summary chips ────────────────────────────
                            HStack(spacing: 12) {
                                SummaryChip(
                                    value: firebase.linkedElder != nil ? "1" : "0",
                                    label: "Monitored",
                                    color: .mintDark
                                )
                                SummaryChip(
                                    value: "\(unreadAlerts.count)",
                                    label: "Alerts",
                                    color: unreadAlerts.isEmpty ? .mintDark : .coralDark
                                )
                                SummaryChip(
                                    value: unreadAlerts.isEmpty ? "All ✓" : "Check",
                                    label: "Status",
                                    color: unreadAlerts.isEmpty ? .mintDark : .coral
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                            // ── Pill box control ─────────────────────────
                            PillBoxControlCard(firebase: firebase)
                                .padding(.horizontal, 20)

                            // ── Loved ones ───────────────────────────────
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Loved Ones").sectionTitle().padding(.horizontal, 20)

                                if let elder = firebase.linkedElder {
                                    ElderCard(elder: elder).padding(.horizontal, 20)
                                } else {
                                    VStack(spacing: 8) {
                                        Text("No connected elder found.")
                                            .font(.appBody(AppFont.bodyMedium))
                                            .foregroundColor(.grayText)
                                        Text("Ask them to sign up using your email: \(firebase.currentUser?.email ?? "")")
                                            .font(.appCaption(AppFont.tiny))
                                            .foregroundColor(.mintDark)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(20).frame(maxWidth: .infinity)
                                    .background(Color.white).cornerRadius(16)
                                    .padding(.horizontal, 20)
                                }
                            }

                            if let elder = firebase.linkedElder {

                                // ── Elder's medications ──────────────────
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\(elder.name)'s Medications")
                                        .sectionTitle().padding(.horizontal, 20)

                                    if isLoading {
                                        ProgressView().frame(maxWidth: .infinity).padding()
                                    } else if elderMeds.isEmpty {
                                        emptyCard("No medications added yet.")
                                    } else {
                                        ForEach(elderMeds) { med in
                                            ElderMedRow(med: med).padding(.horizontal, 20)
                                        }
                                    }
                                }

                                // ── Elder's upcoming appointments ────────
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\(elder.name)'s Upcoming Appointments")
                                        .sectionTitle().padding(.horizontal, 20)

                                    if isLoading {
                                        ProgressView().frame(maxWidth: .infinity).padding()
                                    } else if elderAppts.isEmpty {
                                        emptyCard("No upcoming appointments.")
                                    } else {
                                        ForEach(elderAppts) { appt in
                                            ElderApptRow(appt: appt).padding(.horizontal, 20)
                                        }
                                    }
                                }

                            }

                            // ── Recent alerts ────────────────────────────
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Recent Alerts").sectionTitle()
                                    Spacer()
                                    if !firebase.alerts.isEmpty {
                                        Text("\(firebase.alerts.count) total")
                                            .font(.appCaption(AppFont.tiny))
                                            .foregroundColor(.grayText)
                                    }
                                }
                                .padding(.horizontal, 20)

                                if firebase.alerts.isEmpty {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.mintDark)
                                        Text("No alerts. Everything looks good!")
                                            .font(.appBody(AppFont.bodyMedium)).foregroundColor(.darkText)
                                    }
                                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.mintLight).cornerRadius(16)
                                    .padding(.horizontal, 20)
                                } else {
                                    ForEach(firebase.alerts.prefix(5)) { alert in
                                        AlertCard(alert: alert)
                                            .padding(.horizontal, 20)
                                            .onTapGesture {
                                                if !alert.isRead {
                                                    firebase.markAlertRead(alertID: alert.id)
                                                }
                                            }
                                    }
                                }
                            }

                            Spacer().frame(height: 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            // Re-fetch whenever the linked elder resolves (can be async after login)
            .onChange(of: firebase.linkedElder) { _, elder in
                if let elder = elder { loadElderData(elderID: elder.id) }
            }
            .onAppear {
                if let elder = firebase.linkedElder {
                    loadElderData(elderID: elder.id)
                }
            }
        }
    }

    @ViewBuilder
    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.appBody(AppFont.bodyMedium)).foregroundColor(.grayText)
            .padding(20).frame(maxWidth: .infinity)
            .background(Color.white).cornerRadius(16)
            .padding(.horizontal, 20)
    }

    private func loadElderData(elderID: String) {
        isLoading = true
        let db    = firebase.db
        let today = Calendar.current.startOfDay(for: Date())

        // ── Medications ──────────────────────────────────────────────
        db.collection("users").document(elderID).collection("medications")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [Caretaker] Meds fetch error: \(error.localizedDescription)")
                }
                let meds: [Medication] = snapshot?.documents.compactMap { doc in
                    let d = doc.data()
                    return Medication(
                        id:           doc.documentID,
                        name:         d["name"]         as? String   ?? "",
                        dosage:       d["dosage"]       as? String   ?? "",
                        frequency:    d["frequency"]    as? String   ?? "",
                        times:        d["times"]        as? [String] ?? [],
                        durationDays: d["durationDays"] as? Int      ?? 0,
                        pillCount:    d["pillCount"]    as? Int      ?? 0,
                        refillAt:     d["refillAt"]     as? Int      ?? 5,
                        notes:        d["notes"]        as? String   ?? "",
                        taken:        d["taken"]        as? Bool     ?? false,
                        asNeeded:     d["asNeeded"]     as? Bool     ?? false,
                        expiryDate:   (d["expiryDate"]  as? Timestamp)?.dateValue(),
                        createdAt:    (d["createdAt"]   as? Timestamp)?.dateValue()
                    )
                } ?? []
                DispatchQueue.main.async { self.elderMeds = meds }
            }

        // ── Appointments — fetch ALL, filter client-side (no composite index needed) ──
        db.collection("users").document(elderID).collection("appointments")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [Caretaker] Appointments fetch error: \(error.localizedDescription)")
                    DispatchQueue.main.async { self.isLoading = false }
                    return
                }

                let all: [Appointment] = snapshot?.documents.compactMap { doc in
                    let d = doc.data()
                    guard let ts = d["date"] as? Timestamp else { return nil }
                    return Appointment(
                        id:     doc.documentID,
                        doctor: d["doctor"] as? String ?? "",
                        type:   d["type"]   as? String ?? "",
                        date:   ts.dateValue(),
                        time:   d["time"]   as? String ?? "",
                        notes:  d["notes"]  as? String ?? ""
                    )
                } ?? []

                print("📅 [Caretaker] Total appointments fetched: \(all.count)")

                // Filter to upcoming only (today onwards), sorted soonest first
                let upcoming = all
                    .filter { $0.date >= today }
                    .sorted { $0.date < $1.date }

                print("📅 [Caretaker] Upcoming appointments: \(upcoming.count)")

                DispatchQueue.main.async {
                    self.elderAppts = upcoming
                    self.isLoading  = false
                }
            }
    }
}

// MARK: - Elder Med Row

struct ElderMedRow: View {
    let med: Medication
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(med.isLowOnPills ? Color(hex: "#FFE8E4") : Color.mintLight)
                    .frame(width: 44, height: 44)
                Text("Rx").font(.appBodyBold(AppFont.bodySmall))
                    .foregroundColor(med.isLowOnPills ? .coralDark : .mintDark)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(med.name).font(.appBodyBold(AppFont.bodyMedium)).foregroundColor(.darkText)
                Text([med.dose, med.frequency].filter { !$0.isEmpty }.joined(separator: " · ")).font(.appCaption()).foregroundColor(.grayText)
                if med.isLowOnPills {
                    Text("⚠ Only \(med.pillCount) pills left")
                        .font(.appCaption(AppFont.tiny)).foregroundColor(.coralDark)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color(hex: "#FFE8E4")).cornerRadius(99)
                }
            }
            Spacer()
            Image(systemName: med.taken ? "checkmark.circle.fill" : "circle")
                .foregroundColor(med.taken ? .mintDark : .lightGray)
                .font(.system(size: 20))
        }
        .padding(14).background(Color.white).cornerRadius(16)
        .shadow(color: .shadowColor, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Elder Appt Row

struct ElderApptRow: View {
    let appt: Appointment
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#FFF5F3")).frame(width: 44, height: 44)
                Text("+").font(.appBodyBold(AppFont.titleMedium)).foregroundColor(.coral)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(appt.type).font(.appBodyBold(AppFont.bodyMedium)).foregroundColor(.darkText)
                Text(appt.doctor).font(.appCaption()).foregroundColor(.grayText)
                HStack(spacing: 6) {
                    AmberBadge(text: appt.date.formatted(date: .abbreviated, time: .omitted))
                    if !appt.time.isEmpty { AmberBadge(text: appt.time) }
                }
            }
            Spacer()
        }
        .padding(14).background(Color.white).cornerRadius(16)
        .shadow(color: .shadowColor, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Shared Components

struct ElderCard: View {
    let elder: AppUser
    var elderInitials: String {
        elder.name.components(separatedBy: " ").compactMap { $0.first }
            .prefix(2).map { String($0) }.joined().uppercased()
    }
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.mintLight).frame(width: 52, height: 52)
                Text(elderInitials).font(.appBodyBold(AppFont.titleMedium)).foregroundColor(.mintDark)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(elder.name).font(.appBodyBold(AppFont.bodyMedium)).foregroundColor(.darkText)
                Text(elder.email).font(.appCaption()).foregroundColor(.grayText)
                Text("Connected ✓")
                    .font(.appCaption(AppFont.tiny)).foregroundColor(.mintDark)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.mintLight).cornerRadius(99)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.grayText).font(.system(size: 14))
        }
        .padding(16).background(Color.white).cornerRadius(18)
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
    }
}

struct SummaryChip: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.appBodyBold(AppFont.titleLarge)).foregroundColor(color)
            Text(label).font(.appCaption(AppFont.tiny)).foregroundColor(.grayText)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color.white).cornerRadius(16)
        .shadow(color: .shadowColor, radius: 4, x: 0, y: 2)
    }
}

struct AlertCard: View {
    let alert: AppAlert
    var alertIcon: String {
        switch alert.type {
        case "sos": return "🆘"
        case "ride": return "🚗"
        case "missed_med": return "💊"
        case "refill": return "⚠️"
        default: return "🔔"
        }
    }
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(alert.type == "sos" ? Color(hex: "#FFE8E4") : Color.mintLight)
                    .frame(width: 40, height: 40)
                Text(alertIcon).font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.appBody(AppFont.bodySmall)).foregroundColor(.darkText).lineLimit(2)
                Text(alert.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.appCaption(AppFont.tiny)).foregroundColor(.grayText)
            }
            Spacer()
            if !alert.isRead { Circle().fill(Color.coralDark).frame(width: 10, height: 10) }
        }
        .padding(14).background(Color.white).cornerRadius(16)
        .shadow(color: .shadowColor, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Pill Box Control Card

struct PillBoxControlCard: View {
    @ObservedObject var firebase: FirebaseManager
    @State private var showScheduleEditor = false
    @State private var justBuzzed = false

    private var isClosed: Bool { firebase.pillBoxLidStatus == "closed" }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isClosed ? Color.mintLight : Color(hex: "#FFF0EC"))
                        .frame(width: 48, height: 48)
                    Text(isClosed ? "📦" : "📭")
                        .font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pill Box").font(.appBodyBold(AppFont.bodyMedium)).foregroundColor(.darkText)
                    Text(statusText).font(.appCaption()).foregroundColor(.grayText)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    buzzNow()
                } label: {
                    HStack(spacing: 6) {
                        if firebase.remoteTriggerBusy {
                            ProgressView().tint(.white)
                        } else {
                            Text(justBuzzed ? "Buzzed ✓" : "🔔 Buzz Now")
                                .font(.appBodyBold(AppFont.bodySmall))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.mintDark)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(firebase.remoteTriggerBusy)

                Button {
                    showScheduleEditor = true
                } label: {
                    Text("⏰ Schedule")
                        .font(.appBodyBold(AppFont.bodySmall))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(.mintDark)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mintDark, lineWidth: 1.5))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
        .sheet(isPresented: $showScheduleEditor) {
            PillBoxScheduleEditor(firebase: firebase)
        }
    }

    private var statusText: String {
        switch firebase.pillBoxLidStatus {
        case "closed": return "Lid closed"
        case "open":   return "Lid open"
        default:       return "Waiting for pill box…"
        }
    }

    private func buzzNow() {
        firebase.triggerRemoteBuzz { success in
            if success {
                justBuzzed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { justBuzzed = false }
            }
        }
    }
}

// MARK: - Pill Box Schedule Editor

struct PillBoxScheduleEditor: View {
    @ObservedObject var firebase: FirebaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var time1 = Date()
    @State private var time2 = Date()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder 1") {
                    DatePicker("Time", selection: $time1, displayedComponents: .hourAndMinute)
                }
                Section("Reminder 2") {
                    DatePicker("Time", selection: $time2, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Pill Box Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { save() }
                        .disabled(isSaving)
                }
            }
            .onAppear {
                var c1 = DateComponents(); c1.hour = firebase.reminderHour1; c1.minute = firebase.reminderMinute1
                var c2 = DateComponents(); c2.hour = firebase.reminderHour2; c2.minute = firebase.reminderMinute2
                time1 = Calendar.current.date(from: c1) ?? Date()
                time2 = Calendar.current.date(from: c2) ?? Date()
            }
        }
    }

    private func save() {
        isSaving = true
        let c1 = Calendar.current.dateComponents([.hour, .minute], from: time1)
        let c2 = Calendar.current.dateComponents([.hour, .minute], from: time2)
        firebase.updateReminderSchedule(
            hour1: c1.hour ?? 22, minute1: c1.minute ?? 0,
            hour2: c2.hour ?? 22, minute2: c2.minute ?? 0
        ) { _ in
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    CaretakerDashboardView()
}
