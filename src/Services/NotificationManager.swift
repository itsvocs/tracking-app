//
//  NotificationManager.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import Foundation
import UserNotifications
import Combine
/// Manager für lokale Benachrichtigungen
class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Authorization
    
    /// Fordert Berechtigung für Benachrichtigungen an
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            return granted
        } catch {
            throw NotificationError.authorizationFailed
        }
    }
    
    /// Prüft ob Benachrichtigungen erlaubt sind
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Schedule Notifications
    
    /// Plant eine tägliche Erinnerung zur angegebenen Zeit
    /// - Parameters:
    ///   - hour: Stunde (0-23)
    ///   - minute: Minute (0-59)
    func scheduleDailyReminder(hour: Int, minute: Int) {
        // Vorherige Benachrichtigungen entfernen
        removeDailyReminder()
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "Wie fühlst du dich heute?"
        content.body = "Nimm dir einen Moment Zeit und protokolliere deinen Tag."
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.dailyReminder,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Fehler beim Planen der Benachrichtigung: \(error.localizedDescription)")
            }
        }
    }
    
    /// Entfernt die tägliche Erinnerung
    func removeDailyReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.dailyReminder]
        )
    }
    
    /// Plant eine einmalige Benachrichtigung
    /// - Parameters:
    ///   - title: Titel der Benachrichtigung
    ///   - body: Text der Benachrichtigung
    ///   - date: Datum und Uhrzeit
    ///   - identifier: Eindeutige ID
    func scheduleNotification(title: String, body: String, at date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Fehler beim Planen der Benachrichtigung: \(error.localizedDescription)")
            }
        }
    }
    
    /// Entfernt alle ausstehenden Benachrichtigungen
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Entfernt alle zugestellten Benachrichtigungen
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    /// Holt alle ausstehenden Benachrichtigungen
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - Constants

struct NotificationIdentifier {
    static let dailyReminder = "daily_mood_reminder"
    static let weeklyReport = "weekly_report"
}

// MARK: - Error Handling

enum NotificationError: LocalizedError {
    case authorizationFailed
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed:
            return "Berechtigung für Benachrichtigungen wurde nicht erteilt"
        case .schedulingFailed:
            return "Benachrichtigung konnte nicht geplant werden"
        }
    }
}
