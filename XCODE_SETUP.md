# Xcode Project Setup Guide

## Step 1: Create the Project

1. Open Xcode
2. **File > New > Project**
3. Select **Multiplatform > App**
4. Configure:
   - Product Name: `ChatArk`
   - Team: Your Apple Developer team
   - Organization Identifier: `com.chrismarsh`
   - Bundle Identifier: `com.chrismarsh.chatark`
   - Interface: **SwiftUI**
   - Storage: **SwiftData**
   - Testing: Include Tests
5. Save into the `Chat-App-Clients/` directory (alongside the existing `ChatArk/` folder)
6. **Delete** the auto-generated ContentView.swift and ChatArkApp.swift files that Xcode creates

## Step 2: Configure Deployment Targets

1. Select the project in the Navigator
2. For each target, set:
   - **iOS target**: Deployment Target = **iOS 18.0**
   - **macOS target**: Deployment Target = **macOS 15.0**
   - **watchOS target**: Deployment Target = **watchOS 11.0**

## Step 3: Add SPM Dependencies

1. **File > Add Package Dependencies**
2. Add these three packages:

| Package URL | Version |
|-------------|---------|
| `https://github.com/supabase/supabase-swift.git` | From 2.0.0 |
| `https://github.com/kean/Nuke.git` | From 12.0.0 |
| `https://github.com/kishikawakatsumi/KeychainAccess.git` | From 4.2.2 |

3. For each package, add to **all targets** that need it:
   - `Supabase` → iOS, macOS, watchOS targets
   - `NukeUI` → iOS, macOS targets (watchOS optional)
   - `KeychainAccess` → iOS, macOS, watchOS targets

## Step 4: Add Shared Code

1. In the Project Navigator, right-click the project
2. **Add Files to "ChatArk"**
3. Navigate to `ChatArk/Shared/` and add the entire folder
4. In the file inspector, ensure these files are added to **all targets** (iOS, macOS, watchOS):
   - All files in `Shared/Models/`
   - All files in `Shared/Services/`
   - All files in `Shared/ViewModels/`
   - All files in `Shared/Cache/`
   - All files in `Shared/Utilities/`
   - All files in `Shared/SharedViews/` (exclude from watchOS target if they use unavailable APIs)

## Step 5: Add Platform-Specific Files

### iOS/iPadOS Target
Add these folders to the **iOS target only**:
- `iOS/` (all files including ChatArkApp.swift)
- `iPad/` (all files)

Set `iOS/ChatArkApp.swift` as the app entry point:
- Select iOS target > Build Settings > search "INFOPLIST_FILE" > set to `iOS/Info.plist`

### macOS Target
Add to **macOS target only**:
- `macOS/` (all files including ChatArkApp.swift)

Set `macOS/ChatArkApp.swift` as the app entry point:
- Select macOS target > Build Settings > search "INFOPLIST_FILE" > set to `macOS/Info.plist`

### watchOS Target
Add to **watchOS target only**:
- `watchOS/` (all files including ChatArkWatchApp.swift)

Set `watchOS/ChatArkWatchApp.swift` as the app entry point:
- Select watchOS target > Build Settings > search "INFOPLIST_FILE" > set to `watchOS/Info.plist`

## Step 6: Add Extension Targets

### Notification Service Extension
1. **File > New > Target**
2. Select **iOS > Notification Service Extension**
3. Name: `NotificationServiceExtension`
4. Bundle ID: `com.chrismarsh.chatark.notification-service`
5. Delete the auto-generated files
6. Add `NotificationServiceExtension/NotificationService.swift`
7. Set Info.plist to `NotificationServiceExtension/Info.plist`

### Share Extension
1. **File > New > Target**
2. Select **iOS > Share Extension**
3. Name: `ShareExtension`
4. Bundle ID: `com.chrismarsh.chatark.share`
5. Delete auto-generated files
6. Add `ShareExtension/ShareViewController.swift`
7. Set Info.plist to `ShareExtension/Info.plist`

### Widget Extension (Home Screen + Live Activity)
1. **File > New > Target**
2. Select **iOS > Widget Extension**
3. Name: `ChatWidgets`
4. Bundle ID: `com.chrismarsh.chatark.widgets`
5. Check "Include Live Activity"
6. Delete auto-generated files
7. Add `iOS/Widgets/ChatWidgetBundle.swift` and `iOS/LiveActivity/ChatLiveActivity.swift`

### watchOS Complication (Widget)
1. **File > New > Target**
2. Select **watchOS > Widget Extension**
3. Name: `ChatWatchComplication`
4. Bundle ID: `com.chrismarsh.chatark.watchos.complication`
5. Delete auto-generated files
6. Add `watchOS/Complications/UnreadComplication.swift`

## Step 7: Configure Entitlements

For each target, set the entitlements file:

| Target | Entitlements File |
|--------|-------------------|
| iOS | `iOS/ChatArk.entitlements` |
| macOS | `macOS/ChatArk.entitlements` |
| watchOS | `watchOS/ChatArkWatch.entitlements` |

In each target's **Signing & Capabilities** tab, add:
- Push Notifications
- App Groups → `group.com.chrismarsh.chatark`
- Keychain Sharing → `com.chrismarsh.chatark`

For macOS additionally:
- Network (Outgoing Connections)

## Step 8: Configure Bundle Identifiers

| Target | Bundle ID |
|--------|-----------|
| iOS/iPadOS | `com.chrismarsh.chatark` |
| macOS | `com.chrismarsh.chatark.macos` |
| watchOS | `com.chrismarsh.chatark.watchos` |
| NotificationServiceExtension | `com.chrismarsh.chatark.notification-service` |
| ShareExtension | `com.chrismarsh.chatark.share` |
| ChatWidgets | `com.chrismarsh.chatark.widgets` |
| ChatWatchComplication | `com.chrismarsh.chatark.watchos.complication` |

## Step 9: Add Privacy Manifest

1. Add `PrivacyInfo.xcprivacy` to the iOS and macOS targets
2. It's already configured with the required API declarations

## Step 10: Replace Placeholder Keys

Open `Shared/Services/SupabaseManager.swift` and replace the placeholder anon keys:

```swift
// Development
anonKey: "SUPABASE_ANON_KEY_DEV"  // ← Replace with real dev anon key

// Production
anonKey: "SUPABASE_ANON_KEY_PROD" // ← Replace with real prod anon key
```

Get the keys from your Supabase dashboard:
- Dev: https://supabase.com/dashboard/project/bcwfsqldmyyrstxjuruc/settings/api
- Prod: https://supabase.com/dashboard/project/xtnqdyjldgmfhtvtggmm/settings/api

## Step 11: Resolve @main Conflicts

Each target must have exactly **one** `@main` entry point. If you see duplicate `@main` errors:

- iOS target should only compile `iOS/ChatArkApp.swift` (not macOS or watchOS app files)
- macOS target should only compile `macOS/ChatArkApp.swift`
- watchOS target should only compile `watchOS/ChatArkWatchApp.swift`

Ensure platform-specific files are **only** in their respective target memberships.

## Step 12: Build & Fix

1. **Product > Build** (Cmd+B) for each target
2. Common issues to expect:
   - Missing imports: Add `import Supabase` or `import Auth` where needed
   - Platform availability: Wrap iOS-specific APIs with `#if os(iOS)`
   - Swift 6 concurrency: May need `@Sendable` annotations or `nonisolated` on some closures
3. Build for each destination:
   - iPhone 16 Simulator (iOS)
   - iPad Simulator (iPadOS)
   - My Mac (macOS)
   - Apple Watch Simulator (watchOS)

## Build Order

Build in this order to catch issues incrementally:
1. iOS target first (most complete, fewest platform restrictions)
2. macOS target second
3. watchOS target third
4. Extension targets last
