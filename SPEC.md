# Arena Brasil — fully offline

Native SwiftUI football companion for iOS 17+, Swift 6, iPhone and iPad. English UK only. Local identifier: app.arenabrasil.football. Account assignment: acc_349. Shipping disabled.

## Product

Home with original blue stadium illustration, featured fixture, competition filters, search and personalised match ordering. Calendar with date and favourite filters. Match centre with events, line-ups, statistics, head-to-head and form comparison; three rectangular interactive shortcuts. Team profiles with form, fixtures, squads and league position. Competitions with computed table, rounds and scorers. My Football with favourite teams and competitions, saved matches and local reminder management.

## Offline architecture

All football content is bundled directly with the app and available synchronously on first launch. No network adapter, connection monitor, remote endpoints, API keys, server, online mode, fetching state or refresh action. No future external integration is required. User preferences are stored locally. Existing favourites survive migration from earlier versions that included an offline toggle; that obsolete toggle is removed.

The built-in season is fictional, anchored to November 2026. Illustrative players, results and statistics are clearly identified. The in-progress example is a frozen sample. Source information describes the bundled edition rather than a remote update. Local demo reminders are scheduled one minute after explicit confirmation, with system permission requested at that point. Cancellation removes the pending reminder.

## Design

8 pt grid, 16 pt margins, blue #0755D9, navy #082C78, light background #F2F5FA, white cards, dark text #14233D. Yellow #FFD54A highlights favourites. Original vector stadium, icon and letter shields. Native adaptive navigation with independent tab state, 44 pt minimum controls, VoiceOver labels and Reduce Motion handling.

## Verification

Catalogue integrity, complete round-robin history, no duplicate club in a league round, filters, computed standings, persisted favourites, immediate local catalogue access and migration of existing preferences. Runtime UI checks cover all primary screens, search, comparison, head-to-head, notification permission/scheduling/cancellation and fully offline settings. Simulator work uses the factory pool and shared build locks.
