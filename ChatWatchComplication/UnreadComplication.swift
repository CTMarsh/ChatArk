import WidgetKit
import SwiftUI

// MARK: - Shared Data Reader (watch-local)

enum WatchSharedData {
    private static let suiteName = "group.com.chrismarsh.chatark"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func unreadCount() -> Int {
        defaults?.integer(forKey: "watch_unread_count") ?? 0
    }

    static func recentNames() -> [String] {
        (defaults?.stringArray(forKey: "watch_recent_names")) ?? []
    }

    static func lastSyncTimestamp() -> Date? {
        guard let interval = defaults?.double(forKey: "watch_last_sync"), interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    static var isStale: Bool {
        guard let lastSync = lastSyncTimestamp() else { return true }
        return Date().timeIntervalSince(lastSync) > 3600
    }
}

// MARK: - Timeline Entry

struct WatchUnreadCountEntry: TimelineEntry {
    let date: Date
    let unreadCount: Int
    let recentNames: [String]
    let isStale: Bool
}

// MARK: - Timeline Provider

struct WatchUnreadCountProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchUnreadCountEntry {
        WatchUnreadCountEntry(date: .now, unreadCount: 0, recentNames: [], isStale: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchUnreadCountEntry) -> Void) {
        let entry = WatchUnreadCountEntry(
            date: .now,
            unreadCount: WatchSharedData.unreadCount(),
            recentNames: WatchSharedData.recentNames(),
            isStale: WatchSharedData.isStale
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchUnreadCountEntry>) -> Void) {
        let entry = WatchUnreadCountEntry(
            date: .now,
            unreadCount: WatchSharedData.unreadCount(),
            recentNames: WatchSharedData.recentNames(),
            isStale: WatchSharedData.isStale
        )
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
        completion(timeline)
    }
}

// MARK: - Complication Views

struct WatchCircularView: View {
    let entry: WatchUnreadCountEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "bubble.left.fill")
                    .font(.caption2)
                Text("\(entry.unreadCount)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .opacity(entry.isStale ? 0.5 : 1.0)
        }
    }
}

struct WatchRectangularView: View {
    let entry: WatchUnreadCountEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.caption2)
                Text("ChatArk")
                    .font(.caption)
                    .fontWeight(.semibold)
                if entry.isStale {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                }
            }
            Text("\(entry.unreadCount) unread")
                .font(.caption2)
            if !entry.recentNames.isEmpty {
                Text(entry.recentNames.prefix(2).joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .opacity(entry.isStale ? 0.7 : 1.0)
    }
}

struct WatchInlineView: View {
    let entry: WatchUnreadCountEntry

    var body: some View {
        Label {
            Text(entry.unreadCount == 1 ? "1 unread message" : "\(entry.unreadCount) unread messages")
        } icon: {
            Image(systemName: "bubble.left.fill")
        }
    }
}

// MARK: - Widget

@main
struct UnreadComplication: Widget {
    let kind = "UnreadComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchUnreadCountProvider()) { entry in
            WatchComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Unread Messages")
        .description("Shows your unread message count")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct WatchComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WatchUnreadCountEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            WatchCircularView(entry: entry)
        case .accessoryRectangular:
            WatchRectangularView(entry: entry)
        case .accessoryInline:
            WatchInlineView(entry: entry)
        default:
            WatchCircularView(entry: entry)
        }
    }
}

#if DEBUG
private let previewWatchEntry = WatchUnreadCountEntry(
    date: .now,
    unreadCount: 5,
    recentNames: ["Alice", "Team Chat"],
    isStale: false
)

#Preview("Circular", as: .accessoryCircular) {
    UnreadComplication()
} timeline: {
    previewWatchEntry
}

#Preview("Rectangular", as: .accessoryRectangular) {
    UnreadComplication()
} timeline: {
    previewWatchEntry
}

#Preview("Inline", as: .accessoryInline) {
    UnreadComplication()
} timeline: {
    previewWatchEntry
}
#endif
