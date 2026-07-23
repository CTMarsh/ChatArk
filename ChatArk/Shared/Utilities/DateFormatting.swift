import Foundation

enum DateFormatting {
    // Foundation date formatters are immutable after their configuration closure
    // runs and are documented thread-safe for concurrent formatting (reading), so
    // `nonisolated(unsafe)` is safe here — it silences Swift 6's non-Sendable
    // static-property diagnostic without adding per-call allocation.
    nonisolated(unsafe) private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    nonisolated(unsafe) private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    nonisolated(unsafe) private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    nonisolated(unsafe) private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    nonisolated(unsafe) private static let fullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func messageTime(_ date: Date?) -> String {
        guard let date else { return "" }
        return timeFormatter.string(from: date)
    }

    static func conversationDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: .now).day, daysAgo < 7 {
            return weekdayFormatter.string(from: date)
        } else {
            return dateFormatter.string(from: date)
        }
    }

    static func relative(_ date: Date?) -> String {
        guard let date else { return "" }
        return relativeFormatter.localizedString(for: date, relativeTo: .now)
    }

    static func full(_ date: Date?) -> String {
        guard let date else { return "" }
        return fullFormatter.string(from: date)
    }

    static func lastSeen(_ date: Date?) -> String {
        guard let date else { return "Never" }
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Last seen \(timeFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Last seen yesterday"
        } else {
            return "Last seen \(dateFormatter.string(from: date))"
        }
    }
}
