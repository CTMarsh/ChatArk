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

// MARK: - Type Scale

/// The six Constellation type roles — and only six. Mirrors the
/// `--ark-t-*` / `--ark-lh-*` / `--ark-ls-*` custom properties shipped in
/// `@noahsark/constellation@0.2.0`, so the iOS/macOS/watchOS clients render the
/// same ramp as the web estate.
///
/// Snap every text size to the nearest role. Never introduce a seventh.
///
/// Apply with the `arkType(_:)` view modifier, which sets the font, the
/// letter-spacing and the line-spacing together — they are a matched set and
/// must not be used apart:
///
/// ```swift
/// Text("Signal lost").arkType(.cap)
/// ```
enum ConstellationType: CaseIterable, Sendable {
    /// 11pt — uppercase mono chrome: labels, keycaps, axis ticks.
    case micro
    /// 12.5pt — captions, timestamps, secondary metadata.
    case cap
    /// 15pt — DEFAULT. Every readable string.
    case body
    /// 18pt — lead paragraph, greeting, panel intro.
    case lead
    /// 30pt — stat-tile numbers.
    case stat
    /// 42pt — the one number or heading that must carry.
    case hero

    /// Point size (`--ark-t-*`).
    var size: CGFloat {
        switch self {
        case .micro: 11
        case .cap: 12.5
        case .body: 15
        case .lead: 18
        case .stat: 30
        case .hero: 42
        }
    }

    /// Line-height *multiplier* (`--ark-lh-*`).
    var lineHeight: CGFloat {
        switch self {
        case .micro: 1.2
        case .cap: 1.4
        case .body: 1.5
        case .lead: 1.45
        case .stat: 1.1
        case .hero: 1.05
        }
    }

    /// Letter-spacing in em (`--ark-ls-*`).
    var letterSpacingEm: CGFloat {
        switch self {
        case .micro: 0.12
        case .cap: 0.01
        case .body: 0
        case .lead: -0.01
        case .stat: -0.02
        case .hero: -0.04
        }
    }

    /// Letter-spacing converted to points for SwiftUI's `tracking(_:)`,
    /// which takes an absolute value rather than an em fraction.
    var tracking: CGFloat { size * letterSpacingEm }

    /// SwiftUI's `lineSpacing(_:)` is *additional* leading on top of the font's
    /// intrinsic line height, not a multiplier. San Francisco's intrinsic line
    /// height is ~1.2x the point size, so the extra leading needed to reach the
    /// role's target multiple is `size * (lineHeight - 1.2)`. Roles at or below
    /// 1.2 (`.micro`, `.stat`, `.hero`) therefore add nothing — SwiftUI cannot
    /// express negative leading here, and tightening those would need
    /// `NSAttributedString`. Documented rather than faked.
    var lineSpacing: CGFloat { max(0, size * (lineHeight - 1.2)) }

    /// The role's font. `Font.system(size:)` still scales with Dynamic Type in
    /// SwiftUI, so adopting the ramp does not cost accessibility.
    var font: Font { .system(size: size) }
}

extension View {
    /// Apply a Constellation type role: font, letter-spacing and line-spacing
    /// as one matched set.
    ///
    /// Weight is deliberately not part of a role — compose it separately with
    /// `.fontWeight(_:)` so the ramp stays six sizes rather than six times N.
    ///
    /// - Parameter monospaced: use the monospaced face at the same role size,
    ///   for codes, IDs and TOTP digits. Tracking is dropped, because a
    ///   monospaced face already carries its own fixed advance width.
    ///
    /// `nonisolated` because a `View` extension otherwise inherits SwiftUI's
    /// `@MainActor` isolation, which makes this unusable from the nonisolated
    /// `@ViewBuilder` closures some components take (e.g. `PhotosPicker`'s
    /// label) under Swift 6 strict concurrency. The body only composes
    /// nonisolated view modifiers, so opting out is safe.
    nonisolated func arkType(_ role: ConstellationType, monospaced: Bool = false) -> some View {
        self
            .font(monospaced ? role.font.monospaced() : role.font)
            .tracking(monospaced ? 0 : role.tracking)
            .lineSpacing(role.lineSpacing)
    }
}

// MARK: - Spacing Scale

/// The Constellation 6px spacing grid (`--ark-sp-*`) plus the named rhythm
/// roles (`--ark-gap-*`). Every padding, margin and stack spacing snaps to a
/// value here — nothing sits off-grid.
///
/// Prefer the named roles at call sites; they say what the gap *is* rather than
/// how big it happens to be.
enum ConstellationSpacing {
    /// 6pt
    static let s1: CGFloat = 6
    /// 12pt
    static let s2: CGFloat = 12
    /// 18pt
    static let s3: CGFloat = 18
    /// 24pt
    static let s4: CGFloat = 24
    /// 30pt
    static let s5: CGFloat = 30
    /// 36pt
    static let s6: CGFloat = 36
    /// 60pt
    static let s7: CGFloat = 60
    /// 96pt
    static let s8: CGFloat = 96
    /// 120pt
    static let s9: CGFloat = 120

    // MARK: Named rhythm roles

    /// 12pt — between items on the same line (icon to label, chip to chip).
    static let gapInline: CGFloat = s2
    /// 18pt — between stacked items inside one panel.
    static let gapStack: CGFloat = s3
    /// 24pt — a panel's own inset.
    static let gapPanel: CGFloat = s4
    /// 36pt — the MACRO step, between panels and regions. This is the one that
    /// gives a dense screen room to breathe; reach for it at region boundaries.
    static let gapSection: CGFloat = s6
}
