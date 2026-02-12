import Foundation
import SwiftUI
import Supabase

@MainActor
@Observable
final class SettingsViewModel {
    var preferences: UserPreferences?
    var isLoading = false
    var error: String?

    // Local state mirrors
    var theme: Theme = .system
    var uiScale: UIScale = .comfortable
    var fontSize: FontSize = .medium
    var accentColor: String = NauticalTheme.defaultAccentHex {
        didSet { _tintColor = Color(hex: accentColor) }
    }
    private(set) var _tintColor: Color = NauticalTheme.ocean
    var messageDensity: MessageDensity = .default
    var enterKeyBehavior: EnterKeyBehavior = .send
    var linkPreviewsEnabled = true
    var sendTypingIndicators = true
    var sendReadReceipts = true
    var emojiSkinTone: EmojiSkinTone = .default
    var desktopNotifications = true
    var soundNotifications = true
    var dndEnabled = false
    var dndStartTime = ""
    var dndEndTime = ""
    var showOnlineStatus = true
    var showReadReceipts = true
    var showTypingIndicator = true
    var reduceMotion = false
    var highContrast = false

    private let preferencesService: PreferencesService
    private var debounceTasks: [String: Task<Void, Never>] = [:]

    init(preferencesService: PreferencesService = PreferencesService()) {
        self.preferencesService = preferencesService
    }

    func loadPreferences() async {
        guard preferences == nil else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            var prefs = try await preferencesService.fetchPreferences()
            if prefs == nil {
                prefs = try await preferencesService.createDefaultPreferences()
            }
            preferences = prefs
            applyFromPreferences(prefs!)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func applyFromPreferences(_ prefs: UserPreferences) {
        theme = prefs.theme ?? .system
        uiScale = prefs.uiScale ?? .comfortable
        fontSize = prefs.fontSize ?? .medium
        accentColor = prefs.accentColor ?? NauticalTheme.defaultAccentHex
        messageDensity = prefs.messageDensity ?? .default
        enterKeyBehavior = prefs.enterKeyBehavior ?? .send
        linkPreviewsEnabled = prefs.linkPreviewsEnabled ?? true
        sendTypingIndicators = prefs.sendTypingIndicators ?? true
        sendReadReceipts = prefs.sendReadReceipts ?? true
        emojiSkinTone = prefs.emojiSkinTone ?? .default
        desktopNotifications = prefs.desktopNotifications ?? true
        soundNotifications = prefs.soundNotifications ?? true
        dndEnabled = prefs.dndEnabled ?? false
        dndStartTime = prefs.dndStartTime ?? ""
        dndEndTime = prefs.dndEndTime ?? ""
        showOnlineStatus = prefs.showOnlineStatus ?? true
        showReadReceipts = prefs.showReadReceipts ?? true
        showTypingIndicator = prefs.showTypingIndicator ?? true
        reduceMotion = prefs.reduceMotion ?? false
        highContrast = prefs.highContrast ?? false
    }

    // MARK: - Update (debounced)

    func updatePreference(key: PreferenceKey, value: AnyJSON) {
        let rawKey = key.rawValue
        debounceTasks[rawKey]?.cancel()
        debounceTasks[rawKey] = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                try await preferencesService.updatePreference(key: key, value: value)
            } catch {
                self.error = ErrorSanitizer.sanitize(error)
            }
        }
    }

    func updateTheme(_ newTheme: Theme) {
        theme = newTheme
        updatePreference(key: .theme, value: .string(newTheme.rawValue))
    }

    func updateFontSize(_ newSize: FontSize) {
        fontSize = newSize
        updatePreference(key: .fontSize, value: .string(newSize.rawValue))
    }

    func updateAccentColor(_ color: String) {
        accentColor = color
        updatePreference(key: .accentColor, value: .string(color))
        SharedDataWriter.shared.writeAccentColor(color)
    }

    func toggleDND(_ enabled: Bool) {
        dndEnabled = enabled
        updatePreference(key: .dndEnabled, value: .bool(enabled))
    }

    func toggleOnlineStatus(_ show: Bool) {
        showOnlineStatus = show
        updatePreference(key: .showOnlineStatus, value: .bool(show))
    }

    func toggleReadReceipts(_ show: Bool) {
        showReadReceipts = show
        updatePreference(key: .showReadReceipts, value: .bool(show))
    }

    func toggleTypingIndicator(_ show: Bool) {
        showTypingIndicator = show
        updatePreference(key: .showTypingIndicator, value: .bool(show))
    }

    func toggleReduceMotion(_ reduce: Bool) {
        reduceMotion = reduce
        updatePreference(key: .reduceMotion, value: .bool(reduce))
    }

    func toggleHighContrast(_ contrast: Bool) {
        highContrast = contrast
        updatePreference(key: .highContrast, value: .bool(contrast))
    }

    // MARK: - Color Scheme

    var colorScheme: ColorScheme? {
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
