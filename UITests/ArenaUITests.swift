import XCTest

@MainActor final class ArenaUITests: XCTestCase {
    let app = XCUIApplication()
    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            continueAfterFailure = false
            app.launchArguments = ["-AppleLanguages", "(en-GB)", "-AppleLocale", "en_GB"]
            app.launch()
        }
    }
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func tapTab(_ name: String) {
        let button = app.buttons[name].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5)); button.tap()
    }
    func reveal(_ element: XCUIElement) {
        for _ in 0..<7 { if element.exists && element.isHittable { return }; app.swipeUp() }
    }
    func testHomeAndMatchTeamFlow() {
        XCTAssertTrue(app.buttons["featuredMatch"].waitForExistence(timeout: 10))
        capture("01-home")
        app.buttons["featuredMatch"].tap()
        XCTAssertTrue(app.staticTexts["DEMONSTRATION MATCH"].waitForExistence(timeout: 5))
        capture("02-match")
        let save = app.buttons["Save match"].firstMatch
        if save.exists { save.tap() }
        XCTAssertTrue(app.buttons["Saved match"].exists)
        app.buttons["Form"].firstMatch.tap()
        reveal(app.staticTexts["Team comparison"])
        XCTAssertTrue(app.staticTexts["Team comparison"].exists)
        app.swipeUp()
        capture("03-comparison")
        app.swipeDown(); app.swipeDown()
        app.buttons["Head-to-head"].firstMatch.tap()
        reveal(app.staticTexts["Previous meetings"])
        XCTAssertTrue(app.staticTexts["Previous meetings"].exists)
        XCTAssertTrue(app.buttons["match-r5p0"].exists)
        app.swipeUp()
        capture("17-head-to-head")
        app.swipeDown(); app.swipeDown()
        app.buttons["team-fla"].tap()
        XCTAssertTrue(app.buttons["followTeam"].waitForExistence(timeout: 5))
        if app.buttons["Follow team"].exists { app.buttons["followTeam"].tap() }
        capture("04-team")
        app.buttons["Squad"].tap()
        XCTAssertTrue(app.staticTexts["Demonstration squad"].exists)
        app.terminate(); app.launch()
        tapTab("My Football")
        XCTAssertTrue(app.staticTexts["1 following"].waitForExistence(timeout: 5))
        reveal(app.staticTexts["Saved matches"])
        capture("05-my-football")
    }
    func testCalendarAndInProgressDetail() {
        tapTab("Matches")
        app.buttons["In progress"].tap()
        XCTAssertTrue(app.buttons["match-sample"].waitForExistence(timeout: 5))
        capture("06-calendar")
        app.buttons["match-sample"].tap()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Match timeline"].exists)
        capture("07-events")
        let stats = app.buttons["Statistics"].firstMatch
        reveal(stats); stats.tap()
        reveal(app.staticTexts["Match statistics"])
        capture("08-statistics")
        app.swipeDown(); app.swipeDown()
        app.buttons["Line-ups"].firstMatch.tap()
        reveal(app.staticTexts["Sample line-ups"])
        XCTAssertTrue(app.staticTexts["Sample line-ups"].exists)
        capture("09-lineups")
    }
    func testReminderAndOffline() {
        app.buttons["featuredMatch"].tap()
        let reminder = app.buttons["Demo reminder"]
        reveal(reminder); reminder.tap()
        app.buttons["Remind me in one minute"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Allow"].waitForExistence(timeout: 5) { springboard.buttons["Allow"].tap() }
        let scheduled = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Demo reminder set")).firstMatch
        XCTAssertTrue(scheduled.waitForExistence(timeout: 10))
        capture("14-reminder")
        app.buttons["OK"].tap()
        reminder.tap()
        app.buttons["Cancel reminder"].tap()
        XCTAssertTrue(app.staticTexts["Reminder cancelled."].waitForExistence(timeout: 5))
        app.buttons["OK"].tap()
        tapTab("My Football")
        let offline = app.staticTexts["Works entirely offline"]
        reveal(offline)
        XCTAssertTrue(offline.exists)
        XCTAssertFalse(app.switches["Use offline catalogue"].exists)
        capture("15-offline-preferences")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["featuredMatch"].waitForExistence(timeout: 5))
        capture("16-offline-home")
    }
    func testCompetitionAndSearchEmptyState() {
        tapTab("Competitions")
        app.buttons["competition-0"].tap()
        XCTAssertTrue(app.staticTexts["League table"].waitForExistence(timeout: 5))
        capture("10-table")
        app.buttons["Scorers"].tap()
        XCTAssertTrue(app.staticTexts["Top scorers"].exists)
        capture("11-scorers")
        app.buttons["Fixtures"].tap()
        capture("12-rounds")
        tapTab("Home")
        let search = app.textFields["homeSearch"]
        reveal(search); search.tap(); search.typeText("zzzz\n")
        XCTAssertTrue(app.staticTexts["No matches found"].waitForExistence(timeout: 5))
        capture("13-empty-search")
    }
}
