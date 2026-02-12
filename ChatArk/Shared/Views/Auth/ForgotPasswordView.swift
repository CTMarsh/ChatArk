import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if sent {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green)

                        Text("Check Your Email")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("We've sent a password reset link to \(email)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(NauticalTheme.ocean)

                        Text("Reset Password")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Enter your email and we'll send you a reset link")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            #if os(iOS) || os(visionOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            #endif

                        if let error = authViewModel.error {
                            Text(error)
                                .font(.caption)
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
                            .background(NauticalTheme.ocean)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(email.isEmpty || authViewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
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
