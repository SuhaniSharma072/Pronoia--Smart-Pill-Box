//// FirebaseManager.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
import Combine

final class FirebaseManager: ObservableObject {

    static let shared = FirebaseManager()

    @Published var isLoggedIn:        Bool          = false
    @Published var currentUser:       AppUser?      = nil
    @Published var medications:       [Medication]  = []
    @Published var appointments:      [Appointment] = []
    @Published var alerts:            [AppAlert]    = []
    @Published var linkedElder:       AppUser?      = nil
    @Published var adherenceProgress: Double        = 0.0
    @Published var takenCount:        Int           = 0
    @Published var nextMedDue:        Medication?   = nil
    @Published var unreadAlertCount:  Int           = 0

    // MARK: - Pill box (Realtime Database)
    @Published var pillBoxLidStatus:   String  = "unknown"   // "open" / "closed" / "unknown"
    @Published var pillBoxLastUpdated: Date?   = nil
    @Published var reminderHour1:      Int     = 22
    @Published var reminderMinute1:    Int     = 0
    @Published var reminderHour2:      Int     = 22
    @Published var reminderMinute2:    Int     = 0
    @Published var remoteTriggerBusy:  Bool    = false        // true while a "buzz now" is in flight
    @Published var profileFetchFailed: Bool    = false        // true if sign-in succeeded but the user's Firestore doc couldn't be loaded

    let db   = Firestore.firestore()
    let auth = Auth.auth()
    let rtdb = Database.database().reference()               // points at the RTDB root

    private var authListener:        AuthStateDidChangeListenerHandle?
    private var alertsListener:      ListenerRegistration?
    private var appointmentListener: ListenerRegistration?
    private var midnightTimer:       Timer?
    private var lidStatusHandle:     DatabaseHandle?
    private var reminderHandle:      DatabaseHandle?

    private init() {
        authListener = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = (user != nil)
                if let uid = user?.uid {
                    self?.fetchUserProfile(userID: uid)
                    self?.startPillBoxListeners()
                } else {
                    self?.clearSession()
                }
            }
        }
    }

    private func clearSession() {
        alertsListener?.remove()
        alertsListener = nil
        appointmentListener?.remove()
        appointmentListener = nil
        midnightTimer?.invalidate()
        midnightTimer = nil
        stopPillBoxListeners()

        currentUser      = nil
        medications      = []
        appointments     = []
        alerts           = []
        linkedElder      = nil

        adherenceProgress = 0
        takenCount        = 0
        nextMedDue        = nil
        unreadAlertCount  = 0
    }

    // MARK: - AUTH

    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        auth.signIn(withEmail: email, password: password) { _, error in
            DispatchQueue.main.async {
                completion(error == nil, error?.localizedDescription)
            }
        }
    }

    func signUp(
        name: String,
        email: String,
        password: String,
        phone: String,
        role: String,
        caretakerName: String,
        caretakerEmail: String,
        caretakerPhone: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
                return
            }
            guard let uid = result?.user.uid, let self = self else { return }

            let normalisedCaretakerEmail = caretakerEmail
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let data: [String: Any] = [
                "id":               uid,
                "name":             name,
                "email":            email.lowercased(),
                "role":             role,
                "phone":            phone,
                "caretakerName":    caretakerName,
                "caretakerEmail":   normalisedCaretakerEmail,
                "caretakerPhone":   caretakerPhone,
                "bloodType":        "",
                "allergies":        "",
                "conditions":       "",
                "emergencyContact": ""
            ]

            self.db.collection("users").document(uid).setData(data) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        self.fetchUserProfile(userID: uid)
                        completion(true, nil)
                    }
                }
            }
        }
    }

    func signOut() {
        try? auth.signOut()
        DispatchQueue.main.async { self.clearSession() }
    }

    // MARK: - USER PROFILE

    func fetchUserProfile(userID: String) {
        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ fetchUserProfile failed with error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.profileFetchFailed = true }
                return
            }

            guard let data = snapshot?.data() else {
                print("❌ fetchUserProfile: no document found in Firestore for uid \(userID). The user is authenticated but has no matching /users/\(userID) document.")
                DispatchQueue.main.async { self.profileFetchFailed = true }
                return
            }

            let user = self.makeAppUser(id: userID, data: data)

            DispatchQueue.main.async {
                self.currentUser = user

                if user.isOlderAdult {
                    self.checkAndResetDailyMedications(userID: userID) {
                        self.fetchMedications { meds in
                            DispatchQueue.main.async {
                                self.medications = meds
                                self.recalculateAdherence()
                            }
                        }
                    }
                    self.scheduleMidnightReset(userID: userID)
                    self.listenToAppointments(userID: userID)
                    self.fetchAlerts(userID: userID)

                } else if user.isCaretaker {
                    self.fetchMedications { meds in
                        DispatchQueue.main.async {
                            self.medications = meds
                            self.recalculateAdherence()
                        }
                    }
                    self.fetchAlertsForCaretaker(caretakerEmail: user.email)
                    self.fetchLinkedElder(caretakerEmail: user.email) { elder, _ in
                        DispatchQueue.main.async {
                            self.linkedElder = elder
                            if let elderID = elder?.id {
                                self.listenToAppointments(userID: elderID)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - APPOINTMENTS

    func listenToAppointments(userID: String) {
        appointmentListener?.remove()

        appointmentListener = db.collection("users").document(userID)
            .collection("appointments")
            .order(by: "date")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ [Appointments] Listener error: \(error.localizedDescription)")
                    return
                }
                let appts: [Appointment] = snapshot?.documents.compactMap { doc in
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

                DispatchQueue.main.async {
                    self?.appointments = appts
                    print("📅 [Appointments] Updated — \(appts.count) total")
                }
            }
    }

    func fetchAppointments(userID: String) {
        db.collection("users").document(userID)
            .collection("appointments")
            .order(by: "date")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ [Appointments] Fetch error: \(error.localizedDescription)")
                    return
                }
                let appts: [Appointment] = snapshot?.documents.compactMap { doc in
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
                DispatchQueue.main.async {
                    self?.appointments = appts
                }
            }
    }

    func addAppointment(userID: String, appointment: Appointment,
                        completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "doctor": appointment.doctor,
            "type":   appointment.type,
            "date":   Timestamp(date: appointment.date),
            "time":   appointment.time,
            "notes":  appointment.notes
        ]
        db.collection("users").document(userID)
            .collection("appointments")
            .document(appointment.id)
            .setData(data) { error in
                DispatchQueue.main.async {
                    completion(error == nil)
                }
            }
    }

    // MARK: - DAILY MEDICATION RESET

    func checkAndResetDailyMedications(userID: String, completion: @escaping () -> Void) {
        let defaults     = UserDefaults.standard
        let resetKey     = "lastMedResetDate_\(userID)"
        let streakKey    = "plantStreakDays_\(userID)"
        let today        = Calendar.current.startOfDay(for: Date())
        let formatter    = ISO8601DateFormatter()
        let todayStr     = formatter.string(from: today)
        let lastResetStr = defaults.string(forKey: resetKey) ?? ""

        guard lastResetStr != todayStr else { completion(); return }

        fetchMedications { [weak self] meds in
            guard let self = self else { return }

            let scheduled = meds.filter { !$0.asNeeded }
            let allTaken  = !scheduled.isEmpty && scheduled.allSatisfy { $0.taken }
            let current   = defaults.integer(forKey: streakKey)

            if allTaken {
                defaults.set(min(current + 1, 7), forKey: streakKey)
            } else if !scheduled.isEmpty {
                defaults.set(0, forKey: streakKey)
            }

            defaults.set(todayStr, forKey: resetKey)
            self.resetAllMedicationsTaken(userID: userID) { completion() }
        }
    }

    private func resetAllMedicationsTaken(userID: String, completion: @escaping () -> Void) {
        let medsRef = db.collection("users").document(userID).collection("medications")
        medsRef.getDocuments { [weak self] snapshot, error in
            guard let self = self, let docs = snapshot?.documents, error == nil else {
                completion(); return
            }
            guard !docs.isEmpty else { completion(); return }

            let batch = self.db.batch()
            for doc in docs {
                batch.updateData(["taken": false], forDocument: doc.reference)
            }
            batch.commit { _ in
                DispatchQueue.main.async { completion() }
            }
        }
    }

    private func scheduleMidnightReset(userID: String) {
        midnightTimer?.invalidate()
        let calendar = Calendar.current
        let now      = Date()
        guard let tomorrow = calendar.date(
            byAdding: .day, value: 1, to: calendar.startOfDay(for: now)
        ) else { return }

        let interval = tomorrow.addingTimeInterval(5).timeIntervalSince(now)
        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.checkAndResetDailyMedications(userID: userID) {
                self.fetchMedications { meds in
                    DispatchQueue.main.async {
                        self.medications = meds
                        self.recalculateAdherence()
                        self.scheduleMidnightReset(userID: userID)
                    }
                }
            }
        }
    }

    // MARK: - ADHERENCE

    private func recalculateAdherence() {
        let scheduledMeds = medications.filter { !$0.asNeeded }
        let total = scheduledMeds.count
        guard total > 0 else {
            adherenceProgress = 0; takenCount = 0; nextMedDue = nil; return
        }
        let taken         = scheduledMeds.filter { $0.taken }.count
        takenCount        = taken
        adherenceProgress = Double(taken) / Double(total)
        nextMedDue        = scheduledMeds.first { !$0.taken }
    }

    // MARK: - MEDICATIONS

    func saveMedication(
        name: String, dosage: String, frequency: String, times: [String],
        durationDays: Int, pillCount: Int, refillAt: Int, notes: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard let userID = auth.currentUser?.uid else {
            completion(false, "No user logged in"); return
        }
        let expiryDate = Calendar.current.date(byAdding: .day, value: durationDays, to: Date())
        let data: [String: Any] = [
            "name":         name,
            "dosage":       dosage,
            "frequency":    frequency,
            "times":        times,
            "durationDays": durationDays,
            "pillCount":    pillCount,
            "refillAt":     refillAt,
            "notes":        notes,
            "expiryDate":   expiryDate ?? Date(),
            "taken":        false,
            "asNeeded":     false,
            "createdAt":    Timestamp()
        ]
        db.collection("users").document(userID).collection("medications")
            .addDocument(data: data) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        self?.fetchMedications { meds in
                            DispatchQueue.main.async {
                                self?.medications = meds
                                self?.recalculateAdherence()
                            }
                        }
                        completion(true, nil)
                    }
                }
            }
    }

    func fetchMedications(completion: @escaping ([Medication]) -> Void) {
        guard let userID = auth.currentUser?.uid else { completion([]); return }
        db.collection("users").document(userID).collection("medications")
            .getDocuments { snapshot, _ in
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
                completion(meds)
            }
    }

    func markMedicationTaken(userID: String, medID: String, taken: Bool,
                             completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("medications")
            .document(medID).updateData(["taken": taken]) { [weak self] error in
                DispatchQueue.main.async {
                    completion(error == nil)
                    if error == nil {
                        self?.fetchMedications { meds in
                            DispatchQueue.main.async {
                                self?.medications = meds
                                self?.recalculateAdherence()
                            }
                        }
                    }
                }
            }
    }

    func updatePillCount(userID: String, medID: String, newCount: Int,
                         completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userID).collection("medications")
            .document(medID).updateData(["pillCount": newCount]) { [weak self] error in
                DispatchQueue.main.async {
                    completion(error == nil)
                    if error == nil {
                        self?.fetchMedications { meds in
                            DispatchQueue.main.async {
                                self?.medications = meds
                                self?.recalculateAdherence()
                            }
                        }
                    }
                }
            }
    }

    // MARK: - ALERTS

    func fetchAlerts(userID: String) {
        alertsListener?.remove()
        alertsListener = db.collection("alerts")
            .whereField("elderID", isEqualTo: userID)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ [Alerts] \(error.localizedDescription)"); return
                }
                self?.handleAlertSnapshot(snapshot)
            }
    }

    func fetchAlertsForCaretaker(caretakerEmail: String) {
        alertsListener?.remove()
        let email = caretakerEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        alertsListener = db.collection("alerts")
            .whereField("caretakerEmail", isEqualTo: email)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ [Alerts] \(error.localizedDescription)"); return
                }
                self?.handleAlertSnapshot(snapshot)
            }
    }

    private func handleAlertSnapshot(_ snapshot: QuerySnapshot?) {
        let newAlerts: [AppAlert] = (snapshot?.documents ?? []).compactMap { doc in
            let d = doc.data()
            return AppAlert(
                id:        doc.documentID,
                message:   d["message"]    as? String ?? "",
                timestamp: (d["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                elderID:   d["elderID"]    as? String ?? "",
                elderName: d["elderName"]  as? String ?? "",
                type:      d["type"]       as? String ?? "",
                isRead:    d["isRead"]     as? Bool   ?? false
            )
        }
        let sorted = newAlerts.sorted { $0.timestamp > $1.timestamp }
        DispatchQueue.main.async {
            let existingIDs = Set(self.alerts.map { $0.id })
            let brandNew    = sorted.filter { !existingIDs.contains($0.id) && !$0.isRead }
            self.alerts           = sorted
            self.unreadAlertCount = sorted.filter { !$0.isRead }.count
            for alert in brandNew {
                NotificationManager.shared.sendAlertNotification(
                    title: self.alertTitle(for: alert.type),
                    body:  alert.message,
                    alertID: alert.id
                )
            }
        }
    }

    private func alertTitle(for type: String) -> String {
        switch type {
        case "sos":         return "🆘 Emergency Alert"
        case "ride":        return "🚗 Ride Request"
        case "refill":      return "⚠️ Refill Needed"
        case "missed_med":  return "💊 Missed Medication"
        case "appointment": return "📅 New Appointment"
        default:            return "🔔 New Alert"
        }
    }

    func sendAlert(caretakerEmail: String, elderID: String, elderName: String,
                   message: String, type: String, completion: @escaping (Bool) -> Void) {
        let email = caretakerEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let data: [String: Any] = [
            "caretakerEmail": email,
            "elderID":        elderID,
            "elderName":      elderName,
            "message":        message,
            "type":           type,
            "isRead":         false,
            "timestamp":      Timestamp()
        ]
        db.collection("alerts").addDocument(data: data) { error in
            DispatchQueue.main.async { completion(error == nil) }
        }
    }

    func markAlertRead(alertID: String) {
        db.collection("alerts").document(alertID).updateData(["isRead": true]) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let idx = self.alerts.firstIndex(where: { $0.id == alertID }) {
                    self.alerts[idx].isRead = true
                    self.unreadAlertCount   = self.alerts.filter { !$0.isRead }.count
                }
            }
        }
    }

    func deleteAlert(alertID: String) {
        db.collection("alerts").document(alertID).delete()
    }

    // MARK: - LINKED ELDER

    func fetchLinkedElder(caretakerEmail: String,
                          completion: @escaping (AppUser?, Error?) -> Void) {
        let email = caretakerEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        db.collection("users")
            .whereField("caretakerEmail", isEqualTo: email)
            .whereField("role", isEqualTo: "older_adult")
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let doc = snapshot?.documents.first else {
                    completion(nil, error); return
                }
                completion(self.makeAppUser(id: doc.documentID, data: doc.data()), nil)
            }
    }

    // MARK: - HELPERS

    private func makeAppUser(id: String, data: [String: Any]) -> AppUser {
        AppUser(
            id:               id,
            name:             data["name"]             as? String ?? "",
            email:            data["email"]            as? String ?? "",
            role:             data["role"]             as? String ?? "",
            caretakerEmail:   data["caretakerEmail"]   as? String ?? "",
            caretakerPhone:   data["caretakerPhone"]   as? String ?? "",
            caretakerName:    data["caretakerName"]    as? String ?? "",
            phone:            data["phone"]            as? String ?? "",
            bloodType:        data["bloodType"]        as? String ?? "",
            allergies:        data["allergies"]        as? String ?? "",
            conditions:       data["conditions"]       as? String ?? "",
            emergencyContact: data["emergencyContact"] as? String ?? ""
        )
    }

    // MARK: - PILL BOX (Realtime Database)
    // The ESP32 writes plain string/number values here — no auth or Firestore
    // structure, just simple key paths matching what the firmware expects.

    /// Starts listening for lid status + reminder schedule changes. Safe to call
    /// multiple times — clears any existing observers first.
    func startPillBoxListeners() {
        stopPillBoxListeners()

        // Lid status — ESP32 writes "open" / "closed" to /lidStatus
        lidStatusHandle = rtdb.child("lidStatus").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            let status = snapshot.value as? String ?? "unknown"
            DispatchQueue.main.async {
                self.pillBoxLidStatus   = status
                self.pillBoxLastUpdated = Date()
            }
        }

        // Reminder schedule — app can write here; ESP32 reads it each cycle.
        reminderHandle = rtdb.child("reminders").observe(.value) { [weak self] snapshot in
            guard let self = self, let d = snapshot.value as? [String: Any] else { return }
            DispatchQueue.main.async {
                self.reminderHour1   = d["hour1"]   as? Int ?? self.reminderHour1
                self.reminderMinute1 = d["minute1"] as? Int ?? self.reminderMinute1
                self.reminderHour2   = d["hour2"]   as? Int ?? self.reminderHour2
                self.reminderMinute2 = d["minute2"] as? Int ?? self.reminderMinute2
            }
        }
    }

    func stopPillBoxListeners() {
        if let handle = lidStatusHandle {
            rtdb.child("lidStatus").removeObserver(withHandle: handle)
            lidStatusHandle = nil
        }
        if let handle = reminderHandle {
            rtdb.child("reminders").removeObserver(withHandle: handle)
            reminderHandle = nil
        }
    }

    /// Caretaker sets new reminder times — writes to RTDB, ESP32 reads it next cycle.
    func updateReminderSchedule(hour1: Int, minute1: Int, hour2: Int, minute2: Int,
                                 completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "hour1":   hour1,
            "minute1": minute1,
            "hour2":   hour2,
            "minute2": minute2
        ]
        rtdb.child("reminders").setValue(data) { error, _ in
            DispatchQueue.main.async { completion(error == nil) }
        }
    }

    /// Caretaker triggers an immediate buzz. Writes true, then the ESP32 buzzes
    /// and flips it back to false — this listener clears the local "busy" flag.
    func triggerRemoteBuzz(completion: @escaping (Bool) -> Void) {
        remoteTriggerBusy = true
        rtdb.child("remoteTrigger").setValue(true) { [weak self] error, _ in
            DispatchQueue.main.async {
                completion(error == nil)
                if error != nil { self?.remoteTriggerBusy = false }
            }
        }
        // Watch for the ESP32 flipping it back to false and clear the busy flag.
        rtdb.child("remoteTrigger").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            let isTriggered = snapshot.value as? Bool ?? false
            DispatchQueue.main.async {
                if !isTriggered { self.remoteTriggerBusy = false }
            }
        }
    }
}
