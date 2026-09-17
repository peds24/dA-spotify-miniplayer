import SwiftUI

/// Renders `text` as a static, truncated line when it fits the available
/// width — identical to a plain `Text(...).lineLimit(1)`. When it doesn't
/// fit, it instead scrolls the full title left in a continuous, seamless
/// loop (two copies of the text placed back to back) so the whole title
/// eventually passes by.
struct MarqueeText: View {
    let text: String
    var font: Font
    var color: Color
    var height: CGFloat = 16

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var animate = false

    private static let gap: CGFloat = 24
    /// Points per second the marquee scrolls at.
    private static let speed: CGFloat = 30

    var body: some View {
        GeometryReader { proxy in
            content
                .onAppear { containerWidth = proxy.size.width }
                .onChange(of: proxy.size.width) { containerWidth = $0 }
        }
        .frame(height: height)
        .clipped()
        .background(widthMeasurement)
        // Restart the loop from the beginning whenever the title (or
        // whether it now overflows) changes, instead of jumping mid-loop.
        .task(id: TaskKey(text: text, overflowing: isOverflowing)) {
            animate = false
            guard isOverflowing else { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
            animate = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if isOverflowing {
            HStack(spacing: Self.gap) {
                Text(text).fixedSize()
                Text(text).fixedSize()
            }
            .font(font)
            .foregroundColor(color)
            .offset(x: animate ? -(textWidth + Self.gap) : 0)
            .animation(
                .linear(duration: Double(textWidth / Self.speed)).repeatForever(autoreverses: false),
                value: animate
            )
        } else {
            Text(text)
                .font(font)
                .foregroundColor(color)
                .lineLimit(1)
        }
    }

    private var isOverflowing: Bool {
        textWidth > 0 && containerWidth > 0 && textWidth > containerWidth
    }

    /// Measures the full, unwrapped width of `text` in `font` by rendering
    /// it off-screen and reporting its size back through a preference.
    private var widthMeasurement: some View {
        Text(text)
            .font(font)
            .fixedSize()
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: TextWidthKey.self, value: geo.size.width)
                }
            )
            .hidden()
            .onPreferenceChange(TextWidthKey.self) { textWidth = $0 }
    }

    private struct TaskKey: Equatable {
        let text: String
        let overflowing: Bool
    }
}

private struct TextWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
