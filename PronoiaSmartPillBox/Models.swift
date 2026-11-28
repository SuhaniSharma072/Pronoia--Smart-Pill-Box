//
//  Models.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

// models.swift
import Foundation

// MARK: - AppUser

struct AppUser: Codable, Identifiable, Equatable {
    var id:               String
    var name:             String
    var email:            String
    var role:             String
    var caretakerEmail:   String
    var caretakerPhone:   String
    var caretakerName:    String
    var phone:            String
    var bloodType:        String
    var allergies:        String
    var conditions:       String
    var emergencyContact: String

    var isOlderAdult: Bool { role == "older_adult" }
    var isCaretaker:  Bool { role == "caretaker"   }
}

// MARK: - Medication

struct Medication: Identifiable, Codable, Equatable {
    var id:           String
    var name:         String
    var dosage:       String
    var frequency:    String
    var times:        [String]
    var durationDays: Int
    var pillCount:    Int
    var refillAt:     Int
    var notes:        String
    var taken:        Bool
    var asNeeded:     Bool
    var expiryDate:   Date?
    var createdAt:    Date?

    var dose:         String { dosage }
    var nextTime:     String { times.first ?? "" }
    var isLowOnPills: Bool   { false }
}

// MARK: - Appointment

struct Appointment: Codable, Identifiable, Equatable {
    var id:     String
    var doctor: String
    var type:   String
    var date:   Date
    var time:   String
    var notes:  String
}

// MARK: - SymptomLog

struct SymptomLog: Codable, Identifiable {
    var id:        String
    var symptom:   String
    var severity:  Int
    var date:      Date
    var notes:     String
    var linkedMed: String
}

// MARK: - AppAlert

struct AppAlert: Codable, Identifiable {
    var id:        String
    var message:   String
    var timestamp: Date
    var elderID:   String
    var elderName: String
    var type:      String
    var isRead:    Bool
}

// MARK: - DoctorContact

struct DoctorContact: Codable, Identifiable {
    var id:        String
    var name:      String
    var specialty: String
    var phone:     String
    var address:   String
    var notes:     String
}

// MARK: - HealthReport

struct HealthReport: Codable, Identifiable {
    var id:             String
    var month:          String
    var adherenceScore: Double
    var symptomSummary: [String: Int]
    var totalMeds:      Int
    var takenMeds:      Int
    var missedMeds:     Int
    var totalAppts:     Int
}

// MARK: - AlertType

enum AlertType: String {
    case missedMed   = "missed_med"
    case refill      = "refill"
    case appointment = "appointment"
    case sos         = "sos"

    var icon: String {
        switch self {
        case .missedMed:   return "💊"
        case .refill:      return "⚠️"
        case .appointment: return "📅"
        case .sos:         return "🆘"
        }
    }
}

// MARK: - UserRole

enum UserRole: String {
    case olderAdult = "older_adult"
    case caretaker  = "caretaker"
}
