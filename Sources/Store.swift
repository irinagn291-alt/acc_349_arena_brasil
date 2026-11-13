import SwiftUI
import UserNotifications

struct Preferences: Codable, Equatable {
    var clubs: Set<String> = []
    var competitions: Set<String> = []
    var matches: Set<String> = []
    var reminders: Set<String> = []
}
@MainActor final class FootballStore: ObservableObject {
    let catalogue = Demo.catalogue
    @Published var preferences: Preferences { didSet { persist() } }
    @Published var notice: String?
    #if DEBUG && targetEnvironment(simulator)
    private let defaults: UserDefaults?
    private var isScreenshotStore = false
    init(screenshotPreferences: Preferences) {
        defaults = nil
        preferences = screenshotPreferences
        isScreenshotStore = true
    }
    #else
    private let defaults: UserDefaults
    #endif
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preferences = defaults.data(forKey: "arena.preferences").flatMap { try? JSONDecoder().decode(Preferences.self, from: $0) } ?? Preferences()
        publishWidget()
    }
    func persist() {
        #if DEBUG && targetEnvironment(simulator)
        if isScreenshotStore { return }
        guard let defaults else { return }
        #endif
        do { defaults.set(try JSONEncoder().encode(preferences), forKey: "arena.preferences"); publishWidget() }
        catch { self.notice = "Your changes could not be saved. Please try again." }
    }
    func toggleClub(_ id: String) { if preferences.clubs.contains(id) { preferences.clubs.remove(id) } else { preferences.clubs.insert(id) } }
    func toggleCompetition(_ id: String) { if preferences.competitions.contains(id) { preferences.competitions.remove(id) } else { preferences.competitions.insert(id) } }
    func toggleMatch(_ id: String) { if preferences.matches.contains(id) { preferences.matches.remove(id) } else { preferences.matches.insert(id) } }
    func remind(_ fixture: Fixture) async {
        #if DEBUG && targetEnvironment(simulator)
        if isScreenshotStore { return }
        #endif
        let centre = UNUserNotificationCenter.current()
        if preferences.reminders.contains(fixture.id) {
            centre.removePendingNotificationRequests(withIdentifiers: [fixture.id]); preferences.reminders.remove(fixture.id)
            notice = "Reminder cancelled."; return
        }
        do {
            guard try await centre.requestAuthorization(options: [.alert, .sound]) else {
                notice = "Notifications are disabled. You can enable Arena Brasil notifications in Settings."; return
            }
            let content = UNMutableNotificationContent()
            content.title = "Arena Brasil · demo reminder"
            content.body = "\(catalogue.club(fixture.home).name) v \(catalogue.club(fixture.away).name). Explore the sample match centre."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            try await centre.add(UNNotificationRequest(identifier: fixture.id, content: content, trigger: trigger))
            preferences.reminders.insert(fixture.id)
            notice = "Demo reminder set for one minute from now. Sample fixtures do not represent a real schedule."
        } catch { notice = "The reminder could not be scheduled. Please try again." }
    }
    func reconcileReminders() async {
        #if DEBUG && targetEnvironment(simulator)
        if isScreenshotStore { return }
        #endif
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        preferences.reminders.formIntersection(Set(pending.map(\.identifier)))
    }
}
