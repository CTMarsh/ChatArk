import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: ConstellationSpacing.gapPanel) {
                if sent {
                    VStack(spacing: ConstellationSpacing.gapInline) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: ConstellationType.hero.size))
                            .foregroundStyle(.green)

                        Text("Check Your Email")
                            .arkType(.lead)
                            .fontWeight(.bold)

                        Text("We've sent a password reset link to \(email)")
                            .arkType(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                    }
                } else {
                    VStack(spacing: ConstellationSpacing.gapInline) {
                        Image(systemName: "key.fill")
                            .font(.system(size: ConstellationType.hero.size))
                            .foregroundStyle(ConstellationTheme.primary)

                        Text("Reset Password")
                            .arkType(.lead)
                            .fontWeight(.bold)

                        Text("Enter your email and we'll send you a reset link")
                            .arkType(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: ConstellationSpacing.gapInline) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            #if os(iOS) || os(visionOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            #endif

                        if let error = authViewModel.error {
                            Text(error)
                                .arkType(.cap)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task {
                                await authViewModel.resetPassword(email: email)
                                sent = true
                            }
                        } label: {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Send Reset Link")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ConstellationTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(email.isEmpty || authViewModel.isLoading)
                    }
                    .padding(.horizontal, ConstellationSpacing.gapPanel)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ForgotPasswordView()
        .environment(AuthViewModel())
}
#endif
