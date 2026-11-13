import Foundation

extension FootballStore {
    var widgetSnapshot: WidgetSnapshot {
        let match = catalogue.fixtures.first { preferences.matches.contains($0.id) } ?? catalogue.fixtures.first { $0.id == "featured" }
        let description = match.map { "\(catalogue.club($0.home).short)  \($0.score)  \(catalogue.club($0.away).short)" } ?? "Explore the sample catalogue"
        return WidgetSnapshot(title: "Your football", value: "\(preferences.clubs.count)", label: preferences.clubs.count == 1 ? "team followed" : "teams followed",
            detail: description, footnote: "Offline sample · not live scores", progress: min(1,Double(preferences.clubs.count)/Double(max(1,catalogue.clubs.count))))
    }
    func publishWidget() { WidgetStore.publish(widgetSnapshot) }
}

#if DEBUG && targetEnvironment(simulator)
extension FootballStore {
    /// Only explicit UI-test launches in disposable simulators can mutate this fixture.
    func applyWidgetQA(_ url: URL) {
        guard ProcessInfo.processInfo.arguments.contains("-WidgetQA"),
              URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "qa" && ["1", "2"].contains($0.value ?? "") }) == true else { return }
        let secondUpdate = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "qa" && $0.value == "2" }) == true
        let club = secondUpdate ? "pal" : "fla"
        if !preferences.clubs.contains(club) { toggleClub(club) }
        if !preferences.matches.contains("featured") { toggleMatch("featured") }
    }
}
#endif
