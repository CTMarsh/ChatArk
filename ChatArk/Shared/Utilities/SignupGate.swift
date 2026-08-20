import Foundation

/// Result of querying whether new-account registration is permitted.
///
/// `unverified` is a distinct fail-CLOSED outcome: the check could not be completed,
/// so signups must be treated as NOT allowed rather than opened. It is deliberately
/// NOT folded into `disabled`, because the two need different copy — an administrator
/// turning signups off is a decision, a failed RPC is a fault the user can retry.
enum SignupAvailability: String, Equatable, Sendable, CaseIterable {
    case allowed
    case disabled   // administrator has turned signups off
    case unverified // check failed — deny on doubt (fail closed)
}

/// The fail-CLOSED decision itself, split out of `AuthViewModel` so it can be tested
/// without a Supabase client, a network, or a main-actor view model.
///
/// The bug this guards against (fixed in !49): the previous implementation returned
/// `true` from its `catch` block, so a transient RPC failure — or an attacker able to
/// make one RPC fail — silently re-opened registration on an instance whose
/// administrator had turned it off. An administrative gate must deny on doubt.
enum SignupGate {

    /// Maps the outcome of the `get_allow_signups` RPC onto an availability.
    ///
    /// - `.success(true)`  → `.allowed`
    /// - `.success(false)` → `.disabled`
    /// - `.failure`        → `.unverified`  ← never `.allowed`
    static func evaluate(_ result: Result<Bool, Error>) -> SignupAvailability {
        switch result {
        case .success(true):
            return .allowed
        case .success(false):
            return .disabled
        case .failure:
            // Administrative gate: deny on doubt. A transient RPC failure must
            // never open registration that an admin may have disabled.
            return .unverified
        }
    }

    /// The single place that decides whether a signup may proceed.
    /// Only an explicit `.allowed` permits registration; everything else blocks.
    static func permitsRegistration(_ availability: SignupAvailability) -> Bool {
        switch availability {
        case .allowed:
            return true
        case .disabled, .unverified:
            return false
        }
    }
}
