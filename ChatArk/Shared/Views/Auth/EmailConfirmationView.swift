import SwiftUI

struct EmailConfirmationView: View {
    let email: String
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: ConstellationSpacing.gapPanel) {
            Spacer()

            Image(systemName: "envelope.badge")
                .font(.system(size: ConstellationType.hero.size))
                .foregroundStyle(ConstellationTheme.primary)

            Text("Check Your Email")
                .arkType(.stat)
                .fontWeight(.bold)

            Text("We sent a confirmation link to:")
                .foregroundStyle(.secondary)

            Text(email)
                .fontWeight(.semibold)

            Text("Tap the link in the email to verify your account, then come back here to sign in.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, ConstellationSpacing.gapSection)

            Button {
                authViewModel.state = .unauthenticated
            } label: {
                Text("Back to Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ConstellationTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, ConstellationSpacing.gapPanel)
            .padding(.top, ConstellationSpacing.s1)

            Spacer()
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    EmailConfirmationView(email: "test@example.com")
        .environment(AuthViewModel())
}
#endif
