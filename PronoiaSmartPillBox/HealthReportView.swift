//
//  HealthReportView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


// HealthReportView.swift
import SwiftUI

struct HealthReportView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss

    var adherencePercent: Int { Int(firebase.adherenceProgress * 100) }
    var scheduledMeds: [Medication] { firebase.medications.filter { !$0.asNeeded } }
    var takenToday:    Int          { scheduledMeds.filter { $0.taken }.count }
    var missedToday:   Int          { scheduledMeds.filter { !$0.taken }.count }

    var currentMonthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    var streakDays: Int {
        guard let uid = firebase.currentUser?.id else { return 0 }
        return UserDefaults.standard.integer(forKey: "plantStreakDays_\(uid)")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        Text("\(currentMonthLabel) Summary")
                            .sectionTitle()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            ReportStatCard(
                                value: "\(adherencePercent)%",
                                label: "Today",
                                icon:  "pills.fill",
                                color: adherencePercent >= 80 ? .mintDark : .coral
                            )
                            ReportStatCard(
                                value: "\(firebase.medications.count)",
                                label: "Medications",
                                icon:  "cross.fill",
                                color: .mintDark
                            )
                            ReportStatCard(
                                value: "\(firebase.appointments.count)",
                                label: "Appts",
                                icon:  "calendar",
                                color: .coral
                            )
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Today's Medications").sectionTitle()

                            if scheduledMeds.isEmpty {
                                Text("No medications added yet.")
                                    .font(.appBody(AppFont.bodyMedium))
                                    .foregroundColor(.grayText)
                                    .frame(maxWidth: .infinity)
                                    .padding(20)
                                    .background(Color.white)
                                    .cornerRadius(16)
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

                                ForEach(scheduledMeds) { med in
                                    HStack {
                                        Image(systemName: med.taken
                                              ? "checkmark.circle.fill"
                                              : "circle")
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
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Weekly Streak").sectionTitle()

                            HStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { day in
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(day < streakDays
                                                      ? Color.mintDark
                                                      : Color.lightGray)
                                                .frame(width: 32, height: 32)
                                            if day < streakDays {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        Text("D\(day + 1)")
                                            .font(.appCaption(AppFont.tiny))
                                            .foregroundColor(day < streakDays
                                                             ? .mintDark : .grayText)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)

                            Text("\(streakDays)/7 days with full adherence this week")
                                .font(.appBody(AppFont.bodySmall))
                                .foregroundColor(.grayText)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        if !firebase.appointments.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Upcoming Appointments").sectionTitle()

                                ForEach(firebase.appointments.prefix(3)) { appt in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(appt.type)
                                                .font(.appBodyBold(AppFont.bodyMedium))
                                                .foregroundColor(.darkText)
                                            Text(appt.doctor)
                                                .font(.appCaption())
                                                .foregroundColor(.grayText)
                                        }
                                        Spacer()
                                        AmberBadge(
                                            text: appt.date.formatted(
                                                date: .abbreviated, time: .omitted)
                                        )
                                    }
                                    .padding(14)
                                    .background(Color.white)
                                    .cornerRadius(14)
                                    .shadow(color: .shadowColor, radius: 3, x: 0, y: 2)
                                }
                            }
                        }


                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Health Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.mintDark)
                }
            }
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon:  String
    let label: String
    let color: Color
    let bg:    Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(label)
                .font(.appBodyBold(AppFont.bodySmall))
                .foregroundColor(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(bg)
        .cornerRadius(12)
    }
}

// MARK: - Report Stat Card

struct ReportStatCard: View {
    let value: String
    let label: String
    let icon:  String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.appBodyBold(AppFont.titleLarge))
                .foregroundColor(.darkText)
            Text(label)
                .font(.appCaption(AppFont.tiny))
                .foregroundColor(.grayText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .shadowColor, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Share Button

struct ShareButton: View {
    let icon:   String
    let label:  String
    let color:  Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color == .amber ? .amberDark : .white)
                Text(label)
                    .font(.appCaption(AppFont.tiny))
                    .foregroundColor(color == .amber ? .amberDark : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(14)
        }
    }
}

#Preview {
    HealthReportView()
}
