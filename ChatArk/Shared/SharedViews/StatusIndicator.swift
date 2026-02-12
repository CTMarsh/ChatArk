import SwiftUI

struct StatusIndicator: View {
    let status: UserStatus
    var size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .strokeBorder(.background, lineWidth: 2)
            }
            .accessibilityLabel("Status: \(status.rawValue)")
    }

    private var statusColor: Color {
        switch status {
        case .online: .green
        case .away: .yellow
        case .dnd: .red
        case .offline: .gray
        case .suspended: Color(red: 0.7, green: 0.1, blue: 0.1)
        }
    }
}

#if DEBUG
#Preview("All statuses") {
    HStack(spacing: 16) {
        ForEach(UserStatus.allCases, id: \.self) { status in
            VStack {
                StatusIndicator(status: status, size: 16)
                Text(status.rawValue)
                    .font(.caption2)
            }
        }
    }
    .padding()
}
#endif
