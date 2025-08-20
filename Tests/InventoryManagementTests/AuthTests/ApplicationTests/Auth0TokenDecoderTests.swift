import XCTest
@testable import InventoryManagement

final class Auth0TokenDecoderTests: XCTestCase {
    let testToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTEzVDIxOjMzOjQxLjYxM1oiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTEyMDgyMywiZXhwIjoxNzU1MTU2ODIzLCJzaWQiOiJudHRGVWtST3h6M2pRc1p1Y04xLTBLb1lBcjRaQVVFbiIsIm5vbmNlIjoiYkhSRFZ6VkdRbmRUVDI1S1NVeFNaM054ZG5WdGNYSnNiRTUxTlRnNVVYQm5aRzlyY2pkTVJUUnpjdz09In0.i0mGc7KjQzbNdrQR44z381yMvrZYAHJMZzJsPHnOR9esuFFX0-iIoXD0iqtcIivli9b2AALoJtzmEhDxGdChE7-pIxkiBX1Oigc24d-RXfAcdUszdZtolrkqwC38zObqlJGWgop5PPvPuzliBF-B7rwH72z5cVF9OcTu1lP4HVdUoiUpwHjLOegR4pWk3Q7JqwYMlCYG6mHblkTiHVIBHVl5jwhuIQW4t3iwVIGc8iH1vmUdlwQ4B4XRKn-kNv6mdmoEDjWFc0PP9oJVB4_t8UjiS3PZrsl48xjibi6Lpn69gBuPhTJQTz2fmo5Ow-_qV82IIwEA-c8TRFut4VO6Yg"
    
    override func setUp() {
        super.setUp()
        setenv("AUTH0_ISSUER", "https://dev-6d0hq63qae558wkg.us.auth0.com/", 1)
    }
    
    override func tearDown() {
        unsetenv("AUTH0_ISSUER")
        super.tearDown()
    }
    
    func testVerifyAndDecodeToken() async throws {
        var verifier = TokenVerifier()
        let payload = try verifier.verifyAndDecode(token: testToken)
        
        // Print decoded data for inspection
        print("\nDecoded token payload:")
        for (key, value) in payload {
            print("\(key): \(value)")
        }
        
        // Assert expected claims
        XCTAssertEqual(payload["email"] as? String, "sumitredhu07@gmail.com")
        XCTAssertEqual(payload["name"] as? String, "SK")
        XCTAssertEqual(payload["nickname"] as? String, "sumitredhu07")
        XCTAssertTrue(payload["email_verified"] as? Bool ?? false)
        
        // Verify issuer was correctly validated
        XCTAssertEqual(payload["iss"] as? String, "https://dev-6d0hq63qae558wkg.us.auth0.com/")
    }
    
    func testExpiredToken() async {
        var verifier = TokenVerifier()
        
        do {
            let payload = try verifier.verifyAndDecode(token: testToken)
            // Token should not be expired, so this should succeed
            XCTAssertNotNil(payload["exp"])
            print("\nToken expiration: \(payload["exp"] ?? "not found")")
        } catch {
            XCTFail("Token verification failed with error: \(error)")
        }
    }
    
    func testInvalidToken() async {
        var verifier = TokenVerifier()
        let invalidToken = "invalid"
        
        do {
            _ = try verifier.verifyAndDecode(token: invalidToken)
            XCTFail("Should throw error for invalid token")
        } catch TokenError.invalidFormat {
            // Expected error
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}