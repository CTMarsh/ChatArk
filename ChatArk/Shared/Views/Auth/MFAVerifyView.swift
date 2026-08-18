import SwiftUI

struct MFAVerifyView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    let factorId: String
    @State private var code = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: ConstellationSpacing.gapSection) {
                Spacer()

                VStack(spacing: ConstellationSpacing.s1) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: ConstellationType.hero.size))
                        .foregroundStyle(ConstellationTheme.primary)

                    Text("Two-Factor Authentication")
                        .arkType(.lead)
                        .fontWeight(.bold)

                    Text("Enter the code from your authenticator app")
                        .arkType(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: ConstellationSpacing.gapStack) {
                    TextField("000000", text: $code)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.center)
                        .arkType(.stat, monospaced: true)
                        .frame(maxWidth: 200)

                    if let error = authViewModel.error {
                        Text(error)
                            .arkType(.cap)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task {
                            await authViewModel.verifyMFA(factorId: factorId, code: code)
                        }
                    } label: {
                        Group {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Verify")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ConstellationTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(code.count != 6 || authViewModel.isLoading)
                    .padding(.horizontal, ConstellationSpacing.gapPanel)

                    Button("Sign Out") {
                        Task { await authViewModel.signOut() }
                    }
                    .arkType(.body)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}

#if DEBUG
#Preview {
    MFAVerifyView(factorId: "preview-factor-id")
        .environment(AuthViewModel())
}
#endif
