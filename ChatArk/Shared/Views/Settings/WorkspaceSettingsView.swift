import SwiftUI
import Supabase

struct WorkspaceSettingsView: View {
    let workspaceId: UUID
    @State private var settings: WorkspaceSettings?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var error: String?

    private let workspaceService = WorkspaceService()

    var body: some View {
        Form {
            if isLoading {
                Section {
                    ProgressView()
                }
            } else if settings != nil {
                brandingSection
                businessHoursSection
                autoReplySection
                agentLimitsSection
                notificationSection
            }

            if let error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .arkType(.cap)
                }
            }
        }
        .navigationTitle("Workspace Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await saveSettings() }
                }
                .disabled(isSaving || settings == nil)
            }
        }
        .task {
            await loadSettings()
        }
    }

    // MARK: - Branding

    private var brandingSection: some View {
        Section {
            HStack {
                Text("Primary Color")
                Spacer()
                Circle()
                    .fill(Color(hex: settings?.defaultPrimaryColor ?? "#6366f1"))
                    .frame(width: 24, height: 24)
                TextField("#6366f1", text: Binding(
                    get: { settings?.defaultPrimaryColor ?? "#6366f1" },
                    set: { settings?.defaultPrimaryColor = $0 }
                ))
                .frame(width: 90)
                .arkType(.cap, monospaced: true)
                #if os(iOS) || os(visionOS)
                .textInputAutocapitalization(.never)
                #endif
            }

            VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                Text("Welcome Message")
                    .arkType(.cap)
                    .foregroundStyle(.secondary)
                TextField("Hi! How can we help you today?", text: Binding(
                    get: { settings?.defaultWelcomeMessage ?? "" },
                    set: { settings?.defaultWelcomeMessage = $0 }
                ), axis: .vertical)
                .lineLimit(2...4)
            }

            VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                Text("Offline Message")
                    .arkType(.cap)
                    .foregroundStyle(.secondary)
                TextField("We're currently offline...", text: Binding(
                    get: { settings?.defaultOfflineMessage ?? "" },
                    set: { settings?.defaultOfflineMessage = $0 }
                ), axis: .vertical)
                .lineLimit(2...4)
            }
        } header: {
            Text("Branding Defaults")
        } footer: {
            Text("These defaults are inherited by new widgets created in this workspace.")
        }
    }

    // MARK: - Business Hours

    private var businessHoursSection: some View {
        Section {
            Toggle("Enable Business Hours", isOn: Binding(
                get: { settings?.businessHoursEnabled ?? false },
                set: { settings?.businessHoursEnabled = $0 }
            ))

            if settings?.businessHoursEnabled == true {
                Picker("Timezone", selection: Binding(
                    get: { settings?.timezone ?? "UTC" },
                    set: { settings?.timezone = $0 }
                )) {
                    ForEach(Self.timezones, id: \.self) { tz in
                        Text(tz).tag(tz)
                    }
                }

                ForEach(Self.dayOrder, id: \.self) { day in
                    dayRow(day: day)
                }
            }
        } header: {
            Label("Business Hours", systemImage: "clock")
        }
    }

    private func dayRow(day: String) -> some View {
        let dayBinding = Binding<BusinessHourDay>(
            get: {
                settings?.businessHours?[day] ?? BusinessHourDay(start: "09:00", end: "17:00", enabled: false)
            },
            set: {
                if settings?.businessHours == nil {
                    settings?.businessHours = Self.defaultBusinessHours
                }
                settings?.businessHours?[day] = $0
            }
        )

        return HStack {
            Toggle(day.capitalized, isOn: dayBinding.enabled)
            if dayBinding.wrappedValue.enabled {
                Spacer()
                TextField("09:00", text: dayBinding.start)
                    .frame(width: 60)
                    .arkType(.cap, monospaced: true)
                Text("to")
                    .arkType(.cap)
                    .foregroundStyle(.secondary)
                TextField("17:00", text: dayBinding.end)
                    .frame(width: 60)
                    .arkType(.cap, monospaced: true)
            }
        }
    }

    // MARK: - Auto-Reply

    private var autoReplySection: some View {
        Section {
            Toggle("Enable Auto-Reply", isOn: Binding(
                get: { settings?.autoReplyEnabled ?? false },
                set: { settings?.autoReplyEnabled = $0 }
            ))

            if settings?.autoReplyEnabled == true {
                VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                    Text("Auto-Reply Message")
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                    TextField("Thanks for reaching out!...", text: Binding(
                        get: { settings?.autoReplyMessage ?? "" },
                        set: { settings?.autoReplyMessage = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                }
            }
        } header: {
            Label("Auto-Reply", systemImage: "text.bubble")
        }
    }

    // MARK: - Agent Limits

    private var agentLimitsSection: some View {
        Section("Agent Limits") {
            HStack {
                Text("Max Conversations per Agent")
                Spacer()
                TextField("10", value: Binding(
                    get: { settings?.maxConversationsPerAgent ?? 10 },
                    set: { settings?.maxConversationsPerAgent = $0 }
                ), format: .number)
                .frame(width: 60)
                #if os(iOS) || os(visionOS)
                .keyboardType(.numberPad)
                #endif
                .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Notification Policies

    private var notificationSection: some View {
        Section {
            Toggle("Notify on New Conversations", isOn: Binding(
                get: { settings?.notifyOnNewConversation ?? true },
                set: { settings?.notifyOnNewConversation = $0 }
            ))

            Toggle("Unassigned Timeout Alert", isOn: Binding(
                get: { settings?.notifyOnUnassignedTimeout ?? false },
                set: { settings?.notifyOnUnassignedTimeout = $0 }
            ))

            if settings?.notifyOnUnassignedTimeout == true {
                HStack {
                    Text("Timeout (minutes)")
                    Spacer()
                    TextField("5", value: Binding(
                        get: { settings?.unassignedTimeoutMinutes ?? 5 },
                        set: { settings?.unassignedTimeoutMinutes = $0 }
                    ), format: .number)
                    .frame(width: 60)
                    #if os(iOS) || os(visionOS)
                    .keyboardType(.numberPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                }
            }
        } header: {
            Label("Notification Policies", systemImage: "bell")
        }
    }

    // MARK: - Data

    private func loadSettings() async {
        isLoading = true
        defer { isLoading = false }
        do {
            settings = try await workspaceService.fetchWorkspaceSettings(workspaceId: workspaceId)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func saveSettings() async {
        guard let settings else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            var updates: [String: AnyJSON] = [
                "default_primary_color": .string(settings.defaultPrimaryColor ?? "#6366f1"),
                "default_welcome_message": .string(settings.defaultWelcomeMessage ?? ""),
                "default_offline_message": .string(settings.defaultOfflineMessage ?? ""),
                "business_hours_enabled": .bool(settings.businessHoursEnabled),
                "timezone": .string(settings.timezone ?? "UTC"),
                "auto_reply_enabled": .bool(settings.autoReplyEnabled),
                "auto_reply_message": .string(settings.autoReplyMessage ?? ""),
                "notify_on_new_conversation": .bool(settings.notifyOnNewConversation),
                "notify_on_unassigned_timeout": .bool(settings.notifyOnUnassignedTimeout),
            ]

            if let maxConv = settings.maxConversationsPerAgent {
                updates["max_conversations_per_agent"] = .string(String(maxConv))
            }
            if let timeout = settings.unassignedTimeoutMinutes {
                updates["unassigned_timeout_minutes"] = .string(String(timeout))
            }

            if let hours = settings.businessHours {
                var hoursDict: [String: AnyJSON] = [:]
                for (day, dayInfo) in hours {
                    hoursDict[day] = .object([
                        "start": .string(dayInfo.start),
                        "end": .string(dayInfo.end),
                        "enabled": .bool(dayInfo.enabled),
                    ])
                }
                updates["business_hours"] = .object(hoursDict)
            }

            try await workspaceService.updateWorkspaceSettings(workspaceId: workspaceId, updates: updates)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Constants

    static let timezones = [
        "UTC", "America/New_York", "America/Chicago", "America/Denver",
        "America/Los_Angeles", "Europe/London", "Europe/Paris",
        "Asia/Tokyo", "Asia/Shanghai", "Australia/Sydney",
    ]

    static let dayOrder = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

    static let defaultBusinessHours: [String: BusinessHourDay] = Dictionary(
        uniqueKeysWithValues: dayOrder.map { day in
            let isWeekday = !["saturday", "sunday"].contains(day)
            return (day, BusinessHourDay(start: "09:00", end: "17:00", enabled: isWeekday))
        }
    )
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkspaceSettingsView(workspaceId: UUID())
    }
}
#endif
