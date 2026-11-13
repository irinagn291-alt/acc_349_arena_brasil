import SwiftUI

struct MatchDetail: View {
    @EnvironmentObject var store: FootballStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let match: Fixture
    @State private var section = "Events"
    @State private var showReminder = false
    init(match: Fixture) {
        self.match = match
        #if DEBUG && targetEnvironment(simulator)
        let key = ScreenshotLaunch.current?.key
        _section = State(initialValue: key == "statistics" ? "Statistics" : key == "head-to-head" ? "Head-to-head" : key == "comparison" ? "Form" : "Events")
        #endif
    }
    var home: Club { store.catalogue.club(match.home) }
    var away: Club { store.catalogue.club(match.away) }
    @ViewBuilder var body: some View {
        #if DEBUG && targetEnvironment(simulator)
        if ["match-centre", "comparison", "statistics", "head-to-head"].contains(ScreenshotLaunch.current?.key ?? "") {
            ScrollViewReader { proxy in
                GeometryReader { geometry in
                    matchPage.task {
                        if ["comparison", "statistics", "head-to-head"].contains(ScreenshotLaunch.current?.key ?? "") {
                            await Task.yield()
                            proxy.scrollTo("capture-match-details", anchor: .top)
                        } else if geometry.size.height < 750 {
                            await Task.yield()
                            proxy.scrollTo("capture-match-score", anchor: .top)
                        }
                    }
                }
            }
        } else {
            matchPage
        }
        #else
        matchPage
        #endif
    }
    var matchPage: some View {
        Page {
            VStack(spacing: 20) {
                Text(match.competition.uppercased() + " · ROUND \(match.round)").font(.caption.bold()).tracking(1)
                HStack(alignment: .center) {
                    teamLink(home); Spacer(minLength: 8)
                    VStack(spacing: 8) { Text(match.score).font(.system(size: 36, weight: .heavy, design: .rounded)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1); Text(match.status).font(.caption.bold()) }
                    Spacer(minLength: 8); teamLink(away)
                }
                #if DEBUG && targetEnvironment(simulator)
                .overlay(alignment: .top) {
                    if ScreenshotLaunch.current?.key == "match-centre" && match.id == "sample" {
                        Color.clear.frame(height: 1).id("capture-match-score")
                    }
                }
                #endif
                Text("\(match.day) November 2026 · \(match.time) BRT").font(.subheadline.weight(.semibold))
                Label(match.stadium, systemImage: "mappin.and.ellipse").font(.caption).multilineTextAlignment(.center)
                Text("DEMONSTRATION MATCH").font(.caption2.bold()).tracking(1).padding(8).background(.white.opacity(0.13), in: Capsule())
            }.padding(20).frame(maxWidth: .infinity).foregroundStyle(.white).background { ZStack { Color.arenaNavy; Stadium() } }.clipShape(RoundedRectangle(cornerRadius: 20))
            HStack(spacing: 8) {
                shortcut("Form", icon: "chart.bar.xaxis", destination: "Form")
                shortcut("Line-ups", icon: "person.3", destination: "Line-ups")
                shortcut("Head-to-head", icon: "arrow.left.arrow.right", destination: "Head-to-head")
            }
            HStack(spacing: 12) {
                Button { store.toggleMatch(match.id) } label: { Label(store.preferences.matches.contains(match.id) ? "Saved match" : "Save match", systemImage: store.preferences.matches.contains(match.id) ? "bookmark.fill" : "bookmark").frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered)
                Button { showReminder = true } label: { Image(systemName: store.preferences.reminders.contains(match.id) ? "bell.badge.fill" : "bell").frame(width: 44, height: 44) }.buttonStyle(.bordered).accessibilityLabel("Demo reminder")
            }
            Chips(values: ["Events", "Line-ups", "Statistics", "Head-to-head", "Form"], selection: $section).id("capture-match-details")
            Group {
                switch section {
                case "Line-ups": lineups
                case "Statistics": statistics
                case "Head-to-head": history
                case "Form": form
                default: events
                }
            }.id(section)
            SourceNote()
        }.navigationTitle("Match centre").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Demo reminder", isPresented: $showReminder, titleVisibility: .visible) {
                Button(store.preferences.reminders.contains(match.id) ? "Cancel reminder" : "Remind me in one minute") { Task { await store.remind(match) } }
                Button("Not now", role: .cancel) {}
            } message: { Text("This is a sample fixture. A local demo reminder is sent one minute from now, rather than at a real kick-off time.") }
    }
    func teamLink(_ club: Club) -> some View {
        NavigationLink(value: club) { VStack(spacing: 10) { Shield(club: club, size: 50); Text(club.name).font(.subheadline.bold()).multilineTextAlignment(.center).lineLimit(2) }.frame(maxWidth: .infinity) }.buttonStyle(.plain).accessibilityIdentifier("team-\(club.id)")
    }
    func shortcut(_ title: String, icon: String, destination: String) -> some View {
        Button { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { section = destination } } label: {
            VStack(spacing: 8) { Image(systemName: icon).font(.title3); Text(title).font(.caption.weight(.bold)).lineLimit(2).minimumScaleFactor(0.8) }.frame(maxWidth: .infinity, minHeight: 82).background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.arenaBlue.opacity(0.16)))
        }
    }
    var events: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Match timeline", subtitle: "Illustrative events")
            if match.homeGoals == nil { EmptyCard(title: "Waiting for kick-off", message: "The timeline will appear when events are available. Explore the team form and sample line-ups before the match.") }
            else {
                VStack(spacing: 0) {
                    eventRow("0′", "Kick-off", "The sample match begins", icon: "flag")
                    ForEach(goalEvents, id: \.minute) { event in
                        eventRow("\(event.minute)′", "Goal · \(event.club.name)", event.player, icon: "soccerball")
                    }
                    eventRow(match.finished ? "90′" : "\(match.minute ?? 0)′", match.finished ? "Full time" : "Sample paused", match.finished ? "Final score: \(match.score)" : "Frozen demonstration, not a live feed", icon: "clock")
                }.card()
            }
        }
    }
    var goalEvents: [(minute: Int, club: Club, player: String)] {
        let h = (0..<(match.homeGoals ?? 0)).map { (minute: 14 + $0 * 23, club: home, player: "\(home.short) · J. Pereira") }
        let a = (0..<(match.awayGoals ?? 0)).map { (minute: 21 + $0 * 22, club: away, player: "\(away.short) · V. Souza") }
        return (h + a).sorted { $0.minute < $1.minute }
    }
    func eventRow(_ minute: String, _ title: String, _ detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(minute).font(.subheadline.bold()).monospacedDigit().frame(width: 36)
            Image(systemName: icon).foregroundStyle(Color.arenaBlue).frame(width: 24)
            VStack(alignment: .leading, spacing: 5) { Text(title).font(.subheadline.bold()); Text(detail).font(.caption).foregroundStyle(Color.arenaMuted) }; Spacer()
        }.padding(.vertical, 14)
    }
    var lineups: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Sample line-ups", subtitle: "4–3–3")
            Text("Illustrative players, not official team selections.").font(.subheadline).foregroundStyle(Color.arenaMuted)
            HStack(alignment: .top, spacing: 12) { squadColumn(home); squadColumn(away) }
        }
    }
    func squadColumn(_ club: Club) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(club.name).font(.headline)
            ForEach(Demo.squad(club), id: \.0) { number, name, role in
                HStack(alignment: .top, spacing: 6) { Text(number.formatted(.number.locale(Locale(identifier: "en_GB")))).font(.caption.bold()).monospacedDigit().frame(width: 20); VStack(alignment: .leading, spacing: 3) { Text(name.replacingOccurrences(of: club.short + " · ", with: "")).font(.subheadline.weight(.medium)); Text(role).font(.caption2).foregroundStyle(Color.arenaMuted) } }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).card()
    }
    var statistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Match statistics")
            if match.homeGoals == nil { EmptyCard(title: "Statistics after kick-off", message: "No match statistics are available for this scheduled fixture. Open Form to compare recorded sample results.") }
            else {
                VStack(spacing: 24) {
                    HStack { Text(home.short); Spacer(); Text("DEMO").font(.caption); Spacer(); Text(away.short) }.font(.headline)
                    stat("Possession", 56, 44, suffix: "%")
                    stat("Shots", 13, 8)
                    stat("Shots on target", max(match.homeGoals ?? 0, 6), max(match.awayGoals ?? 0, 3))
                    stat("Corners", 5, 3)
                    stat("Fouls", 10, 12)
                    Text("Sample match metrics for demonstration only.").font(.caption).foregroundStyle(Color.arenaMuted)
                }.card()
            }
        }
    }
    func stat(_ label: String, _ a: Int, _ b: Int, suffix: String = "") -> some View {
        VStack(spacing: 8) {
            HStack { Text("\(a)\(suffix)").bold(); Spacer(); Text(label).font(.subheadline); Spacer(); Text("\(b)\(suffix)").bold() }.monospacedDigit()
            GeometryReader { g in HStack(spacing: 4) { Capsule().fill(Color.arenaBlue).frame(width: max(0, (g.size.width - 4) * CGFloat(a) / CGFloat(max(1, a+b)))); Capsule().fill(Color.arenaNavy.opacity(0.25)) } }.frame(height: 6)
        }.accessibilityElement(children: .ignore).accessibilityLabel("\(label), \(home.name) \(a)\(suffix), \(away.name) \(b)\(suffix)")
    }
    var history: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Previous meetings")
            let previous = store.catalogue.fixtures.filter { $0.finished && Set([$0.home, $0.away]) == Set([match.home, match.away]) }
            if previous.isEmpty { EmptyCard(title: "No previous meetings", message: "These teams have not met in the available sample catalogue.") }
            ForEach(previous) { MatchRow(match: $0) }
        }
    }
    var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Team comparison", subtitle: "Recorded sample results")
            VStack(spacing: 20) {
                HStack { Text(home.name).bold(); Spacer(); Text(away.name).bold() }
                HStack { FormStrip(results: store.catalogue.form(home.id)); Spacer(); FormStrip(results: store.catalogue.form(away.id)) }
                let table = store.catalogue.table("Brasileirão")
                let a = table.first { $0.id == home.id }!
                let b = table.first { $0.id == away.id }!
                stat("Points", a.points, b.points)
                stat("Goals scored", a.goalsFor, b.goalsFor)
                stat("Goals conceded", a.goalsAgainst, b.goalsAgainst)
                Text("Brasileirão sample season · W win, D draw, L loss. Most recent first.").font(.caption).foregroundStyle(Color.arenaMuted)
            }.card()
        }
    }
}
struct FormStrip: View {
    let results: [String]
    var body: some View { HStack(spacing: 4) { ForEach(Array(results.enumerated()), id: \.offset) { _, result in Text(result).font(.caption2.bold()).frame(width: 23, height: 27).foregroundStyle(result == "W" ? .white : Color.arenaInk).background(result == "W" ? Color.arenaBlue : Color.arenaBackground, in: RoundedRectangle(cornerRadius: 5)) } }.accessibilityLabel("Form, most recent first: " + results.map { $0 == "W" ? "Win" : ($0 == "D" ? "Draw" : "Loss") }.joined(separator: ", ")) }
}
struct TeamDetail: View {
    @EnvironmentObject var store: FootballStore
    let club: Club
    @State private var section = "Overview"
    var body: some View {
        Page {
            VStack(spacing: 16) {
                Shield(club: club, size: 72)
                Text(club.name).font(.largeTitle.bold())
                Label(club.city, systemImage: "mappin.and.ellipse").font(.subheadline)
                Button { store.toggleClub(club.id) } label: { Label(store.preferences.clubs.contains(club.id) ? "Following team" : "Follow team", systemImage: store.preferences.clubs.contains(club.id) ? "star.fill" : "star").font(.subheadline.bold()).padding(12).foregroundStyle(store.preferences.clubs.contains(club.id) ? Color.arenaInk : Color.arenaNavy).background(store.preferences.clubs.contains(club.id) ? Color.arenaYellow : .white, in: Capsule()) }.accessibilityIdentifier("followTeam")
            }.frame(maxWidth: .infinity).padding(24).foregroundStyle(.white).background(Color.arenaNavy.gradient, in: RoundedRectangle(cornerRadius: 20))
            Chips(values: ["Overview", "Fixtures", "Squad"], selection: $section)
            if section == "Overview" {
                SectionTitle(title: "Last five matches")
                VStack(alignment: .leading, spacing: 12) { FormStrip(results: store.catalogue.form(club.id)); Text("Most recent first · W win · D draw · L loss").font(.caption).foregroundStyle(Color.arenaMuted) }.frame(maxWidth: .infinity, alignment: .leading).card()
                SectionTitle(title: "Season snapshot", subtitle: "Brasileirão · demo")
                let table = store.catalogue.table("Brasileirão")
                if let row = table.first(where: { $0.id == club.id }), let index = table.firstIndex(where: { $0.id == club.id }) {
                    HStack { metric("Position", "\(index+1)"); metric("Played", row.played.formatted(.number.locale(Locale(identifier: "en_GB")))); metric("Points", row.points.formatted(.number.locale(Locale(identifier: "en_GB")))) }.card()
                }
                NavigationLink(value: "Brasileirão") { Label("View league table", systemImage: "list.number").frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered)
                SectionTitle(title: "Next fixtures")
                fixtureList(upcoming: true)
            } else if section == "Fixtures" { fixtureList(upcoming: false) }
            else {
                SectionTitle(title: "Demonstration squad")
                Text("Illustrative roster · not official club players").font(.caption).foregroundStyle(Color.arenaMuted)
                VStack(spacing: 0) { ForEach(Demo.squad(club), id: \.0) { n, name, role in HStack { Text(n.formatted(.number.locale(Locale(identifier: "en_GB")))).monospacedDigit().frame(width: 32); Text(name); Spacer(); Text(role).font(.caption).foregroundStyle(Color.arenaMuted) }.padding(.vertical, 14); Divider() } }.card()
            }
            SourceNote()
        }.navigationTitle(club.name).navigationBarTitleDisplayMode(.inline)
    }
    func metric(_ title: String, _ value: String) -> some View { VStack(spacing: 6) { Text(value).font(.system(size: 32, weight: .bold)).monospacedDigit(); Text(title).font(.caption).foregroundStyle(Color.arenaMuted) }.frame(maxWidth: .infinity) }
    @ViewBuilder func fixtureList(upcoming: Bool) -> some View {
        let fixtures = store.catalogue.filtered(day: nil).filter { ($0.home == club.id || $0.away == club.id) && (!upcoming || !$0.finished) }
        if fixtures.isEmpty { EmptyCard(title: "No fixtures available", message: "There are no scheduled games for this team in the sample catalogue.") }
        ForEach(fixtures) { MatchRow(match: $0) }
    }
}
