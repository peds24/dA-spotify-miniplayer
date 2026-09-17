import SwiftUI

struct HeartButton: View {
    let isLiked: Bool?
    let action: () -> Void
    @Environment(\.playerTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: isLiked == true ? "heart.fill" : "heart")
                .foregroundColor(isLiked == true ? theme.accent : theme.inkDim)
        }
        .buttonStyle(.plain)
        .opacity(isLiked == nil ? 0.4 : 1.0)
        .disabled(isLiked == nil)
    }
}
