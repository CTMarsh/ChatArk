import SwiftUI

struct SignupView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var signupsDisabled = false
    @State private var checkingSignups = true

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var isValidPassword: Bool {
        password.count >= 8
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if checkingSignups {
                    ProgressView("Checking availability...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                } else if signupsDisabled {
                    signupsDisabledContent
                } else {
                    signupFormContent
                }
            }
        }
        .navigationTitle("Sign Up")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            let allowed = await authViewModel.checkSignupsAllowed()
            signupsDisabled = !allowed
            checkingSignups = false
        }
    }

    private var signupsDisabledContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.slash")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("Signups Disabled")
                .font(.title)
                .fontWeight(.bold)

            Text("New account registration is currently unavailable. Please contact your administrator for access.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 40)
    }

    private var signupFormContent: some View {
        Group {
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(ConstellationTheme.primary)

                Text("Create Account")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.top, 20)

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    #if os(iOS) || os(visionOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()

                SecureField("Password (min 8 characters)", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let error = authViewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        await authViewModel.signUp(email: email, password: password)
                    }
                } label: {
                    Group {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ConstellationTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!passwordsMatch || !isValidPassword || email.isEmpty || authViewModel.isLoading)
            }
            .padding(.horizontal, 24)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SignupView()
    }
    .environment(AuthViewModel())
}
#endif
