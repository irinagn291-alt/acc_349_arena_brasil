import SwiftUI

extension Color {
    init(hex: String) {
        let n = UInt64(hex, radix: 16) ?? 0
        self.init(red: Double((n >> 16) & 255) / 255, green: Double((n >> 8) & 255) / 255, blue: Double(n & 255) / 255)
    }
    static let arenaBlue = Color(hex: "0755D9")
    static let arenaNavy = Color(hex: "082C78")
    static let arenaInk = Color(hex: "14233D")
    static let arenaMuted = Color(hex: "52657F")
    static let arenaBackground = Color(hex: "F2F5FA")
    static let arenaYellow = Color(hex: "FFD54A")
}
struct Card: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.arenaNavy.opacity(0.06)))
    }
}
extension View { func card() -> some View { modifier(Card()) } }
struct Shield: View {
    let club: Club
    var size: CGFloat = 48
    var body: some View {
        ZStack {
            UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 22, bottomTrailingRadius: 22, topTrailingRadius: 12).fill(Color(hex: club.colour).gradient)
            VStack(spacing: 2) { Image(systemName: "soccerball").font(.system(size: size * 0.29)); Text(club.short).font(.system(size: size * 0.21, weight: .black, design: .rounded)) }.foregroundStyle(.white)
        }.frame(width: size, height: size * 1.12).accessibilityLabel(club.name)
    }
}
struct Stadium: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(x: size.width * 0.12, y: size.height * 0.08, width: size.width * 0.95, height: size.height * 0.9)
            for i in 0..<6 {
                context.stroke(Path(ellipseIn: rect.insetBy(dx: CGFloat(i) * 9, dy: CGFloat(i) * 7)), with: .color(.white.opacity(0.08)), lineWidth: 2)
            }
            var field = Path()
            let a = CGPoint(x: size.width * 0.33, y: size.height * 0.36)
            let b = CGPoint(x: size.width * 0.78, y: size.height * 0.25)
            let c = CGPoint(x: size.width * 0.94, y: size.height * 0.65)
            let d = CGPoint(x: size.width * 0.43, y: size.height * 0.81)
            field.move(to: a); field.addLine(to: b); field.addLine(to: c); field.addLine(to: d); field.closeSubpath()
            context.fill(field, with: .color(.white.opacity(0.06)))
            context.stroke(field, with: .color(.white.opacity(0.2)), lineWidth: 2)
            context.stroke(Path(ellipseIn: CGRect(x: size.width * 0.57, y: size.height * 0.45, width: 40, height: 30)), with: .color(.white.opacity(0.2)), lineWidth: 2)
        }.accessibilityHidden(true)
    }
}
struct SectionTitle: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) { Text(title).font(.title3.bold()); Spacer(); if let subtitle { Text(subtitle).font(.caption.weight(.semibold)).foregroundStyle(Color.arenaMuted) } }.padding(.top, 8)
    }
}
struct Chips: View {
    let values: [String]
    @Binding var selection: String
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Button { selection = value } label: {
                        Text(value).font(.subheadline.weight(.semibold)).padding(.horizontal, 16).frame(minHeight: 44)
                            .background(selection == value ? Color.arenaBlue : .white, in: Capsule())
                            .foregroundStyle(selection == value ? .white : Color.arenaInk)
                            .overlay(Capsule().stroke(Color.arenaBlue.opacity(selection == value ? 0 : 0.12)))
                    }.accessibilityAddTraits(selection == value ? .isSelected : [])
                }
            }
        }
    }
}
struct SourceNote: View {
    @EnvironmentObject var store: FootballStore
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
            VStack(alignment: .leading, spacing: 3) {
                Text("Built-in demo season · November 2026").font(.caption.weight(.bold))
                Text("Illustrative fixtures, players and statistics. Available entirely offline.").font(.caption)
                Text("\(store.catalogue.source)\nEdition \(store.catalogue.updatedAt.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Locale(identifier: "en_GB"), timeZone: TimeZone(secondsFromGMT: 0)!))) UTC").font(.caption2)
            }
        }.foregroundStyle(Color.arenaMuted).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
    }
}
struct EmptyCard: View {
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) { Image(systemName: "soccerball").font(.largeTitle).foregroundStyle(Color.arenaBlue); Text(title).font(.headline); Text(message).font(.subheadline).foregroundStyle(Color.arenaMuted).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(.vertical, 24).card()
    }
}
struct MatchRow: View {
    @EnvironmentObject var store: FootballStore
    let match: Fixture
    var body: some View {
        NavigationLink(value: match) {
            VStack(spacing: 12) {
                HStack { Text(match.competition.uppercased()).font(.caption2.weight(.bold)); Spacer(); Text("\(match.day) Nov · \(match.status)").font(.caption.weight(.semibold)) }.foregroundStyle(Color.arenaMuted)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        team(match.home); team(match.away)
                    }
                    Spacer(minLength: 8)
                    if let h = match.homeGoals, let a = match.awayGoals {
                        VStack(spacing: 12) { Text(h.formatted(.number.locale(Locale(identifier: "en_GB")))); Text(a.formatted(.number.locale(Locale(identifier: "en_GB")))) }.font(.title3.bold()).monospacedDigit()
                    } else { Text(match.time).font(.title3.bold()).monospacedDigit() }
                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(Color.arenaMuted)
                }
            }.card().foregroundStyle(Color.arenaInk)
        }.buttonStyle(.plain).accessibilityIdentifier("match-\(match.id)")
    }
    func team(_ id: String) -> some View {
        HStack(spacing: 10) {
            Shield(club: store.catalogue.club(id), size: 24)
            Text(store.catalogue.club(id).name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
            if store.preferences.clubs.contains(id) { Image(systemName: "star.fill").foregroundStyle(Color.arenaYellow).font(.caption) }
        }
    }
}
