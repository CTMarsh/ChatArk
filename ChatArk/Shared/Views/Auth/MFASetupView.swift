import SwiftUI

struct MFASetupView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var verificationCode = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(NauticalTheme.ocean)

                        Text("Set Up Two-Factor Authentication")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Scan the QR code with your authenticator app")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

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
                            VStack(spacing: 8) {
                                Text("Manual Entry Key:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let secret = authViewModel.mfaSecret {
                                    Text(secret)
                                        .font(.system(.body, design: .monospaced))
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
                    VStack(spacing: 12) {
                        Text("Enter the 6-digit code from your authenticator")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("000000", text: $verificationCode)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS) || os(visionOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.center)
                            .font(.title2.monospaced())
                            .frame(maxWidth: 200)

                        if let error = authViewModel.error {
                            Text(error)
                                .font(.caption)
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
                            .background(NauticalTheme.ocean)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(verificationCode.count != 6 || authViewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
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
