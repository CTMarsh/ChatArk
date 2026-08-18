import SwiftUI

struct TypingIndicator: View {
    let userNames: [String]
    @State private var animationPhase = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !userNames.isEmpty {
            HStack(spacing: 4) {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.secondary)
                            .frame(width: 6, height: 6)
                            .offset(y: reduceMotion ? 0 : (animationPhase == index ? -4 : 0))
                            .opacity(reduceMotion ? (index == animationPhase ? 1.0 : 0.4) : 1.0)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(typingText)
                    .arkType(.cap)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(typingText)
            .onAppear {
                if reduceMotion {
                    // Use timer-based phase change without animation
                    Task {
                        while !Task.isCancelled {
                            try? await Task.sleep(for: .milliseconds(600))
                            animationPhase = (animationPhase + 1) % 3
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                        animationPhase = (animationPhase + 1) % 3
                    }
                }
            }
        }
    }

    private var typingText: String {
        switch userNames.count {
        case 1: return "\(userNames[0]) is typing..."
        case 2: return "\(userNames[0]) and \(userNames[1]) are typing..."
        default: return "Several people are typing..."
        }
    }
}

#if DEBUG
#Preview("Single user") {
    TypingIndicator(userNames: ["Alice"])
}

#Preview("Multiple users") {
    TypingIndicator(userNames: ["Alice", "Bob"])
}
#endif
