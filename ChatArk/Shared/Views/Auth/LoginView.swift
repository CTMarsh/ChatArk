import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ConstellationSpacing.gapSection) {
                    // Logo
                    VStack(spacing: ConstellationSpacing.s1) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 28))

                        Text("ChatArk")
                            .arkType(.stat)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .arkType(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, ConstellationSpacing.gapSection)

                    // Form
                    VStack(spacing: ConstellationSpacing.gapStack) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            #if os(iOS) || os(visionOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)

                        if let error = authViewModel.error {
                            Text(error)
                                .arkType(.cap)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        } label: {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ConstellationTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .arkType(.body)
                    }
                    .padding(.horizontal, ConstellationSpacing.gapPanel)

                    Divider()
                        .padding(.horizontal, ConstellationSpacing.gapSection)

                    Button {
                        showSignup = true
                    } label: {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                        .arkType(.body)
                    }

                    Spacer().frame(height: 24)

                    Text("v\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                        .arkType(.cap)
                        .foregroundStyle(.quaternary)
                }
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

#if DEBUG
#Preview {
    LoginView()
        .environment(AuthViewModel())
}
#endif
