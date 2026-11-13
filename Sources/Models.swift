import Foundation

struct Club: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let short: String
    let city: String
    let colour: String
}
struct Fixture: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let home: String
    let away: String
    let competition: String
    let day: Int
    let time: String
    let homeGoals: Int?
    let awayGoals: Int?
    let minute: Int?
    let stadium: String
    let round: Int
    var finished: Bool { homeGoals != nil && minute == nil }
    var score: String { homeGoals.map { "\($0) – \(awayGoals ?? 0)" } ?? time }
    var status: String { minute.map { "Sample · \($0)′" } ?? (finished ? "Full time" : "Scheduled") }
}
struct Standing: Identifiable, Sendable {
    let club: Club
    var id: String { club.id }
    var played = 0
    var won = 0
    var drawn = 0
    var lost = 0
    var goalsFor = 0
    var goalsAgainst = 0
    var points: Int { won * 3 + drawn }
    var difference: Int { goalsFor - goalsAgainst }
}
struct Catalogue: Codable, Sendable {
    let clubs: [Club]
    let fixtures: [Fixture]
    let source: String
    let updatedAt: Date
    let isDemo: Bool
    func club(_ id: String) -> Club { clubs.first { $0.id == id } ?? Club(id: id, name: id, short: "?", city: "", colour: "0755D9") }
    func filtered(day: Int?, competition: String = "All", mode: String = "All", favourites: Set<String> = [], query: String = "") -> [Fixture] {
        fixtures.filter { f in
            (day == nil || f.day == day) && (competition == "All" || f.competition == competition)
            && (mode != "In progress" || f.minute != nil)
            && (mode != "Favourites" || favourites.contains(f.home) || favourites.contains(f.away))
            && (query.isEmpty || "\(club(f.home).name) \(club(f.away).name) \(f.competition)".localizedCaseInsensitiveContains(query))
        }.sorted { ($0.day, $0.time, $0.id) < ($1.day, $1.time, $1.id) }
    }
    func table(_ competition: String) -> [Standing] {
        var rows = Dictionary(uniqueKeysWithValues: clubs.map { ($0.id, Standing(club: $0)) })
        for f in fixtures where f.competition == competition && f.finished {
            guard let hg = f.homeGoals, let ag = f.awayGoals else { continue }
            for (id, gf, ga) in [(f.home, hg, ag), (f.away, ag, hg)] {
                rows[id]?.played += 1; rows[id]?.goalsFor += gf; rows[id]?.goalsAgainst += ga
                if gf > ga { rows[id]?.won += 1 } else if gf == ga { rows[id]?.drawn += 1 } else { rows[id]?.lost += 1 }
            }
        }
        return rows.values.sorted { a, b in
            if a.points != b.points { return a.points > b.points }
            if a.difference != b.difference { return a.difference > b.difference }
            if a.goalsFor != b.goalsFor { return a.goalsFor > b.goalsFor }
            return a.club.name < b.club.name
        }
    }
    func form(_ id: String) -> [String] {
        fixtures.filter { $0.finished && ($0.home == id || $0.away == id) }.sorted { $0.day > $1.day }.prefix(5).map {
            let own = $0.home == id ? $0.homeGoals! : $0.awayGoals!
            let other = $0.home == id ? $0.awayGoals! : $0.homeGoals!
            return own == other ? "D" : (own > other ? "W" : "L")
        }
    }
    func validated() throws -> Catalogue {
        let ids = Set(clubs.map(\.id))
        guard ids.count == clubs.count, Set(fixtures.map(\.id)).count == fixtures.count,
              !clubs.isEmpty, fixtures.allSatisfy({ ids.contains($0.home) && ids.contains($0.away) && $0.home != $0.away && (($0.homeGoals == nil) == ($0.awayGoals == nil)) && ($0.homeGoals ?? 0) >= 0 && ($0.awayGoals ?? 0) >= 0 }) else { throw CatalogueError.invalidCatalogue }
        return self
    }
}
enum CatalogueError: Error { case invalidCatalogue }
enum Demo {
    static let competitions = ["Brasileirão", "Copa do Brasil", "Libertadores"]
    static let catalogue: Catalogue = {
        let clubs = [
            Club(id: "fla", name: "Flamengo", short: "FLA", city: "Rio de Janeiro", colour: "B5263D"),
            Club(id: "pal", name: "Palmeiras", short: "PAL", city: "São Paulo", colour: "167557"),
            Club(id: "cor", name: "Corinthians", short: "COR", city: "São Paulo", colour: "25334A"),
            Club(id: "san", name: "Santos", short: "SAN", city: "Santos", colour: "54667B"),
            Club(id: "flu", name: "Fluminense", short: "FLU", city: "Rio de Janeiro", colour: "8E3E59"),
            Club(id: "bot", name: "Botafogo", short: "BOT", city: "Rio de Janeiro", colour: "364356")
        ]
        var fixtures: [Fixture] = []
        var order = clubs.map(\.id)
        for round in 1...5 {
            for pair in 0..<3 {
                let home = order[pair]
                let away = order[5 - pair]
                fixtures.append(Fixture(id: "r\(round)p\(pair)", home: home, away: away, competition: "Brasileirão", day: round + 6, time: "19:00", homeGoals: (round + pair) % 4, awayGoals: pair % 3, minute: nil, stadium: "Arena Brasil", round: round))
            }
            let last = order.removeLast()
            order.insert(last, at: 1)
        }
        fixtures += [
            Fixture(id: "featured", home: "fla", away: "pal", competition: "Brasileirão", day: 13, time: "21:30", homeGoals: nil, awayGoals: nil, minute: nil, stadium: "Maracanã · Rio de Janeiro", round: 6),
            Fixture(id: "sample", home: "cor", away: "san", competition: "Brasileirão", day: 13, time: "19:00", homeGoals: 2, awayGoals: 1, minute: 67, stadium: "Neo Química Arena · São Paulo", round: 6),
            Fixture(id: "cup", home: "flu", away: "bot", competition: "Copa do Brasil", day: 13, time: "20:00", homeGoals: nil, awayGoals: nil, minute: nil, stadium: "Maracanã · Rio de Janeiro", round: 1),
            Fixture(id: "lib", home: "pal", away: "flu", competition: "Libertadores", day: 14, time: "21:00", homeGoals: nil, awayGoals: nil, minute: nil, stadium: "Allianz Parque · São Paulo", round: 1),
            Fixture(id: "next", home: "san", away: "fla", competition: "Brasileirão", day: 15, time: "18:00", homeGoals: nil, awayGoals: nil, minute: nil, stadium: "Vila Belmiro · Santos", round: 7)
        ]
        return Catalogue(clubs: clubs, fixtures: fixtures, source: "Arena Brasil sample catalogue", updatedAt: Date(timeIntervalSince1970: 1794571200), isDemo: true)
    }()
    static func squad(_ club: Club) -> [(Int, String, String)] {
        let names = ["R. Alves", "D. Costa", "L. Martins", "A. Rocha", "B. Lima", "G. Silva", "P. Santos", "M. Oliveira", "J. Pereira", "V. Souza", "T. Ferreira"]
        return names.enumerated().map { ($0.offset + 1, "\(club.short) · \($0.element)", $0.offset == 0 ? "Goalkeeper" : ($0.offset < 5 ? "Defender" : ($0.offset < 8 ? "Midfielder" : "Forward"))) }
    }
}
