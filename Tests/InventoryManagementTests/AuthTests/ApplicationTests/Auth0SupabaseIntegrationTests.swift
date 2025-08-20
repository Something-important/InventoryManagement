import XCTest
@testable import InventoryManagement

final class Auth0SupabaseIntegrationTests: XCTestCase {
    let testToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTEzVDIxOjMzOjQxLjYxM1oiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTEyMDgyMywiZXhwIjoxNzU1MTU2ODIzLCJzaWQiOiJudHRGVWtST3h6M2pRc1p1Y04xLTBLb1lBcjRaQVVFbiIsIm5vbmNlIjoiYkhSRFZ6VkdRbmRUVDI1S1NVeFNaM054ZG5WdGNYSnNiRTUxTlRnNVVYQm5aRzlyY2pkTVJUUnpjdz09In0.i0mGc7KjQzbNdrQR44z381yMvrZYAHJMZzJsPHnOR9esuFFX0-iIoXD0iqtcIivli9b2AALoJtzmEhDxGdChE7-pIxkiBX1Oigc24d-RXfAcdUszdZtolrkqwC38zObqlJGWgop5PPvPuzliBF-B7rwH72z5cVF9OcTu1lP4HVdUoiUpwHjLOegR4pWk3Q7JqwYMlCYG6mHblkTiHVIBHVl5jwhuIQW4t3iwVIGc8iH1vmUdlwQ4B4XRKn-kNv6mdmoEDjWFc0PP9oJVB4_t8UjiS3PZrsl48xjibi6Lpn69gBuPhTJQTz2fmo5Ow-_qV82IIwEA-c8TRFut4VO6Yg"
    
    static let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    static let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_KEY"] ?? ""
    
    override func setUp() {
        super.setUp()
        // Set required environment variables
        setenv("AUTH0_ISSUER", "https://dev-6d0hq63qae558wkg.us.auth0.com/", 1)
        setenv("SUPABASE_URL", Self.supabaseUrl, 1)
        setenv("SUPABASE_SERVICE_KEY", Self.supabaseKey, 1)
        
        print("\nEnvironment Setup:")
        print("SUPABASE_URL: \(Self.supabaseUrl)")
        print("SUPABASE_SERVICE_KEY: \(Self.supabaseKey.prefix(10))...")
    }
    
    override func tearDown() {
        unsetenv("AUTH0_ISSUER")
        unsetenv("SUPABASE_URL")
        unsetenv("SUPABASE_SERVICE_KEY")
        super.tearDown()
    }
    
    func testVerifyTokenAndUpdateUser() async throws {
        // First verify the token
        var verifier = TokenVerifier()
        let payload = try verifier.verifyAndDecode(token: testToken)
        
        // Extract user info from verified token
        guard let sub = payload["sub"] as? String,  // This is the Auth0 ID
              let name = payload["name"] as? String,
              let email = payload["email"] as? String else {
            XCTFail("Failed to extract user info from token")
            return
        }
        
        print("\nVerified token payload:")
        print("Auth0 ID (sub): \(sub)")
        print("Name: \(name)")
        print("Email: \(email)")
        
        // Now update the user in Supabase
        let userService = await SupabaseUserService()
        
        print("\nAttempting Supabase operations:")
        do {
            print("Fetching user with Auth0 ID: \(sub)")
            let existingUser = try await userService.fetchUser(byAuth0Id: sub)
            
            if existingUser == nil {
                print("User not found, creating new user...")
                let created = try await userService.createUser(auth0Id: sub, name: name, email: email)
                XCTAssertTrue(created, "Failed to create new user")
                print("Created new user with Auth0 ID: \(sub)")
            } else {
                print("User found, updating existing user...")
                let updated = try await userService.updateUser(auth0Id: sub, name: name, email: email)
                XCTAssertTrue(updated, "Failed to update user")
                print("Updated existing user with Auth0 ID: \(sub)")
            }
            
            // Verify the user was saved/updated
            let user = try await userService.fetchUser(byAuth0Id: sub)
            XCTAssertNotNil(user, "User should exist after create/update")
            XCTAssertEqual(user?.name, name)
            XCTAssertEqual(user?.email, email)
            
            print("\nFinal user state:")
            print("ID: \(user?.id ?? -1)")
            print("Auth0 ID: \(user?.auth0Id ?? "none")")
            print("Name: \(user?.name ?? "none")")
            print("Email: \(user?.email ?? "none")")
            print("Created At: \(user?.createdAt ?? Date())")
        } catch {
            print("\nError during Supabase operation: \(error)")
            throw error
        }
    }
    
    func testInvalidTokenHandling() async {
        let invalidToken = "invalid.token.here"
        var verifier = TokenVerifier()
        
        do {
            _ = try verifier.verifyAndDecode(token: invalidToken)
            XCTFail("Should throw error for invalid token")
        } catch {
            print("Successfully caught invalid token error: \(error)")
            XCTAssert(true, "Successfully caught invalid token")
        }
    }
    
    func testManuallyUpdateUserName() async throws {
        // First verify the token to get the Auth0 ID
        var verifier = TokenVerifier()
        let payload = try verifier.verifyAndDecode(token: testToken)
        
        guard let sub = payload["sub"] as? String else {
            XCTFail("Failed to get Auth0 ID from token")
            return
        }
        
        // Now update the user with a new name
        let userService = await SupabaseUserService()
        let newName = "Updated SK"
        
        print("\nAttempting to update user name:")
        print("Auth0 ID: \(sub)")
        print("New name: \(newName)")
        
        // Update user with new name but keep the same email
        let updated = try await userService.updateUser(
            auth0Id: sub,
            name: newName,
            email: payload["email"] as? String
        )
        XCTAssertTrue(updated, "Failed to update user name")
        
        // Verify the update
        let user = try await userService.fetchUser(byAuth0Id: sub)
        XCTAssertNotNil(user, "User should exist")
        XCTAssertEqual(user?.name, newName, "Name should be updated")
        
        print("\nUpdated user state:")
        print("ID: \(user?.id ?? -1)")
        print("Auth0 ID: \(user?.auth0Id ?? "none")")
        print("Name: \(user?.name ?? "none")")
        print("Email: \(user?.email ?? "none")")
        print("Created At: \(user?.createdAt ?? Date())")
    }
    
    func testForgedTokenAccess() async throws {
        // Create a forged token with modified claims but keeping JWT format
        let forgedToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiSGFja2VyIiwibmlja25hbWUiOiJoYWNrZXIiLCJuYW1lIjoiSGFja2VyIiwiZW1haWwiOiJoYWNrZXJAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTEyMDgyMywiZXhwIjoxNzU1MTU2ODIzfQ.invalid_signature"

        var verifier = TokenVerifier()
        
        print("\nAttempting to use forged token:")
        print("Token claims modified to use hacker's information")
        print("But keeping the same Auth0 ID to attempt user modification")
        
        do {
            let payload = try verifier.verifyAndDecode(token: forgedToken)
            
            // If we get here, something is wrong with our verification
            XCTFail("Should not verify a forged token. Got payload: \(payload)")
            
            // Attempt to modify user data (should not reach this point)
            let userService = await SupabaseUserService()
            if let sub = payload["sub"] as? String {
                let updated = try await userService.updateUser(
                    auth0Id: sub,
                    name: "Hacker",
                    email: "hacker@example.com"
                )
                XCTFail("Should not allow updates with forged token. Update success: \(updated)")
            }
        } catch {
            // This is what we expect - the token should fail verification
            print("✅ Security check passed: Forged token was rejected")
            print("Error (expected): \(error)")
        }
    }
} 