//
//  AppointmentsView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


import SwiftUI

struct AppointmentsView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @State private var showAddAppt  = false
    @State private var selectedDate = Date()

    var upcomingAppts: [Appointment] { firebase.appointments.filter { $0.date >= Date() } }
    var pastAppts:     [Appointment] { firebase.appointments.filter { $0.date <  Date() } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {

                    ZStack(alignment: .bottomLeading) {
                        LinearGradient.mintHeader
                            .frame(height: 160)
                            .ignoresSafeArea()

                        VStack(alignment: .leading, spacing: 4) {
                         
                            Text("Appointments")
                                .font(.appTitle(AppFont.displayMedium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 24)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            WeekStripView(selectedDate: $selectedDate)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming")
                                    .sectionTitle()
                                    .padding(.horizontal, 20)

                                if upcomingAppts.isEmpty {
                                    VStack(spacing: 12) {
                                        Text("📅").font(.system(size: 40))
                                        Text("No upcoming appointments")
                                            .font(.appBodyBold(AppFont.bodyMedium))
                                            .foregroundColor(.darkText)
                                        Text("Tap + to add one")
                                            .font(.appBody(AppFont.bodySmall))
                                            .foregroundColor(.grayText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(30)
                                    .background(Color.white)
                                    .cornerRadius(18)
                                    .padding(.horizontal, 20)
                                } else {
                                    ForEach(upcomingAppts) { appt in
                                        AppointmentCard(appointment: appt)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }

                        

                            Spacer().frame(height: 100)
                        }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { showAddAppt = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.mintDark)
                                .clipShape(Circle())
                                .shadow(color: Color.mintDark.opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddAppt) { AddAppointmentView() }
        }
    }
}

// MARK: - Week Strip

struct WeekStripView: View {
    @Binding var selectedDate: Date

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today    = Date()
        let weekday  = calendar.component(.weekday, from: today)
        let monday   = calendar.date(byAdding: .day, value: -(weekday - 2), to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let isToday    = Calendar.current.isDateInToday(date)

                Button { selectedDate = date } label: {
                    VStack(spacing: 6) {
                        Text(dayLetter(from: date))
                            .font(.appCaption(AppFont.tiny))
                            .foregroundColor(isSelected ? .white : .grayText)
                        Text(dayNumber(from: date))
                            .font(.appBodyBold(AppFont.bodyMedium))
                            .foregroundColor(isSelected ? .white : .darkText)
                        Circle()
                            .fill(isSelected ? Color.white : Color.mintDark)
                            .frame(width: 6, height: 6)
                            .opacity(isToday ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.mintDark : Color.white)
                    .cornerRadius(14)
                    .shadow(
                        color: isSelected ? Color.mintDark.opacity(0.3) : .shadowColor,
                        radius: 4, x: 0, y: 2
                    )
                }
            }
        }
    }

    private func dayLetter(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "E"
        return String(f.string(from: date).prefix(1))
    }
    private func dayNumber(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }
}

// MARK: - Appointment Card

struct AppointmentCard: View {
    let appointment: Appointment
    var isPast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#FFF5F3"))
                        .frame(width: 52, height: 52)
                    Text("+")
                        .font(.appBodyBold(AppFont.titleLarge))
                        .foregroundColor(.coral)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.type)
                        .font(.appBodyBold(AppFont.bodyMedium))
                        .foregroundColor(isPast ? .grayText : .darkText)
                    Text(appointment.doctor)
                        .font(.appCaption())
                        .foregroundColor(.grayText)

                    HStack(spacing: 8) {
                        AmberBadge(text: appointment.date.formatted(date: .abbreviated, time: .omitted))
                        AmberBadge(text: appointment.time)
                        if isPast {
                            Text("Past")
                                .font(.appCaption(AppFont.tiny))
                                .foregroundColor(.grayText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.lightGray)
                                .cornerRadius(99)
                        }
                    }
                }
                Spacer()
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
        .opacity(isPast ? 0.7 : 1)
    }
}

// MARK: - Add Appointment View

struct AddAppointmentView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var doctor    = ""
    @State private var type      = ""
    @State private var date      = Date()
    @State private var time      = ""
    @State private var notes     = ""
    @State private var isSaving  = false
    @State private var showError = false
    @State private var errorMsg  = ""

    let apptTypes = [
        "General Checkup", "Heart Check", "Eye Exam",
        "Blood Test", "Dental", "Physical Therapy", "Follow-up", "Other"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        AppTextField(label: "Doctor Name", placeholder: "e.g. Dr. Patel", icon: "stethoscope", text: $doctor)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Appointment Type")
                                .font(.appBodyBold(AppFont.bodySmall))
                                .foregroundColor(.darkText)

                            Menu {
                                ForEach(apptTypes, id: \.self) { t in Button(t) { type = t } }
                            } label: {
                                HStack {
                                    Image(systemName: "cross.case.fill").foregroundColor(.grayText)
                                    Text(type.isEmpty ? "Select type" : type)
                                        .font(.appBody(AppFont.bodyMedium))
                                        .foregroundColor(type.isEmpty ? .grayText : .darkText)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundColor(.grayText)
                                }
                                .padding(16)
                                .frame(height: 54)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lightGray, lineWidth: 1))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.appBodyBold(AppFont.bodySmall))
                                .foregroundColor(.darkText)

                            DatePicker("", selection: $date, in: Date()..., displayedComponents: .date)
                                .labelsHidden()
                                .tint(.mintDark)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lightGray, lineWidth: 1))
                        }

                        AppTextField(label: "Time", placeholder: "e.g. 10:30 AM", icon: "clock.fill", text: $time)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (optional)")
                                .font(.appBodyBold(AppFont.bodySmall))
                                .foregroundColor(.darkText)

                            TextField("e.g. Bring insurance card", text: $notes, axis: .vertical)
                                .font(.appBody(AppFont.bodyMedium))
                                .lineLimit(3...6)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lightGray, lineWidth: 1))
                        }

                        if showError {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(errorMsg).font(.appBody(AppFont.bodySmall))
                            }
                            .foregroundColor(.coralDark)
                            .padding(14)
                            .background(Color(hex: "#FFE8E4"))
                            .cornerRadius(12)
                        }

                        Button { saveAppointment() } label: {
                            ZStack {
                                if isSaving {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    HStack {
                                        Image(systemName: "calendar.badge.plus")
                                        Text("Save Appointment").font(.appButton(AppFont.bodyLarge))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(Color.mintDark)
                            .cornerRadius(16)
                        }
                        .disabled(isSaving)

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.mintDark)
                }
            }
        }
    }

    private func saveAppointment() {
        guard !doctor.isEmpty else { errorMsg = "Please enter doctor name";        showError = true; return }
        guard !type.isEmpty   else { errorMsg = "Please select appointment type";  showError = true; return }
        guard let userID = firebase.currentUser?.id else { return }

        isSaving = true
        let appt = Appointment(id: UUID().uuidString, doctor: doctor, type: type, date: date, time: time, notes: notes)

        firebase.addAppointment(userID: userID, appointment: appt) { success in
            isSaving = false
            if success { dismiss() }
        }
    }
}

#Preview {
    AppointmentsView()
}
