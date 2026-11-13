import Foundation

enum WidgetIdentity {
    static let group = "group.app.arenabrasil.football"
    static let kind = "app.arenabrasil.football.progress"
    static let scheme = "arenabrasil"
    static let route = "my-football"
    static let displayName = "Arena Brasil"
    static let emptyHint = "Follow teams in the sample catalogue."
    static let widgetName = "My football"
    static let widgetDescription = "Your saved football and the offline sample match."
    static let icon = "soccerball"
    static let theme = "football"
    static let accent: [Double] = [0.96, 0.8, 0.22]
    static let background: [Double] = [0.03, 0.14, 0.38]
    static let serif = false
    static var url: URL { URL(string: "\(scheme)://widget/\(route)")! }
    static func accepts(_ url: URL) -> Bool { url.scheme == scheme && url.host == "widget" && url.path == "/" + route }
}
