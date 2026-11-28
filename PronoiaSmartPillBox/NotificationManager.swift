//
//  NotificationManager.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

// NotificationManager.swift
import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            print("🔔 [Notifications] Permission granted: \(granted), error: \(String(describing: error))")
        }
    }

    // MARK: - Medication Reminders

    func scheduleMedicationNotifications(medName: String, times: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: times.map { "\(medName)_\($0)" }
        )

        for time in times {
            guard let components = timeToDateComponents(timeString: time) else { continue }

            let content       = UNMutableNotificationContent()
            content.title     = "Medication Reminder"
            content.body      = "Time to take \(medName)"
            content.sound     = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(medName)_\(time)",
                content:    content,
                trigger:    trigger
            )
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    // MARK: - Real-time Alert Notifications

    func sendAlertNotification(title: String, body: String, alertID: String) {
        let content       = UNMutableNotificationContent()
        content.title     = title
        content.body      = body
        content.sound     = .defaultCritical
        content.badge     = 1

        let request = UNNotificationRequest(
            identifier: "alert_\(alertID)",
            content:    content,
            trigger:    nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [Notifications] Failed to deliver alert notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private Helpers

    private func timeToDateComponents(timeString: String) -> DateComponents? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        guard let date = formatter.date(from: timeString) else { return nil }
        return Calendar.current.dateComponents([.hour, .minute], from: date)
    }
}
