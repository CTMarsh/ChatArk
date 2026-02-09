import Foundation
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

enum HapticManager {
    #if os(iOS)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func messageSent() {
        impact(.light)
    }

    static func reactionAdded() {
        impact(.medium)
    }

    static func error() {
        notification(.error)
    }
    #elseif os(watchOS)
    static func messageSent() {
        WKInterfaceDevice.current().play(.click)
    }

    static func reactionAdded() {
        WKInterfaceDevice.current().play(.success)
    }

    static func error() {
        WKInterfaceDevice.current().play(.failure)
    }
    #else
    // macOS - no haptics
    static func messageSent() {}
    static func reactionAdded() {}
    static func error() {}
    #endif
}
