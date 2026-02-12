import SwiftUI

/// Nautical color palette matching the ChatArk web application theme.
/// Primary: ocean blue, Accent: warm golden, Dark: deep navy.
enum NauticalTheme {
    // MARK: - Primary

    /// Ocean blue — primary brand color (#4A8BC2)
    static let ocean = Color(hex: "4A8BC2")

    /// Deep navy — dark text / dark mode emphasis (#1A2938)
    static let navy = Color(hex: "1A2938")

    // MARK: - Accent

    /// Warm golden — secondary accent, highlights (#D4A04A)
    static let golden = Color(hex: "D4A04A")

    // MARK: - Surfaces

    /// Deep sea — dark mode background (#1E2D3D)
    static let deepSea = Color(hex: "1E2D3D")

    /// Mist — light secondary background (#E8F1F8)
    static let mist = Color(hex: "E8F1F8")

    /// Shore — light border color (#D9E3ED)
    static let shore = Color(hex: "D9E3ED")

    // MARK: - Semantic

    /// Driftwood — muted foreground text (#5A7183)
    static let driftwood = Color(hex: "5A7183")

    /// Coral — destructive/error (#D03A3A)
    static let coral = Color(hex: "D03A3A")

    // MARK: - Accent Color Presets (for AppearanceSettingsView)

    static let accentPresets: [(hex: String, name: String)] = [
        ("#4A8BC2", "Ocean"),
        ("#1A2938", "Navy"),
        ("#D4A04A", "Golden"),
        ("#2BA89E", "Seafoam"),
        ("#D06050", "Coral"),
        ("#6B5B95", "Dusk"),
    ]

    /// Default accent hex string
    static let defaultAccentHex = "#4A8BC2"

    // MARK: - Avatar Palette

    /// Nautical-themed colors for fallback avatars
    static let avatarColors: [Color] = [
        Color(hex: "4A8BC2"),  // ocean blue
        Color(hex: "2BA89E"),  // seafoam teal
        Color(hex: "D4A04A"),  // warm golden
        Color(hex: "6B5B95"),  // dusk purple
        Color(hex: "D06050"),  // coral
        Color(hex: "3A6B8C"),  // deep water
        Color(hex: "7B9E6B"),  // sea moss
        Color(hex: "C47A5A"),  // driftwood
    ]
}
