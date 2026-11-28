//
//  AddMedicationView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


import SwiftUI
import UserNotifications

struct AddMedicationView: View {

    @StateObject private var firebase = FirebaseManager.shared

    @State private var medicationName = ""
    @State private var notes          = ""
    @State private var times: [String] = []
    @State private var newTimeDate    = Date()
    @State private var showError      = false
    @State private var errorMessage   = ""
    @State private var isSaving       = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        Text("Add Medication")
                            .font(.appTitle(AppFont.displayMedium))
                            .foregroundColor(.darkText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)

                        fieldView(label: "Medication Name", placeholder: "e.g. Ibuprofen", icon: "pills", text: $medicationName)

                        // Times
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Times to Take")
                                .font(.appBodyBold(AppFont.bodySmall))
                                .foregroundColor(.darkText)

                            HStack {
                                DatePicker("", selection: $newTimeDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .tint(.mintDark)

                                Spacer()

                                Button("Add") {
                                    let text = formatTime(newTimeDate)
                                    if !times.contains(text) {
                                        times.append(text)
                                    }
                                }
                                .font(.appBodyBold(AppFont.bodyMedium))
                                .foregroundColor(.mintDark)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lightGray, lineWidth: 1))

                            ForEach(times, id: \.self) { time in
                                HStack {
                                    Text(time)
                                        .font(.appCaption())
                                        .foregroundColor(.mintDark)
                                    Spacer()
                                    Button {
                                        times.removeAll { $0 == time }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.grayText)
                                    }
                                }
                                .padding(10)
                                .background(Color.mintLight)
                                .cornerRadius(10)
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.appBodyBold(AppFont.bodySmall))
                                .foregroundColor(.darkText)

                            HStack(alignment: .top) {
                                Image(systemName: "note.text").foregroundColor(.grayText)
                                TextField("Optional notes...", text: $notes, axis: .vertical)
                                    .font(.appBody(AppFont.bodyMedium))
                                    .lineLimit(3...6)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lightGray, lineWidth: 1))
                        }

                        if showError {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(errorMessage).font(.appBody(AppFont.bodySmall))
                            }
                            .foregroundColor(.coralDark)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#FFE8E4"))
                            .cornerRadius(12)
                        }

                        Button(action: saveMedication) {
                            ZStack {
                                if isSaving {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save Medication")
                                        .font(.appButton(AppFont.bodyLarge))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.mintDark)
                            .cornerRadius(16)
                        }
                        .disabled(isSaving)
                        .padding(.top)

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear { NotificationManager.shared.requestPermission() }
        }
    }

    private func fieldView(label: String, placeholder: String, icon: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.appBodyBold(AppFont.bodySmall))
                .foregroundColor(.darkText)

            HStack {
                Image(systemName: icon).foregroundColor(.grayText)
                TextField(placeholder, text: text)
                    .font(.appBody(AppFont.bodyMedium))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lightGray, lineWidth: 1))
        }
    }

    // Turns the picked time into text like "12:40 AM" (always 12-hour with AM/PM).
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func saveMedication() {
        guard !medicationName.isEmpty else { showError("Please enter medication name"); return }
        guard !times.isEmpty          else { showError("Please add at least one time");  return }

        isSaving = true

        firebase.saveMedication(
            name:         medicationName,
            dosage:       "",
            frequency:    "",
            times:        times,
            durationDays: 0,
            pillCount:    0,
            refillAt:     0,
            notes:        notes
        ) { success, error in
            DispatchQueue.main.async {
                isSaving = false
                if success {
                    NotificationManager.shared.scheduleMedicationNotifications(
                        medName: medicationName,
                        times:   times
                    )
                    syncTimesToPillBox(times)
                    clearForm()
                } else {
                    showError(error ?? "Failed to save medication")
                }
            }
        }
    }

    // Sends the first two times to the pill box (it holds two reminder slots).
    // If only one time was entered, the box's existing second reminder is kept.
    private func syncTimesToPillBox(_ timeStrings: [String]) {
        let parsed = timeStrings
            .compactMap { parseTime($0) }
            .sorted { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }

        guard let first = parsed.first else { return }

        let second = parsed.count > 1
            ? parsed[1]
            : (hour: firebase.reminderHour2, minute: firebase.reminderMinute2)

        firebase.updateReminderSchedule(
            hour1: first.hour,  minute1: first.minute,
            hour2: second.hour, minute2: second.minute
        ) { _ in }
    }

    // Accepts "8:00 AM", "8 am", "8:00pm", "20:00", "8:30".
    private func parseTime(_ text: String) -> (hour: Int, minute: Int)? {
        let cleaned = text.trimmingCharacters(in: .whitespaces).uppercased()
        let isPM = cleaned.contains("PM")
        let isAM = cleaned.contains("AM")

        let digits = cleaned
            .replacingOccurrences(of: "AM", with: "")
            .replacingOccurrences(of: "PM", with: "")
            .trimmingCharacters(in: .whitespaces)

        let parts = digits.split(separator: ":")
        guard let first = parts.first, var hour = Int(first) else { return nil }
        let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0

        if isPM && hour < 12 { hour += 12 }
        if isAM && hour == 12 { hour = 0 }

        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return (hour, minute)
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError    = true
    }

    private func clearForm() {
        medicationName = ""; notes = ""
        times = []; newTimeDate = Date()
        showError = false
    }
}

#Preview {
    AddMedicationView()
}
