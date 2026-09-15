import XCTest
@testable import DAMiniPlayer

final class PKCETests: XCTestCase {
    func testKnownVectorFromRFC7636() {
        // RFC 7636 Appendix B fixed test vector.
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let expectedChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        XCTAssertEqual(PKCE.codeChallenge(for: verifier), expectedChallenge)
    }

    func testGeneratedVerifierIsURLSafeAndLongEnough() {
        let verifier = PKCE.generateCodeVerifier()
        XCTAssertGreaterThanOrEqual(verifier.count, 43)
        XCTAssertLessThanOrEqual(verifier.count, 128)
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        XCTAssertTrue(verifier.unicodeScalars.allSatisfy { allowed.contains($0) })
    }

    func testChallengeIsDeterministic() {
        let verifier = PKCE.generateCodeVerifier()
        XCTAssertEqual(PKCE.codeChallenge(for: verifier), PKCE.codeChallenge(for: verifier))
    }
}
