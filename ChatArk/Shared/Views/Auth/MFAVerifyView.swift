import SwiftUI

struct MFAVerifyView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    let factorId: String
    @State private var code = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(NauticalTheme.ocean)

                    Text("Two-Factor Authentication")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter the code from your authenticator app")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    TextField("000000", text: $code)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS) || os(visionOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.center)
                        .font(.title.monospaced())
                        .frame(maxWidth: 200)

                    if let error = authViewModel.error {
                        Text(error)
                            .font(.caption)
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
                        .background(NauticalTheme.ocean)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(code.count != 6 || authViewModel.isLoading)
                    .padding(.horizontal, 24)

                    Button("Sign Out") {
                        Task { await authViewModel.signOut() }
                    }
                    .font(.subheadline)
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
