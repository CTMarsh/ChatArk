import Foundation

/// Simple token-bucket rate limiter for client-side API call throttling.
@MainActor
final class RateLimiter {
    private let maxTokens: Int
    private let refillInterval: TimeInterval
    private var tokens: Int
    private var lastRefill: Date

    /// - Parameters:
    ///   - maxTokens: Maximum burst size
    ///   - refillInterval: Seconds between token refills (1 token per interval)
    /// `nonisolated` so services with a `nonisolated init` (e.g. SearchService)
    /// can construct a RateLimiter as a default stored-property value under Swift 6.
    /// Only assigns stored properties; the mutating refill/consume stay @MainActor.
    nonisolated init(maxTokens: Int, refillInterval: TimeInterval) {
        self.maxTokens = maxTokens
        self.refillInterval = refillInterval
        self.tokens = maxTokens
        self.lastRefill = Date()
    }

    /// Returns true if the action is allowed, false if rate-limited.
    func tryConsume() -> Bool {
        refill()
        guard tokens > 0 else { return false }
        tokens -= 1
        return true
    }

    private func refill() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        let newTokens = Int(elapsed / refillInterval)
        if newTokens > 0 {
            tokens = min(maxTokens, tokens + newTokens)
            lastRefill = now
        }
    }
}
