import SwiftUI

struct MFASetupView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var verificationCode = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ConstellationSpacing.gapPanel) {
                    VStack(spacing: ConstellationSpacing.s1) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: ConstellationType.hero.size))
                            .foregroundStyle(ConstellationTheme.primary)

                        Text("Set Up Two-Factor Authentication")
                            .arkType(.lead)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Scan the QR code with your authenticator app")
                            .arkType(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, ConstellationSpacing.gapStack)

                    // QR Code
                    if let qrCode = authViewModel.mfaQrCode {
                        if let data = Data(base64Encoded: qrCode.replacingOccurrences(of: "data:image/svg+xml;base64,", with: "")) {
                            #if canImport(UIKit)
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .frame(width: 200, height: 200)
                            }
                            #elseif canImport(AppKit)
                            if let nsImage = NSImage(data: data) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .frame(width: 200, height: 200)
                            }
                            #endif
                        } else {
                            // Fallback: show secret key
                            VStack(spacing: ConstellationSpacing.s1) {
                                Text("Manual Entry Key:")
                                    .arkType(.cap)
                                    .foregroundStyle(.secondary)

                                if let secret = authViewModel.mfaSecret {
                                    Text(secret)
                                        .arkType(.body, monospaced: true)
                                        .padding()
                                        .background(Color.gray.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    } else {
                        Button("Generate QR Code") {
                            Task {
                                await authViewModel.enrollMFA()
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    // Verification
                    VStack(spacing: ConstellationSpacing.gapInline) {
                        Text("Enter the 6-digit code from your authenticator")
                            .arkType(.body)
                            .foregroundStyle(.secondary)

                        TextField("000000", text: $verificationCode)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS) || os(visionOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.center)
                            .arkType(.lead, monospaced: true)
                            .frame(maxWidth: 200)

                        if let error = authViewModel.error {
                            Text(error)
                                .arkType(.cap)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task {
                                await authViewModel.verifyMFAEnrollment(code: verificationCode)
                            }
                        } label: {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Verify & Continue")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ConstellationTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(verificationCode.count != 6 || authViewModel.isLoading)
                    }
                    .padding(.horizontal, ConstellationSpacing.gapPanel)
                }
            }
        }
        .task {
            if authViewModel.mfaQrCode == nil {
                await authViewModel.enrollMFA()
            }
        }
    }
}

#if DEBUG
#Preview {
    MFASetupView()
        .environment(AuthViewModel())
}
#endif
