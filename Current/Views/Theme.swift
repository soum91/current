import SwiftUI

enum Theme {
    static let download = Color(red: 0.38, green: 0.91, blue: 0.78)
    static let upload = Color(red: 1.00, green: 0.66, blue: 0.46)
    static let bgTop = Color(red: 0.05, green: 0.08, blue: 0.10)
    static let bgBottom = Color(red: 0.01, green: 0.02, blue: 0.03)
    static let card = Color.white.opacity(0.06)
    static let stroke = Color.white.opacity(0.09)

    static var background: some View {
        ZStack {
            LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [download.opacity(0.17), .clear], center: .topLeading, startRadius: 10, endRadius: 410)
            RadialGradient(colors: [upload.opacity(0.09), .clear], center: .bottomTrailing, startRadius: 10, endRadius: 440)
        }
        .ignoresSafeArea()
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(Theme.stroke))
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(.white.opacity(0.48))
    }
}
