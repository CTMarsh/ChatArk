import SwiftUI

struct SignupView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var isValidPassword: Bool {
        password.count >= 8
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundStyle(NauticalTheme.ocean)

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
                        .background(NauticalTheme.ocean)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!passwordsMatch || !isValidPassword || email.isEmpty || authViewModel.isLoading)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Sign Up")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
