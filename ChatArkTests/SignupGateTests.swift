import XCTest

/// The signup gate is an *administrative* control: an operator who turns registration
/// off on this instance expects it to stay off. Before !49 the check failed OPEN -- the
/// `catch` returned `true` -- so any error on the `get_allow_signups` RPC (a dropped
/// connection, a Supabase restart, a deliberately-provoked failure) re-opened
/// registration. These tests pin the fail-CLOSED rule so that regression cannot recur
/// silently.
final class SignupGateTests: XCTestCase {

    private struct RPCFailure: Error {}

    // MARK: - The three outcomes

    func testExplicitTrueAllowsSignups() {
        XCTAssertEqual(SignupGate.evaluate(.success(true)), .allowed)
    }

    func testExplicitFalseDisablesSignups() {
        XCTAssertEqual(SignupGate.evaluate(.success(false)), .disabled)
    }

    /// THE regression test for !49.
    func testRPCFailureIsUnverifiedNotAllowed() {
        let outcome = SignupGate.evaluate(.failure(RPCFailure()))
        XCTAssertEqual(outcome, .unverified)
        XCTAssertNotEqual(outcome, .allowed, "a failed availability check must never open registration")
    }

    /// Any error, not just our own type -- URLError, a Cocoa error, an NSError from
    /// PostgREST -- must land on the same closed outcome.
    func testEveryErrorKindFailsClosed() {
        let errors: [Error] = [
            RPCFailure(),
            URLError(.notConnectedToInternet),
            URLError(.timedOut),
            NSError(domain: "PostgREST", code: 500),
            CocoaError(.coderValueNotFound)
        ]
        for error in errors {
            XCTAssertEqual(SignupGate.evaluate(.failure(error)), .unverified,
                           "\(type(of: error)) did not fail closed")
        }
    }

    // MARK: - Only `.allowed` permits registration

    func testOnlyAllowedPermitsRegistration() {
        XCTAssertTrue(SignupGate.permitsRegistration(.allowed))
        XCTAssertFalse(SignupGate.permitsRegistration(.disabled))
        XCTAssertFalse(SignupGate.permitsRegistration(.unverified))
    }

    /// Exhaustive over `CaseIterable`, so a case added later is covered the moment it
    /// exists: anything that is not `.allowed` must not permit registration.
    func testNoNonAllowedCasePermitsRegistration() {
        for availability in SignupAvailability.allCases {
            XCTAssertEqual(SignupGate.permitsRegistration(availability),
                           availability == .allowed,
                           "\(availability) has the wrong permission")
        }
    }

    /// `disabled` and `unverified` both block, but they are not interchangeable -- the UI
    /// shows "signups disabled" for one and an offer to retry for the other. Collapsing
    /// them would tell a user an admin turned signups off when the network merely blipped.
    func testDisabledAndUnverifiedRemainDistinct() {
        XCTAssertNotEqual(SignupAvailability.disabled, .unverified)
        XCTAssertEqual(SignupAvailability.allCases.count, 3)
    }
}
