import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: ConstellationSpacing.s1) {
            Image(systemName: "wifi.slash")
                .arkType(.cap)
            Text("No internet connection")
                .arkType(.cap)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, ConstellationSpacing.s1)
        .background(.red.opacity(0.85))
    }
}
