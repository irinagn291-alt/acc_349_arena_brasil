import XCTest
@testable import ArenaBrasil

final class FootballTests: XCTestCase {
    func testCatalogueIntegrityAndRoundRobin() throws {
        let data = try Demo.catalogue.validated()
        XCTAssertEqual(data.clubs.count, 6)
        XCTAssertEqual(data.fixtures.count, 20)
        let completed = data.fixtures.filter(\.finished)
        XCTAssertEqual(completed.count, 15)
        let pairs = Set(completed.map { [$0.home, $0.away].sorted().joined(separator: ":") })
        XCTAssertEqual(pairs.count, 15, "Each club meets every other club exactly once")
        for club in data.clubs { XCTAssertEqual(data.form(club.id).count, 5) }
        for round in 1...7 {
            let participants = data.fixtures.filter { $0.competition == "Brasileirão" && $0.round == round }.flatMap { [$0.home, $0.away] }
            XCTAssertEqual(participants.count, Set(participants).count, "A club cannot play twice in the same league round")
        }
    }
    func testDateCompetitionAndFavouriteFilters() {
        let data = Demo.catalogue
        XCTAssertEqual(data.filtered(day: 13).count, 3)
        XCTAssertEqual(data.filtered(day: 13, mode: "In progress").map(\.id), ["sample"])
        XCTAssertEqual(data.filtered(day: 13, mode: "Favourites", favourites: ["fla"]).map(\.id), ["featured"])
        XCTAssertEqual(data.filtered(day: nil, competition: "Libertadores").map(\.id), ["lib"])
        XCTAssertTrue(data.filtered(day: 16).isEmpty)
        XCTAssertEqual(data.filtered(day: 13, query: "FLAMENGO").map(\.id), ["featured"])
        XCTAssertTrue(data.filtered(day: nil, query: "no club found").isEmpty)
    }
    func testStandingsExcludeInProgressAndConserveGoals() {
        let table = Demo.catalogue.table("Brasileirão")
        XCTAssertEqual(table.reduce(0) { $0 + $1.played }, 30)
        XCTAssertEqual(table.reduce(0) { $0 + $1.goalsFor }, table.reduce(0) { $0 + $1.goalsAgainst })
        for row in table {
            XCTAssertEqual(row.played, row.won + row.drawn + row.lost)
            XCTAssertEqual(row.points, row.won * 3 + row.drawn)
        }
        XCTAssertTrue(zip(table, table.dropFirst()).allSatisfy { $0.points >= $1.points })
    }
    func testMalformedCatalogueRejected() {
        let bad = Catalogue(clubs: [], fixtures: Demo.catalogue.fixtures, source: "Test", updatedAt: Date(), isDemo: false)
        XCTAssertThrowsError(try bad.validated())
    }
    @MainActor func testPersistenceAndRemoval() {
        let name = "ArenaBrasil.Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let first = FootballStore(defaults: defaults)
        first.toggleClub("fla"); first.toggleCompetition("Brasileirão"); first.toggleMatch("featured")
        let second = FootballStore(defaults: defaults)
        XCTAssertEqual(second.preferences, first.preferences)
        second.toggleClub("fla"); second.toggleMatch("featured")
        XCTAssertTrue(second.preferences.clubs.isEmpty)
        XCTAssertTrue(second.preferences.matches.isEmpty)
    }
    @MainActor func testCatalogueAvailableImmediatelyAfterRestart() {
        let name = "ArenaBrasil.LocalTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let first = FootballStore(defaults: defaults)
        first.toggleMatch("featured")
        let second = FootballStore(defaults: defaults)
        XCTAssertEqual(first.catalogue.fixtures, second.catalogue.fixtures)
        XCTAssertEqual(second.catalogue.fixtures.count, 20)
        XCTAssertTrue(second.preferences.matches.contains("featured"))
    }
    @MainActor func testExistingPreferencesSurviveOfflineOnlyMigration() throws {
        let name = "ArenaBrasil.MigrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let legacy = #"{"clubs":["fla"],"competitions":["Brasileirão"],"matches":["featured"],"reminders":[],"offline":false}"#.data(using: .utf8)!
        defaults.set(legacy, forKey: "arena.preferences")
        let store = FootballStore(defaults: defaults)
        XCTAssertEqual(store.preferences.clubs, ["fla"])
        XCTAssertEqual(store.preferences.matches, ["featured"])
        XCTAssertEqual(store.preferences.competitions, ["Brasileirão"])
        XCTAssertEqual(store.catalogue.fixtures.count, 20)
    }
}
