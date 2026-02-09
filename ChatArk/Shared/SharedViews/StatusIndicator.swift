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
    }

    private var statusColor: Color {
        switch status {
        case .online: .green
        case .away: .yellow
        case .dnd: .red
        case .offline: .gray
        }
    }
}
