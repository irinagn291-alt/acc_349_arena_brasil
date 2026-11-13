import SwiftUI

@main struct ArenaBrasilApp: App {
    #if DEBUG && targetEnvironment(simulator)
    @StateObject private var store: FootballStore
    init() {
        if let capture = ScreenshotLaunch.current {
            _store = StateObject(wrappedValue: FootballStore(screenshotPreferences: capture.preferences))
        } else {
            _store = StateObject(wrappedValue: FootballStore())
        }
    }
    #else
    @StateObject private var store = FootballStore()
    #endif
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store).tint(.arenaBlue).preferredColorScheme(.light)
                .environment(\.locale, Locale(identifier: "en_GB"))
                .environment(\.layoutDirection, .leftToRight)
        }
    }
}
#if DEBUG && targetEnvironment(simulator)
// Launch-only routes for the factory; indices are one-based in the selected screen order.
struct ScreenshotLaunch {
    static let keys = ["home", "matches", "match-centre", "team-profile", "competitions", "league-table", "my-football", "comparison", "statistics", "head-to-head", "scorers"]
    let key: String

    static var current: ScreenshotLaunch? {
        let process = ProcessInfo.processInfo
        let args = process.arguments
        func value(after flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
            return args[index + 1]
        }
        if args.contains("-ReviewScreen") {
            let key = value(after: "-ReviewScreen") ?? "home"
            return ScreenshotLaunch(key: keys.contains(key) ? key : "home")
        }
        let environment = process.environment
        let envFlag = environment["APPSTORE_SCREENSHOTS"].map { !["", "0", "false", "no"].contains($0.lowercased()) } ?? false
        guard args.contains("-AppStoreScreenshots") || envFlag else { return nil }
        let rawIndex = value(after: "-AppStoreScreenshotScreen") ?? environment["APPSTORE_SCREENSHOT_SCREEN"] ?? "1"
        let index = Int(rawIndex) ?? 1
        return ScreenshotLaunch(key: (1...keys.count).contains(index) ? keys[index - 1] : "home")
    }

    var preferences: Preferences {
        var result = Preferences()
        if key == "my-football" {
            result.clubs.insert("fla")
            result.competitions.insert("Brasileirão")
            result.matches.insert("featured")
        }
        return result
    }
}
#endif

struct RootView: View {
    @EnvironmentObject var store: FootballStore
    @Environment(\.scenePhase) var scenePhase
    @State private var selected = 0
    #if DEBUG && targetEnvironment(simulator)
    @State private var homePath = NavigationPath()
    @State private var matchesPath = NavigationPath()
    @State private var competitionsPath = NavigationPath()
    @State private var myFootballPath = NavigationPath()

    init() {
        guard let capture = ScreenshotLaunch.current else { return }
        var home = NavigationPath()
        var matches = NavigationPath()
        var competitions = NavigationPath()
        let catalogue = Demo.catalogue
        var tab = 0
        switch capture.key {
        case "matches": tab = 1
        case "match-centre", "statistics":
            tab = 1
            if let match = catalogue.fixtures.first(where: { $0.id == "sample" }) { matches.append(match) }
        case "comparison", "head-to-head":
            if let match = catalogue.fixtures.first(where: { $0.id == "featured" }) { home.append(match) }
        case "team-profile":
            if let match = catalogue.fixtures.first(where: { $0.id == "featured" }) { home.append(match) }
            home.append(catalogue.club("fla"))
        case "competitions": tab = 2
        case "league-table", "scorers":
            tab = 2
            competitions.append("Brasileirão")
        case "my-football": tab = 3
        default: break
        }
        _selected = State(initialValue: tab)
        _homePath = State(initialValue: home)
        _matchesPath = State(initialValue: matches)
        _competitionsPath = State(initialValue: competitions)
    }
    #endif
    var body: some View {
        adjustedTabContent
            .onOpenURL { url in if WidgetIdentity.accepts(url) {
                #if DEBUG && targetEnvironment(simulator)
                store.applyWidgetQA(url)
                #endif
                selected = 3
            } }
            .task { await store.reconcileReminders() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await store.reconcileReminders() } } }
            .alert("Arena Brasil", isPresented: Binding(get: { store.notice != nil }, set: { if !$0 { store.notice = nil } })) { Button("OK", role: .cancel) { store.notice = nil } } message: { Text(store.notice ?? "") }
    }
    @ViewBuilder var adjustedTabContent: some View {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.current != nil {
            tabContent
                .transaction { $0.animation = nil; $0.disablesAnimations = true }
        } else {
            tabContent
        }
        #else
        tabContent
        #endif
    }
    @ViewBuilder var tabContent: some View {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.current != nil {
            TabView(selection: $selected) {
                captureStack(path: $homePath) { HomeView() }.tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
                captureStack(path: $matchesPath) { MatchesView() }.tabItem { Label("Matches", systemImage: "sportscourt") }.tag(1)
                captureStack(path: $competitionsPath) { CompetitionsView() }.tabItem { Label("Competitions", systemImage: "trophy") }.tag(2)
                captureStack(path: $myFootballPath) { MyFootballView() }.tabItem { Label("My Football", systemImage: "star") }.tag(3)
            }
        } else {
            normalTabs
        }
        #else
        normalTabs
        #endif
    }
    var normalTabs: some View {
        TabView(selection: $selected) {
            stack { HomeView() }.tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            stack { MatchesView() }.tabItem { Label("Matches", systemImage: "sportscourt") }.tag(1)
            stack { CompetitionsView() }.tabItem { Label("Competitions", systemImage: "trophy") }.tag(2)
            stack { MyFootballView() }.tabItem { Label("My Football", systemImage: "star") }.tag(3)
        }
    }
    #if DEBUG && targetEnvironment(simulator)
    func captureStack<Content: View>(path: Binding<NavigationPath>, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: path) {
            content().navigationDestination(for: Fixture.self) { MatchDetail(match: $0) }
                .navigationDestination(for: Club.self) { TeamDetail(club: $0) }
                .navigationDestination(for: String.self) { CompetitionDetail(name: $0) }
        }
    }
    #endif
    func stack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content().navigationDestination(for: Fixture.self) { MatchDetail(match: $0) }
                .navigationDestination(for: Club.self) { TeamDetail(club: $0) }
                .navigationDestination(for: String.self) { CompetitionDetail(name: $0) }
        }
    }
}
struct Page<Content: View>: View {
    @EnvironmentObject var store: FootballStore
    @ViewBuilder let content: Content
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) {
        content }.frame(maxWidth: 760).padding(16).frame(maxWidth: .infinity) }.scrollDismissesKeyboard(.interactively).background(Color.arenaBackground).foregroundStyle(Color.arenaInk) }
}
struct HomeView: View {
    @EnvironmentObject var store: FootballStore
    @State private var competition = "All"
    @State private var search = ""
    @State private var favourites = false
    var fixtures: [Fixture] { store.catalogue.filtered(day: nil, competition: competition, mode: favourites ? "Favourites" : "All", favourites: store.preferences.clubs, query: search).filter { !$0.finished }.sorted { a, b in
        let af = store.preferences.clubs.contains(a.home) || store.preferences.clubs.contains(a.away)
        let bf = store.preferences.clubs.contains(b.home) || store.preferences.clubs.contains(b.away)
        return af != bf ? af : (a.day, a.time) < (b.day, b.time)
    } }
    var body: some View {
        Page {
            HStack { VStack(alignment: .leading, spacing: 4) { Text("THE BEAUTIFUL GAME").font(.caption.weight(.heavy)).tracking(2).foregroundStyle(Color.arenaBlue); Text("Your football.\nYour Brasil.").font(.system(size: 34, weight: .heavy, design: .rounded)) }; Spacer(); Image(systemName: "soccerball").font(.system(size: 42)).foregroundStyle(Color.arenaBlue) }
            if let f = store.catalogue.fixtures.first(where: { $0.id == "featured" }), search.isEmpty { FeaturedMatch(match: f) }
            HStack { Image(systemName: "magnifyingglass").foregroundStyle(Color.arenaMuted); TextField("Search teams or competitions", text: $search).autocorrectionDisabled().submitLabel(.search).accessibilityIdentifier("homeSearch"); if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill").frame(width: 44, height: 44) }.accessibilityLabel("Clear search") } }.padding(.horizontal, 16).frame(minHeight: 52).background(.white, in: RoundedRectangle(cornerRadius: 12))
            Chips(values: ["All"] + Demo.competitions, selection: $competition)
            HStack { SectionTitle(title: store.preferences.clubs.isEmpty ? "Around the grounds" : "Picked for you"); Button { favourites.toggle() } label: { Image(systemName: favourites ? "star.fill" : "star").foregroundStyle(favourites ? Color.arenaYellow : Color.arenaBlue).frame(width: 44, height: 44) }.accessibilityLabel("Filter favourite teams").accessibilityAddTraits(favourites ? .isSelected : []) }
            if fixtures.isEmpty { EmptyCard(title: "No matches found", message: "Try another competition or add a favourite team in My Football.") }
            ForEach(fixtures) { MatchRow(match: $0) }
            SourceNote()
        }.navigationTitle("Arena Brasil").navigationBarTitleDisplayMode(.inline)
    }
}
struct FeaturedMatch: View {
    @EnvironmentObject var store: FootballStore
    let match: Fixture
    var body: some View {
        NavigationLink(value: match) {
            VStack(spacing: 20) {
                HStack { Label("MATCH SPOTLIGHT", systemImage: "sparkle").font(.caption.weight(.heavy)).tracking(1); Spacer(); Text("DEMO").font(.caption2.bold()).padding(6).background(.white.opacity(0.15), in: Capsule()) }
                HStack {
                    featuredClub(match.home)
                    Spacer()
                    VStack(spacing: 5) { featuredTime; Text("13 NOV · BRT").font(.caption.weight(.bold)) }
                    Spacer()
                    featuredClub(match.away)
                }
                VStack(spacing: 5) { Text(match.competition + " · Round \(match.round)").font(.subheadline.bold()); Label(match.stadium, systemImage: "mappin.and.ellipse").font(.caption) }
                HStack { Text("Open match centre").font(.subheadline.bold()); Spacer(); Image(systemName: "arrow.up.right") }.padding(14).background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            }.padding(20).foregroundStyle(.white).background { ZStack { LinearGradient(colors: [.arenaBlue, .arenaNavy], startPoint: .topLeading, endPoint: .bottomTrailing); Stadium() } }.clipShape(RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain).accessibilityIdentifier("featuredMatch")
    }
    @ViewBuilder var featuredTime: some View {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.current?.key == "home" {
            Text(match.time).font(.system(size: 34, weight: .heavy, design: .rounded)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.8).layoutPriority(1)
        } else {
            Text(match.time).font(.system(size: 34, weight: .heavy, design: .rounded)).monospacedDigit()
        }
        #else
        Text(match.time).font(.system(size: 34, weight: .heavy, design: .rounded)).monospacedDigit()
        #endif
    }
    func featuredClub(_ id: String) -> some View { VStack(spacing: 10) { Shield(club: store.catalogue.club(id), size: 52); Text(store.catalogue.club(id).name).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.7) }.frame(maxWidth: .infinity) }
}
struct MatchesView: View {
    @EnvironmentObject var store: FootballStore
    @State private var day = 13
    @State private var mode = "All"
    #if DEBUG && targetEnvironment(simulator)
    init() {
        if ScreenshotLaunch.current?.key == "match-centre" {
            _mode = State(initialValue: "In progress")
        }
    }
    #endif
    var body: some View {
        Page {
            SectionTitle(title: "November 2026", subtitle: "Demo schedule · BRT")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { ForEach(7...16, id: \.self) { d in Button { day = d } label: { VStack(spacing: 6) { Text(["SAT", "SUN", "MON", "TUE", "WED", "THU", "FRI"][(d-7)%7]).font(.caption2.bold()); Text(d.formatted(.number.locale(Locale(identifier: "en_GB")))).font(.title2.bold()).monospacedDigit() }.frame(width: 56, height: 76).foregroundStyle(day == d ? .white : Color.arenaInk).background(day == d ? Color.arenaBlue : .white, in: RoundedRectangle(cornerRadius: 12)) }.accessibilityIdentifier("day-\(d)").accessibilityAddTraits(day == d ? .isSelected : []) } }
            }.defaultScrollAnchor(.trailing)
            Chips(values: ["All", "In progress", "Favourites"], selection: $mode)
            let matches = store.catalogue.filtered(day: day, mode: mode, favourites: store.preferences.clubs)
            SectionTitle(title: "Matchday", subtitle: matches.count == 1 ? "1 match" : "\(matches.count) matches")
            if matches.isEmpty { EmptyCard(title: "No fixtures here", message: "Choose another date or filter to explore the sample season.") }
            ForEach(matches) { MatchRow(match: $0) }
            SourceNote()
        }.navigationTitle("Matches")
    }
}
