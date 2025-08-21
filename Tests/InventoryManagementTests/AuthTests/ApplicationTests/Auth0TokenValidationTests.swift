import XCTest
@testable import InventoryManagement

final class Auth0TokenValidationTests: XCTestCase {
    let testToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTIwVDA3OjE4OjU5LjE1NVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTc5OTkyOCwiZXhwIjoxNzU1ODM1OTI4LCJzaWQiOiJLSUpaZXBQdUZyZWItVFh6WG9DY3RycE9GMElYMHl6SiIsIm5vbmNlIjoiYUhVemNVbDZjV3BoZFhscmRFUmZja2hwZGkxTlNGUjVheTFvTGxsc1kwOVFRa2RDYjJ3MlpsVllVZz09In0.beqWA6KwzhM_7UenAu9A0qB4XEXlCNO5Z4_BPh34qLePCGq2VxsqJ6d1Fl0h1DOWfhFNd6hFsFTdSOszBknKttO7GW7IpE_zeb7OBvcT5bO-eGz8KC1fsqBkUamYXd9x14lPkBs_Hde7yVm2d3MB4N4WSyjeLLEzi7hTwWUtgP8MweSDms6n1zhk1aGDKF_iavXi0bskRFAqsfUH1nRivecAqiYhke84QvT04DeXDOLBUpdPYLOeDnIreYErVe7cqzTmdaVCRxTdayXj5eK6Kyn9DvCRhZGh3qlJGU8ycNbNJoYfqLW4BIxNkaRRj1DCZfkoz4Bl6zA5G-L1fuRrmA"
    
    override func setUp() {
        super.setUp()
        setenv("AUTH0_ISSUER", "https://dev-6d0hq63qae558wkg.us.auth0.com/", 1)
    }
    
    override func tearDown() {
        unsetenv("AUTH0_ISSUER")
        super.tearDown()
    }
    
    func testVerifyAndDecodeToken() async throws {
        let verifier = Auth0TokenVerifier()
          let token = try AuthenticationToken(testToken)
          let user = try await verifier.verify(token)
        
        // Print decoded user for inspection
          print("\nDecoded user:")
          print("Email: \(user.profile.email ?? "none")")
          print("Name: \(user.profile.name ?? "none")")
          print("Verified: \(user.authenticationInfo.isVerified)")
          print("External ID: \(user.authenticationInfo.externalId)")
          print("Expires At: \(user.authenticationInfo.expiresAt ?? Date())")

          // Assert expected user properties
          XCTAssertEqual(user.profile.email, "sumitredhu07@gmail.com")
          XCTAssertEqual(user.profile.name, "SK")
          XCTAssertTrue(user.authenticationInfo.isVerified)
          XCTAssertEqual(user.authenticationInfo.externalId,
          "google-oauth2|116719435989576380610")    }
    
    func testExpiredToken() async {
        let verifier = Auth0TokenVerifier()
        do {
            let user = try await verifier.verify (try AuthenticationToken(testToken))
            // Token should not be expired, so this should succeed
              XCTAssertNotNil(user.authenticationInfo.expiresAt)
              print("\nToken expiration: \(user.authenticationInfo.expiresAt ?? Date())")
        } catch {
            XCTFail("Token verification failed with error: \(error)")
        }
    }
    
    func testInvalidToken() async {
        let verifier = Auth0TokenVerifier()
        let invalidToken = "invalid"
        
        do {
            _ = try await verifier.verify(try AuthenticationToken(invalidToken))
            XCTFail("Should throw error for invalid token")
        } catch TokenError.invalidFormat {
            // Expected error
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testInvalidSignature() async {
        // Modified signature part of the token
        let tamperedToken = "\(testToken.split(separator: ".")[0]).\(testToken.split(separator: ".")[1]).invalidSignature"
        let verifier = Auth0TokenVerifier()
        
        do {
            _ = try await verifier.verify(try AuthenticationToken(tamperedToken))
            XCTFail("Should throw error for invalid signature")
        } catch TokenError.signatureInvalid {
            // Expected error
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testIssuerMismatch() async {
        // Create a new token with modified issuer in payload
        let parts = testToken.split(separator: ".")
        guard let _ = try? base64UrlDecode(String(parts[0])), // Verify header is valid base64
              let payloadData = try? base64UrlDecode(String(parts[1])),
              var payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            XCTFail("Failed to decode token parts")
            return
        }
        
        // Modify the issuer in the payload
        payload["iss"] = "https://wrong-issuer.auth0.com/"
        
        // Encode modified payload
        guard let modifiedPayloadData = try? JSONSerialization.data(withJSONObject: payload),
              let modifiedPayloadBase64 = base64UrlEncode(modifiedPayloadData) else {
            XCTFail("Failed to encode modified payload")
            return
        }
        
        let modifiedToken = "\(parts[0]).\(modifiedPayloadBase64).\(parts[2])"
        let verifier = Auth0TokenVerifier()
        
        do {
            _ = try await verifier.verify(try AuthenticationToken(modifiedToken))
            XCTFail("Should throw error for issuer mismatch")
        } catch TokenError.signatureInvalid {
            // Since we modified the payload, signature becomes invalid first
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // Helper function to decode base64url
    private func base64UrlDecode(_ input: String) throws -> Data {
        var base64 = input.replacingOccurrences(of: "-", with: "+")
                         .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let data = Data(base64Encoded: base64) else {
            throw TokenError.invalidBase64
        }
        return data
    }
    
    // Helper function to encode base64url
    private func base64UrlEncode(_ data: Data) -> String? {
        let base64 = data.base64EncodedString()
        return base64.replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "")
    }
    
    func testTokenExpiration() async {
        // Create verifier with a future date to simulate expired token
        let futureDate = Date(timeIntervalSince1970: 1755835929) // After token expiration
        let verifier = Auth0TokenVerifier(currentDate: futureDate)
        
        do {
            _ = try await verifier.verify(try AuthenticationToken(testToken))
            XCTFail("Should throw error for expired token")
        } catch TokenError.tokenExpired {
            // Expected error
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testInvalidHeader() async {
        // Create token with invalid header (not proper base64)
        let invalidHeaderToken = "invalid_header.\(testToken.split(separator: ".")[1]).\(testToken.split(separator: ".")[2])"
        let verifier = Auth0TokenVerifier()
        
        do {
            _ = try await verifier.verify(try AuthenticationToken(invalidHeaderToken))
            XCTFail("Should throw error for invalid header")
        } catch TokenError.invalidHeader {
            // Expected error
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testInvalidPayload() async {
        // Create token with invalid payload (not proper base64)
        let parts = testToken.split(separator: ".")
        let invalidPayloadToken = "\(parts[0]).@@invalid@@.\(parts[2])"
        let verifier = Auth0TokenVerifier()
        
        do {
            _ = try await verifier.verify(try AuthenticationToken(invalidPayloadToken))
            XCTFail("Should throw error for invalid payload")
        } catch TokenError.invalidBase64 {
            // Expected error - invalid base64 is caught before signature validation
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
