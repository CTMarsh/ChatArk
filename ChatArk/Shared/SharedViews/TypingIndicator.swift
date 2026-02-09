import SwiftUI

struct TypingIndicator: View {
    let userNames: [String]
    @State private var animationPhase = 0

    var body: some View {
        if !userNames.isEmpty {
            HStack(spacing: 4) {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.secondary)
                            .frame(width: 6, height: 6)
                            .offset(y: animationPhase == index ? -4 : 0)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(typingText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                    animationPhase = (animationPhase + 1) % 3
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
