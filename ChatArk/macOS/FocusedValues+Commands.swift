#if os(macOS)
import SwiftUI

struct NewConversationCommandKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct SearchCommandKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var newConversationCommand: (() -> Void)? {
        get { self[NewConversationCommandKey.self] }
        set { self[NewConversationCommandKey.self] = newValue }
    }
    var searchCommand: (() -> Void)? {
        get { self[SearchCommandKey.self] }
        set { self[SearchCommandKey.self] = newValue }
    }
}
#endif
