//
//  ReportsView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


// ReportsView.swift
import SwiftUI
import FirebaseFirestore

struct ReportsView: View {

    @StateObject private var firebase = FirebaseManager.shared

    @State private var elderMeds:     [Medication] = []
    @State private var isLoadingMeds  = false

    // Scheduled meds — elder sees own, caretaker sees fetched elderMeds
    var scheduledMeds: [Medication] {
        if firebase.currentUser?.isCaretaker == true {
            return elderMeds.filter { !$0.asNeeded }
        } else {
            return firebase.medications.filter { !$0.asNeeded }
        }
    }

    var takenToday:  Int { scheduledMeds.filter { $0.taken }.count }
    var missedToday: Int { max(scheduledMeds.count - takenToday, 0) }

    // ✅ Calculate adherence from the correct source — never reads firebase.adherenceProgress for caretaker
    var adherencePercent: Int {
        let total = scheduledMeds.count
        guard total > 0 else { return 0 }
        return Int((Double(takenToday) / Double(total)) * 100)
    }

    var currentMonthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    var streakDays: Int {
        if firebase.currentUser?.isCaretaker == true {
            guard let uid = firebase.linkedElder?.id else { return 0 }
            return UserDefaults.standard.integer(forKey: "plantStreakDays_\(uid)")
        } else {
            guard let uid = firebase.currentUser?.id else { return 0 }
            return UserDefaults.standard.integer(forKey: "plantStreakDays_\(uid)")
        }
    }

    var medSectionTitle: String {
        if firebase.currentUser?.isCaretaker == true {
            return "\(firebase.linkedElder?.name ?? "Elder")'s Medications Today"
        } else {
            return "My Medications Today"
        }
    }

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
                            Text("Monthly Overview")
                                .font(.appBody(AppFont.bodyMedium))
                                .foregroundColor(.white.opacity(0.8))
                            Text("Reports")
                                .font(.appTitle(AppFont.displayMedium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 24)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            Text("\(currentMonthLabel) Report")
                                .sectionTitle()
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            // ── Stat cards ───────────────────────────────
                            HStack(spacing: 12) {
                                ReportStatCard(
                                    value: "\(adherencePercent)%",
                                    label: "Today",
                                    icon:  "pills.fill",
                                    color: adherencePercent >= 80 ? .mintDark : .coral
                                )
                                ReportStatCard(
                                    value: "\(missedToday)",
                                    label: "Remaining",
                                    icon:  "xmark.circle.fill",
                                    color: missedToday == 0 ? .mintDark : .coralDark
                                )
                                ReportStatCard(
                                    value: "\(firebase.appointments.count)",
                                    label: "Appointments",
                                    icon:  "calendar",
                                    color: .coral
                                )
                            }
                            .padding(.horizontal, 20)

                            // ── Medication breakdown — both roles ─────────
                            VStack(alignment: .leading, spacing: 12) {
                                Text(medSectionTitle)
                                    .sectionTitle()
                                    .padding(.horizontal, 20)

                                if isLoadingMeds {
                                    ProgressView().frame(maxWidth: .infinity).padding()
                                } else if scheduledMeds.isEmpty {
                                    Text("No medications on record.")
                                        .font(.appBody(AppFont.bodyMedium))
                                        .foregroundColor(.grayText)
                                        .padding(20)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .padding(.horizontal, 20)
                                } else {
                                    HStack(spacing: 12) {
                                        StatPill(
                                            icon:  "checkmark.circle.fill",
                                            label: "\(takenToday) Taken",
                                            color: .mintDark,
                                            bg:    Color.mintLight
                                        )
                                        StatPill(
                                            icon:  "xmark.circle.fill",
                                            label: "\(missedToday) Remaining",
                                            color: .coralDark,
                                            bg:    Color(hex: "#FFE8E4")
                                        )
                                    }
                                    .padding(.horizontal, 20)

                                    ForEach(scheduledMeds) { med in
                                        HStack {
                                            Image(systemName: med.taken
                                                  ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(med.taken ? .mintDark : .lightGray)
                                                .font(.system(size: 18))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(med.name)
                                                    .font(.appBodyBold(AppFont.bodyMedium))
                                                    .foregroundColor(.darkText)
                                                    .strikethrough(med.taken, color: .grayText)
                                                if !med.dose.isEmpty {
                                                    Text(med.dose)
                                                        .font(.appCaption())
                                                        .foregroundColor(.grayText)
                                                }
                                            }
                                            Spacer()
                                            Text(med.taken ? "Taken ✓" : "Pending")
                                                .font(.appCaption(AppFont.tiny))
                                                .foregroundColor(med.taken ? .mintDark : .grayText)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(med.taken ? Color.mintLight : Color.lightGray)
                                                .cornerRadius(99)
                                        }
                                        .padding(14)
                                        .background(Color.white)
                                        .cornerRadius(14)
                                        .shadow(color: .shadowColor, radius: 3, x: 0, y: 2)
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }

                            // ── Weekly streak ────────────────────────────
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Weekly Streak").sectionTitle().padding(.horizontal, 20)

                                HStack(spacing: 0) {
                                    ForEach(0..<7, id: \.self) { day in
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle()
                                                    .fill(day < streakDays ? Color.mintDark : Color.lightGray)
                                                    .frame(width: 32, height: 32)
                                                if day < streakDays {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            Text("D\(day + 1)")
                                                .font(.appCaption(AppFont.tiny))
                                                .foregroundColor(day < streakDays ? .mintDark : .grayText)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
                                .padding(.horizontal, 20)

                                Text("\(streakDays)/7 perfect days this week")
                                    .font(.appBody(AppFont.bodySmall))
                                    .foregroundColor(.grayText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            // ── Share ─────────────────────────────────────
                            

                            Spacer().frame(height: 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { fetchElderMedsIfNeeded() }
            .onChange(of: firebase.linkedElder) { _, _ in fetchElderMedsIfNeeded() }
        }
    }

    private func fetchElderMedsIfNeeded() {
        guard firebase.currentUser?.isCaretaker == true,
              let elderID = firebase.linkedElder?.id else { return }
        isLoadingMeds = true
        firebase.db.collection("users").document(elderID).collection("medications")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [ReportsView] Elder meds fetch error: \(error.localizedDescription)")
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
                DispatchQueue.main.async {
                    self.elderMeds     = meds
                    self.isLoadingMeds = false
                }
            }
    }
}

#Preview {
    ReportsView()
}
