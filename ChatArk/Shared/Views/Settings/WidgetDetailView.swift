import SwiftUI
import Supabase

struct WidgetDetailView: View {
    @State var widget: WorkspaceWidget
    let workspaceId: UUID
    @State private var isSaving = false
    @State private var error: String?
    @State private var copiedToken = false
    @State private var showRegenerateConfirm = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    private let workspaceService = WorkspaceService()

    var body: some View {
        Form {
            embedSection
            generalSection
            messagesSection
            visitorSection
            securitySection
            dangerSection

            if let error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .arkType(.cap)
                }
            }
        }
        .navigationTitle(widget.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await saveWidget() }
                }
                .disabled(isSaving)
            }
        }
        .confirmationDialog("Regenerate Token", isPresented: $showRegenerateConfirm, titleVisibility: .visible) {
            Button("Regenerate", role: .destructive) {
                Task { await regenerateToken() }
            }
        } message: {
            Text("This will invalidate the current embed token. Existing embeds will stop working.")
        }
        .confirmationDialog("Delete Widget", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await deleteWidget() }
            }
        } message: {
            Text("This will permanently delete the widget and invalidate its embed token.")
        }
    }

    // MARK: - Embed Token

    private var embedSection: some View {
        Section("Embed Token") {
            if let token = widget.embedToken {
                HStack {
                    Text(String(token.prefix(20)) + "...")
                        .arkType(.cap, monospaced: true)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        #if os(iOS) || os(visionOS)
                        UIPasteboard.general.string = token
                        #elseif os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(token, forType: .string)
                        #endif
                        copiedToken = true
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            copiedToken = false
                        }
                    } label: {
                        Text(copiedToken ? "Copied" : "Copy")
                            .arkType(.cap)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button("Regenerate Token") {
                    showRegenerateConfirm = true
                }
                .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - General Settings

    private var generalSection: some View {
        Section("General") {
            TextField("Widget Name", text: $widget.name)

            Picker("Position", selection: Binding(
                get: { widget.position ?? "bottom-right" },
                set: { widget.position = $0 }
            )) {
                Text("Bottom Right").tag("bottom-right")
                Text("Bottom Left").tag("bottom-left")
            }

            HStack {
                Text("Primary Color")
                Spacer()
                Circle()
                    .fill(Color(hex: widget.primaryColor ?? "#6366f1"))
                    .frame(width: 24, height: 24)
                TextField("#6366f1", text: Binding(
                    get: { widget.primaryColor ?? "#6366f1" },
                    set: { widget.primaryColor = $0 }
                ))
                .frame(width: 90)
                .arkType(.cap, monospaced: true)
                #if os(iOS) || os(visionOS)
                .textInputAutocapitalization(.never)
                #endif
            }

            Toggle("Active", isOn: Binding(
                get: { widget.isActive ?? true },
                set: { widget.isActive = $0 }
            ))
        }
    }

    // MARK: - Messages

    private var messagesSection: some View {
        Section("Messages") {
            VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                Text("Welcome Message")
                    .arkType(.cap)
                    .foregroundStyle(.secondary)
                TextField("Hi! How can we help you today?", text: Binding(
                    get: { widget.welcomeMessage ?? "" },
                    set: { widget.welcomeMessage = $0 }
                ), axis: .vertical)
                .lineLimit(2...4)
            }

            VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                Text("Offline Message")
                    .arkType(.cap)
                    .foregroundStyle(.secondary)
                TextField("We're currently offline...", text: Binding(
                    get: { widget.offlineMessage ?? "" },
                    set: { widget.offlineMessage = $0 }
                ), axis: .vertical)
                .lineLimit(2...4)
            }
        }
    }

    // MARK: - Visitor Settings

    private var visitorSection: some View {
        Section("Visitor Settings") {
            Toggle("Require Email", isOn: Binding(
                get: { widget.requireEmail ?? false },
                set: { widget.requireEmail = $0 }
            ))

            Toggle("Collect Name", isOn: Binding(
                get: { widget.collectName ?? false },
                set: { widget.collectName = $0 }
            ))
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                Text("Allowed Origins")
                    .arkType(.cap)
                    .foregroundStyle(.secondary)
                TextField("e.g., https://example.com (one per line)", text: Binding(
                    get: { widget.allowedOrigins?.joined(separator: "\n") ?? "" },
                    set: {
                        widget.allowedOrigins = $0.isEmpty ? nil : $0.components(separatedBy: "\n")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    }
                ), axis: .vertical)
                .lineLimit(2...4)
                .arkType(.cap, monospaced: true)
            }
        } header: {
            Text("Security")
        } footer: {
            Text("Leave empty to allow all origins. Add specific domains to restrict embedding.")
        }
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete Widget")
            }
        }
    }

    // MARK: - Actions

    private func saveWidget() async {
        isSaving = true
        defer { isSaving = false }
        do {
            var updates: [String: AnyJSON] = [
                "name": .string(widget.name),
                "position": .string(widget.position ?? "bottom-right"),
                "primary_color": .string(widget.primaryColor ?? "#6366f1"),
                "is_active": .bool(widget.isActive ?? true),
                "require_email": .bool(widget.requireEmail ?? false),
                "collect_name": .bool(widget.collectName ?? false),
            ]
            if let msg = widget.welcomeMessage, !msg.isEmpty {
                updates["welcome_message"] = .string(msg)
            }
            if let msg = widget.offlineMessage, !msg.isEmpty {
                updates["offline_message"] = .string(msg)
            }
            if let origins = widget.allowedOrigins {
                updates["allowed_origins"] = .array(origins.map { .string($0) })
            }
            try await workspaceService.updateWidget(id: widget.id, updates: updates)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func regenerateToken() async {
        do {
            let newToken = try await workspaceService.regenerateWidgetToken(id: widget.id)
            widget.embedToken = newToken
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func deleteWidget() async {
        do {
            try await workspaceService.deleteWidget(id: widget.id)
            dismiss()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WidgetDetailView(
            widget: WorkspaceWidget(
                id: UUID(),
                workspaceId: UUID(),
                name: "Test Widget",
                embedToken: "abc123def456ghi789",
                primaryColor: "#6366f1",
                position: "bottom-right",
                isActive: true
            ),
            workspaceId: UUID()
        )
    }
}
#endif
