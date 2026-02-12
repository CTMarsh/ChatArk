import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        let r = Double((color >> 16) & 0xFF) / 255.0
        let g = Double((color >> 8) & 0xFF) / 255.0
        let b = Double(color & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
