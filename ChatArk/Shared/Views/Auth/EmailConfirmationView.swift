import SwiftUI

struct EmailConfirmationView: View {
    let email: String
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.badge")
                .font(.system(size: 60))
                .foregroundStyle(NauticalTheme.ocean)

            Text("Check Your Email")
                .font(.title)
                .fontWeight(.bold)

            Text("We sent a confirmation link to:")
                .foregroundStyle(.secondary)

            Text(email)
                .fontWeight(.semibold)

            Text("Tap the link in the email to verify your account, then come back here to sign in.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button {
                authViewModel.state = .unauthenticated
            } label: {
                Text("Back to Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(NauticalTheme.ocean)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

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
