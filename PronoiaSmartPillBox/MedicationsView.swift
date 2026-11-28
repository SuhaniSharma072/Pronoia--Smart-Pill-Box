//
//  MedicationsView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

// MedicationsView.swift
import SwiftUI
import FirebaseFirestore

struct MedicationsView: View {

    @StateObject private var firebase = FirebaseManager.shared
    @State private var showAddMed = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {

                    Text("My Medications")
                        .font(.appTitle(AppFont.displayMedium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.top, 14)
                        .padding(.bottom, 18)
                        .background(
                            LinearGradient.mintHeader.ignoresSafeArea(edges: .top)
                        )

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {

                            if firebase.medications.isEmpty {
                                VStack(spacing: 12) {
                                    Text("💊").font(.system(size: 40))
                                    Text("No medications yet")
                                        .font(.appBodyBold(AppFont.bodyMedium))
                                        .foregroundColor(.darkText)
                                    Text("Add your medications to stay on track")
                                        .font(.appBody(AppFont.bodySmall))
                                        .foregroundColor(.grayText)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(30)
                                .background(Color.white)
                                .cornerRadius(18)
                                .padding(.horizontal, 20)

                            } else {
                                ForEach(firebase.medications) { med in
                                    MedDetailCard(medication: med)
                                        .padding(.horizontal, 20)
                                }
                            }

                            Button {
                                showAddMed = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Medication")
                                        .font(.appButton(AppFont.bodyLarge))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.mintDark)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                            Spacer().frame(height: 100)
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddMed) {
                AddMedicationView()
            }
        }
    }
}

// MARK: - Med Detail Card

struct MedDetailCard: View {

    let medication: Medication
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mintLight)
                    .frame(width: 52, height: 52)
                Text("Rx")
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.mintDark)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(medication.name)
                    .font(.appBodyBold(AppFont.bodyMedium))
                    .foregroundColor(.darkText)

                if !medication.times.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(medication.times, id: \.self) { time in
                            Text(time)
                                .font(.appCaption(AppFont.tiny))
                                .foregroundColor(.mintDark)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.mintLight)
                                .cornerRadius(99)
                        }
                    }
                }
            }

            Spacer()

            Button { showEdit = true } label: {
                Text("Edit")
                    .font(.appBodyBold(AppFont.bodySmall))
                    .foregroundColor(.mintDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.mintLight)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .shadowColor, radius: 6, x: 0, y: 3)
        .sheet(isPresented: $showEdit) {
            EditMedicationView(medication: medication)
        }
    }
}

// MARK: - Edit Medication View

struct EditMedicationView: View {

    let medication: Medication

    @StateObject private var firebase = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name         : String
    @State private var notes        : String
    @State private var times        : [String]
    @State private var newTime      = ""
    @State private var isSaving     = false
    @State private var showError    = false
    @State private var errorMsg     = ""

    init(medication: Medication) {
        self.medication = medication
        _name           = State(initialValue: medication.name)
        _notes          = State(initialValue: medication.notes)
        _times          = State(initialValue: medication.times)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        AppTextField(label: "Medication Name",  placeholder: "e.g. Ibuprofen",   icon: "pills",                    text: $name)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Times to Take")
                                .font(.appBodyBold(AppFont.bodySmall))
                                .foregroundColor(.darkText)
                            HStack {
                                TextField("e.g. 8:00 AM", text: $newTime)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add") {
                                    let trimmed = newTime.trimmingCharacters(in: .whitespaces)
                                    if !trimmed.isEmpty { times.append(trimmed); newTime = "" }
                                }
                                .foregroundColor(.mintDark)
                            }
                            ForEach(times, id: \.self) { time in
                                HStack {
                                    Text(time).font(.appCaption()).foregroundColor(.mintDark)
                                    Spacer()
                                    Button { times.removeAll { $0 == time } } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.grayText)
                                    }
                                }
                                .padding(10).background(Color.mintLight).cornerRadius(10)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.appBodyBold(AppFont.bodySmall)).foregroundColor(.darkText)
                            HStack(alignment: .top) {
                                Image(systemName: "note.text").foregroundColor(.grayText)
                                TextField("Optional notes...", text: $notes, axis: .vertical)
                                    .lineLimit(3...6)
                            }
                            .padding(16).background(Color.white).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lightGray, lineWidth: 1))
                        }

                        if showError {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(errorMsg).font(.appBody(AppFont.bodySmall))
                            }
                            .foregroundColor(.coralDark).padding(14)
                            .background(Color(hex: "#FFE8E4")).cornerRadius(12)
                        }

                        Button { saveChanges() } label: {
                            ZStack {
                                if isSaving {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Save Changes").font(.appButton(AppFont.bodyLarge))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(Color.mintDark).cornerRadius(16)
                        }
                        .disabled(isSaving)

                        Button { deleteMedication() } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Medication").font(.appBodyBold(AppFont.bodyMedium))
                            }
                            .foregroundColor(.coralDark)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(Color(hex: "#FFE8E4")).cornerRadius(16)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 22).padding(.top, 20)
                }
            }
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.mintDark)
                }
            }
        }
    }

    private func saveChanges() {
        guard !name.isEmpty else { errorMsg = "Please enter medication name"; showError = true; return }
        guard let userID = firebase.currentUser?.id else { return }
        isSaving = true
        let data: [String: Any] = [
            "name": name, "times": times, "notes": notes
        ]
        firebase.db.collection("users").document(userID)
            .collection("medications").document(medication.id)
            .updateData(data) { error in
                DispatchQueue.main.async {
                    isSaving = false
                    if let error = error { errorMsg = error.localizedDescription; showError = true }
                    else {
                        firebase.fetchMedications { meds in
                            DispatchQueue.main.async { firebase.medications = meds; dismiss() }
                        }
                    }
                }
            }
    }

    private func deleteMedication() {
        guard let userID = firebase.currentUser?.id else { return }
        firebase.db.collection("users").document(userID)
            .collection("medications").document(medication.id)
            .delete { error in
                DispatchQueue.main.async {
                    if error == nil {
                        firebase.fetchMedications { meds in
                            DispatchQueue.main.async { firebase.medications = meds; dismiss() }
                        }
                    }
                }
            }
    }
}

#Preview {
    MedicationsView()
}
