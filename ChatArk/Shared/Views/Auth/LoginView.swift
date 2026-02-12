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
                VStack(spacing: 32) {
                    // Logo
                    VStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 28))

                        Text("ChatArk")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
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
                                .font(.caption)
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
                            .background(NauticalTheme.ocean)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 24)

                    Divider()
                        .padding(.horizontal, 40)

                    Button {
                        showSignup = true
                    } label: {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
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
