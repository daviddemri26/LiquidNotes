import SwiftUI

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(LNTheme.Spacing.medium)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: LNTheme.Radius.card, style: .continuous))
    }
}
