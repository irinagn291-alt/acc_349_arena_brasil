import SwiftUI

struct CompetitionsView: View {
    @EnvironmentObject var store: FootballStore
    var body: some View {
        Page {
            Text("The heart of\nBrazilian football.").font(.system(size: 32, weight: .heavy, design: .rounded))
            Text("Explore the tables, follow every round and discover the names on the scoresheet.").font(.subheadline).foregroundStyle(Color.arenaMuted)
            ForEach(Array(Demo.competitions.enumerated()), id: \.element) { index, name in
                NavigationLink(value: name) {
                    HStack(spacing: 16) {
                        Image(systemName: ["trophy.fill", "shield.lefthalf.filled", "globe.americas.fill"][index]).font(.system(size: 30)).frame(width: 64, height: 72).foregroundStyle(.white).background(Color.arenaBlue.gradient, in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 8) { Text(name).font(.title3.bold()); Text(index == 0 ? "League · 6 demo clubs" : "Cup · sample fixtures").font(.caption).foregroundStyle(Color.arenaMuted); Text("2026 SEASON").font(.caption2.bold()).tracking(1).foregroundStyle(Color.arenaBlue) }
                        Spacer()
                        if store.preferences.competitions.contains(name) { Image(systemName: "star.fill").foregroundStyle(Color.arenaYellow) }
                        Image(systemName: "chevron.right").font(.caption.bold())
                    }.card()
                }.buttonStyle(.plain).accessibilityIdentifier("competition-\(index)")
            }
            SourceNote()
        }.navigationTitle("Competitions")
    }
}
struct CompetitionDetail: View {
    @EnvironmentObject var store: FootballStore
    let name: String
    @State private var section = "Table"
    @State private var round = 6
    init(name: String) {
        self.name = name
        #if DEBUG && targetEnvironment(simulator)
        _section = State(initialValue: ScreenshotLaunch.current?.key == "scorers" ? "Scorers" : "Table")
        #endif
    }
    var body: some View {
        Page {
            HStack(spacing: 16) {
                Image(systemName: "trophy.fill").font(.largeTitle)
                VStack(alignment: .leading, spacing: 5) { Text(name).font(.title.bold()); Text("2026 · DEMO SEASON").font(.caption.bold()).tracking(1) }
                Spacer()
                Button { store.toggleCompetition(name) } label: { Image(systemName: store.preferences.competitions.contains(name) ? "star.fill" : "star").foregroundStyle(store.preferences.competitions.contains(name) ? Color.arenaYellow : .white).frame(width: 44, height: 44) }.accessibilityLabel(store.preferences.competitions.contains(name) ? "Unfollow competition" : "Follow competition")
            }.padding(20).foregroundStyle(.white).background(Color.arenaNavy.gradient, in: RoundedRectangle(cornerRadius: 18))
            Chips(values: ["Table", "Fixtures", "Scorers"], selection: $section)
            if section == "Table" {
                if name == "Brasileirão" { standings }
                else { EmptyCard(title: "Cup format", message: "This competition has no league table. Open Fixtures to explore the sample cup schedule."); Button("Show fixtures") { section = "Fixtures" }.buttonStyle(.borderedProminent) }
            } else if section == "Fixtures" {
                HStack { Text("Round").font(.headline); Spacer(); Picker("Round", selection: $round) { ForEach(1...(name == "Brasileirão" ? 7 : 1), id: \.self) { Text("Round \($0)").tag($0) } }.pickerStyle(.menu) }.card()
                let fixtures = store.catalogue.filtered(day: nil, competition: name).filter { $0.round == round }
                if fixtures.isEmpty { EmptyCard(title: "No fixtures in this round", message: "Choose another round to view matches.") }
                ForEach(fixtures) { MatchRow(match: $0) }
            } else { scorers }
            SourceNote()
        }.navigationTitle(name).navigationBarTitleDisplayMode(.inline).onAppear { if name != "Brasileirão" { round = 1 } }
    }
    var standings: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "League table", subtitle: "After 5 sample rounds")
            VStack(spacing: 0) {
                HStack { Text("CLUB").frame(maxWidth: .infinity, alignment: .leading); Text("P").frame(width: 28); Text("GD").frame(width: 30); Text("PTS").frame(width: 34) }.font(.caption2.bold()).foregroundStyle(Color.arenaMuted).padding(.vertical, 12)
                ForEach(Array(store.catalogue.table(name).enumerated()), id: \.element.id) { index, row in
                    Divider()
                    NavigationLink(value: row.club) {
                        HStack(spacing: 8) {
                            Text("\(index+1)").font(.caption.bold()).frame(width: 18)
                            Shield(club: row.club, size: 24)
                            Text(row.club.name).font(.subheadline.weight(.semibold)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.played.formatted(.number.locale(Locale(identifier: "en_GB")))).frame(width: 28)
                            Text(row.difference.formatted(.number.locale(Locale(identifier: "en_GB")))).frame(width: 30)
                            Text(row.points.formatted(.number.locale(Locale(identifier: "en_GB")))).bold().foregroundStyle(Color.arenaBlue).frame(width: 34)
                        }.font(.subheadline).monospacedDigit().padding(.vertical, 16).foregroundStyle(Color.arenaInk)
                    }.accessibilityLabel("Position \(index+1), \(row.club.name), played \(row.played), goal difference \(row.difference), \(row.points) points")
                }
            }.card()
            Text("P: played · GD: goal difference · PTS: points\nThree points for a win, one for a draw. Ties use goal difference, goals scored, then club name.").font(.caption).foregroundStyle(Color.arenaMuted)
        }
    }
    var scorers: some View {
        let goals = scorerRows()
        return VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Top scorers", subtitle: "Illustrative players")
            if goals.isEmpty { EmptyCard(title: "No goals recorded", message: "The sample competition has not started yet.") }
            else {
                VStack(spacing: 0) {
                    ForEach(Array(goals.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 12) { Text("\(index+1)").font(.caption.bold()).frame(width: 20); VStack(alignment: .leading, spacing: 5) { Text(item.0).font(.subheadline.bold()); Text(item.1).font(.caption).foregroundStyle(Color.arenaMuted) }; Spacer(); Text(item.2.formatted(.number.locale(Locale(identifier: "en_GB")))).font(.title2.bold()).monospacedDigit(); Text("goals").font(.caption) }.padding(.vertical, 14)
                        Divider()
                    }
                }.card()
            }
        }
    }
    func scorerRows() -> [(String, String, Int)] {
        var totals: [String: Int] = [:]
        for f in store.catalogue.fixtures where f.competition == name && f.finished {
            totals[f.home + "|J. Pereira", default: 0] += f.homeGoals ?? 0
            totals[f.away + "|V. Souza", default: 0] += f.awayGoals ?? 0
        }
        return totals.filter { $0.value > 0 }.map { key, goals in let split = key.split(separator: "|"); return (String(split[1]), store.catalogue.club(String(split[0])).name, goals) }.sorted { $0.2 != $1.2 ? $0.2 > $1.2 : ($0.1, $0.0) < ($1.1, $1.0) }
    }
}
struct MyFootballView: View {
    @EnvironmentObject var store: FootballStore
    @State private var manage = false
    @State private var search = ""
    var body: some View {
        Page {
            HStack { VStack(alignment: .leading, spacing: 4) { Text("Your side of the game.").font(.title2.bold()); Text("A home for the clubs you love.").font(.subheadline).foregroundStyle(Color.arenaMuted) }; Spacer(); Image(systemName: "star.circle.fill").font(.system(size: 40)).foregroundStyle(Color.arenaBlue) }
            HStack { SectionTitle(title: "My teams", subtitle: "\(store.preferences.clubs.count) following"); Button(manage ? "Done" : "Manage") { manage.toggle() }.font(.subheadline.bold()).frame(minHeight: 44) }
            if store.preferences.clubs.isEmpty || manage {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose your clubs").font(.headline)
                    Text("Follow a team to bring its matches to the top of Home.").font(.subheadline).foregroundStyle(Color.arenaMuted)
                    TextField("Find a team", text: $search).textFieldStyle(.roundedBorder).frame(minHeight: 44)
                    ForEach(store.catalogue.clubs.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }) { club in
                        HStack { NavigationLink(value: club) { HStack(spacing: 12) { Shield(club: club, size: 30); Text(club.name).font(.subheadline.bold()) }.frame(maxWidth: .infinity, minHeight: 48, alignment: .leading) }.buttonStyle(.plain)
                            Button { store.toggleClub(club.id) } label: { Image(systemName: store.preferences.clubs.contains(club.id) ? "star.fill" : "star").foregroundStyle(store.preferences.clubs.contains(club.id) ? Color.arenaYellow : Color.arenaBlue).frame(width: 44, height: 44) }.accessibilityLabel("\(store.preferences.clubs.contains(club.id) ? "Unfollow" : "Follow") \(club.name)").accessibilityIdentifier("favourite-\(club.id)")
                        }
                    }
                }.card()
            } else {
                ForEach(store.catalogue.clubs.filter { store.preferences.clubs.contains($0.id) }) { club in NavigationLink(value: club) { HStack(spacing: 12) { Shield(club: club, size: 36); Text(club.name).bold(); Spacer(); FormStrip(results: store.catalogue.form(club.id)); Image(systemName: "chevron.right").font(.caption) }.card() }.buttonStyle(.plain) }
            }
            SectionTitle(title: "My competitions")
            ForEach(Demo.competitions, id: \.self) { name in
                HStack { NavigationLink(value: name) { Label(name, systemImage: "trophy").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading) }; Button { store.toggleCompetition(name) } label: { Image(systemName: store.preferences.competitions.contains(name) ? "star.fill" : "star").foregroundStyle(store.preferences.competitions.contains(name) ? Color.arenaYellow : Color.arenaBlue).frame(width: 44, height: 44) }.accessibilityLabel("\(store.preferences.competitions.contains(name) ? "Unfollow" : "Follow") \(name)") }.card()
            }
            SectionTitle(title: "Saved matches", subtitle: "\(store.preferences.matches.count)")
            if store.preferences.matches.isEmpty { EmptyCard(title: "Keep a match close", message: "Open any match and tap Save match. It will be waiting here next time.") }
            ForEach(store.catalogue.fixtures.filter { store.preferences.matches.contains($0.id) }) { MatchRow(match: $0) }
            SectionTitle(title: "Reminders")
            if store.preferences.reminders.isEmpty { Text("No pending reminders. Open a match to try a one-minute demo reminder.").font(.subheadline).foregroundStyle(Color.arenaMuted).frame(maxWidth: .infinity, alignment: .leading).card() }
            ForEach(store.catalogue.fixtures.filter { store.preferences.reminders.contains($0.id) }) { f in HStack { Text("\(store.catalogue.club(f.home).short) v \(store.catalogue.club(f.away).short)").font(.headline); Spacer(); Button("Cancel") { Task { await store.remind(f) } }.frame(minHeight: 44) }.card() }
            SectionTitle(title: "About this catalogue")
            VStack(alignment: .leading, spacing: 16) {
                Label("Works entirely offline", systemImage: "checkmark.circle.fill").font(.headline).accessibilityIdentifier("offlineStatus")
                Text("All matches, squads and statistics are included in the app. Favourites and reminders stay on this device.").font(.subheadline).foregroundStyle(Color.arenaMuted)
                LabeledContent("Language", value: "English (UK)")
                LabeledContent("Fixture time zone", value: "Brasília · BRT")
                Text("Arena Brasil 1.0 · Independent football companion. Club names are used for identification; shields and stadium artwork are original.").font(.caption).foregroundStyle(Color.arenaMuted)
            }.card()
            SourceNote()
        }.navigationTitle("My Football")
    }
}
