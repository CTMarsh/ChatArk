import SwiftUI

/// Constellation color palette matching the Noah's Ark design system used across
/// every project in the estate (see `DESIGN-SYSTEM.md`). Primary: signal blue,
/// accents: cyan + amber, ground: deep navy.
enum ConstellationTheme {
    // MARK: - Primary

    /// Signal blue — primary brand color (#2F8FFF)
    static let primary = Color(hex: "2F8FFF")

    /// Signal blue bright — hover / emphasis (#58B0FF)
    static let primaryBright = Color(hex: "58B0FF")

    /// Deep navy — app background (#0A0F1C)
    static let navy = Color(hex: "0A0F1C")

    // MARK: - Accent

    /// Cyan — secondary accent, data viz, glows (#33D6E6)
    static let cyan = Color(hex: "33D6E6")

    /// Amber — warm highlight, used sparingly (#F4A83A)
    static let amber = Color(hex: "F4A83A")

    /// Amber soft — amber hover (#FFC879)
    static let amberSoft = Color(hex: "FFC879")

    // MARK: - Surfaces

    /// Void — deepest background, behind hero art (#05070E)
    static let void = Color(hex: "05070E")

    /// Surface — cards, panels (#111A2D)
    static let surface = Color(hex: "111A2D")

    /// Surface secondary — raised surfaces, inputs, hover (#16223A)
    static let surfaceSecondary = Color(hex: "16223A")

    /// Line — borders, dividers (#1F2F4A)
    static let line = Color(hex: "1F2F4A")

    // MARK: - Ink

    /// Ink — primary text on dark surfaces (#E8EEF8)
    static let ink = Color(hex: "E8EEF8")

    /// Ink muted — secondary text (#9FB0C8)
    static let inkMuted = Color(hex: "9FB0C8")

    /// Ink subtle — captions, disabled (#64768F)
    static let inkSubtle = Color(hex: "64768F")

    // MARK: - Semantic

    /// Good — success state (#35D6A0)
    static let good = Color(hex: "35D6A0")

    /// Warn — warning state (#F4A83A)
    static let warn = Color(hex: "F4A83A")

    /// Critical — destructive/error (#FF5D6C)
    static let critical = Color(hex: "FF5D6C")

    // MARK: - Accent Color Presets (for AppearanceSettingsView)

    static let accentPresets: [(hex: String, name: String)] = [
        ("#2F8FFF", "Signal"),
        ("#33D6E6", "Cyan"),
        ("#F4A83A", "Amber"),
        ("#35D6A0", "Aurora"),
        ("#FF5D6C", "Coral"),
        ("#6B5B95", "Dusk"),
    ]

    /// Default accent hex string
    static let defaultAccentHex = "#2F8FFF"

    // MARK: - Avatar Palette

    /// Constellation-themed colors for fallback avatars
    static let avatarColors: [Color] = [
        Color(hex: "2F8FFF"),  // signal blue
        Color(hex: "33D6E6"),  // cyan
        Color(hex: "F4A83A"),  // amber
        Color(hex: "35D6A0"),  // aurora green
        Color(hex: "6B5B95"),  // dusk violet
        Color(hex: "58B0FF"),  // signal blue bright
        Color(hex: "FF5D6C"),  // coral
        Color(hex: "FFC879"),  // amber soft
    ]
}
