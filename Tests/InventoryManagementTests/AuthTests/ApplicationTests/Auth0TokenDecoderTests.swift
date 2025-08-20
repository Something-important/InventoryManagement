import XCTest
@testable import InventoryManagement

final class Auth0TokenDecoderTests: XCTestCase {
    let testToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTIwVDA3OjE4OjU5LjE1NVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTY3NDM0NiwiZXhwIjoxNzU1NzEwMzQ2LCJzaWQiOiJLSUpaZXBQdUZyZWItVFh6WG9DY3RycE9GMElYMHl6SiIsIm5vbmNlIjoiVFVKSFZub3dUbXhPVFMwdU9EVktUekI0TFc1VlVWZGhabXRSV2pab1FYNHhUSFJaWXpkbFlXSjBTUT09In0.QBzQvV87o-SFT_4D8NiKbqqR5Ap3h9CEHCeYmuYW742OB8jqlrh4ITzyIA86wDwpFUp_4zv-yRBAPDvO9edHOhXaLli4fSqjsWuDERL-_nb7m6n49RBGCikHrJo8ycn_63PqUo6k5hcfkTpxqkXF3yCP6X0Db8piF8ZakFPDcQfJ4vBC2Fx7SdDxcv2_CD1pCh8-acpnKYv3znUeUEsZELPzpuX3n4yFsv2jhmegXU1IPWlEO13j3EcnLCYk3vm-9yBRZx2enUpnmyCUG4_a_fKxRmAb8tdnKPMO4B6gqvEjAtQBmtnpIdZnWkQW6Oa8P5DQj_71O2bq_7C8abkk7g"
    
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
}
