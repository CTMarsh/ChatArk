#if os(watchOS)
import SwiftUI

struct WatchStatusView: View {
    @State private var currentStatus: UserStatus = .online
    private let presenceService = PresenceService()

    var body: some View {
        List {
            ForEach(UserStatus.allCases.filter { $0 != .suspended }, id: \.self) { status in
                Button {
                    Task {
                        try? await presenceService.updateStatus(status)
                        currentStatus = status
                    }
                } label: {
                    HStack {
                        StatusIndicator(status: status, size: 10)
                        Text(status.rawValue.capitalized)
                            .font(.caption)
                        Spacer()
                        if status == currentStatus {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(NauticalTheme.ocean)
                        }
                    }
                }
            }
        }
        .navigationTitle("Status")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchStatusView()
    }
}
#endif
#endif
