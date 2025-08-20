import XCTest
@testable import InventoryManagement

final class Auth0SupabaseIntegrationTests: XCTestCase {
    let testToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTIwVDA3OjE4OjU5LjE1NVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTY3NDM0NiwiZXhwIjoxNzU1NzEwMzQ2LCJzaWQiOiJLSUpaZXBQdUZyZWItVFh6WG9DY3RycE9GMElYMHl6SiIsIm5vbmNlIjoiVFVKSFZub3dUbXhPVFMwdU9EVktUekI0TFc1VlVWZGhabXRSV2pab1FYNHhUSFJaWXpkbFlXSjBTUT09In0.QBzQvV87o-SFT_4D8NiKbqqR5Ap3h9CEHCeYmuYW742OB8jqlrh4ITzyIA86wDwpFUp_4zv-yRBAPDvO9edHOhXaLli4fSqjsWuDERL-_nb7m6n49RBGCikHrJo8ycn_63PqUo6k5hcfkTpxqkXF3yCP6X0Db8piF8ZakFPDcQfJ4vBC2Fx7SdDxcv2_CD1pCh8-acpnKYv3znUeUEsZELPzpuX3n4yFsv2jhmegXU1IPWlEO13j3EcnLCYk3vm-9yBRZx2enUpnmyCUG4_a_fKxRmAb8tdnKPMO4B6gqvEjAtQBmtnpIdZnWkQW6Oa8P5DQj_71O2bq_7C8abkk7g"
    
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
        let verifier = Auth0TokenVerifier()
          let token = try AuthenticationToken(testToken)
          let user = try await verifier.verify(token)
        
        // Extract user info from verified token
        let sub = user.authenticationInfo.externalId
        let name = user.profile.name ?? "Unknown"
        let email = user.profile.email ?? "no-email@example.com"

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
                //let updated = try await userService.updateUser(auth0Id: sub, name: name, email: email)
                let updatedProfile = try UserProfile(name: name, email: email)
                let updatedUser = User(
                    identifier: existingUser!.identifier,
                    profile: updatedProfile,
                    authenticationInfo: existingUser!.authenticationInfo,
                    registrationDate: existingUser!.registrationDate
                )
                let updated = try await userService.updateUser(updatedUser)
                XCTAssertTrue(updated, "Failed to update user")
                print("Updated existing user with Auth0 ID: \(sub)")
            }
            
            // Verify the user was saved/updated
            let user = try await userService.fetchUser(byAuth0Id: sub)
            XCTAssertNotNil(user, "User should exist after create/update")
            XCTAssertEqual(user?.profile.name, name)
            XCTAssertEqual(user?.profile.email, email)
            
            print("\nFinal user state:")
            print("ID: \(user?.identifier.value ?? "none")")
            print("Auth0 ID: \(user?.authenticationInfo.externalId ?? "none")")
            print("Name: \(user?.profile.name ?? "none")")
            print("Email: \(user?.profile.email ?? "none")")
            print("Created At: \(user?.registrationDate ?? Date())")
        } catch {
            print("\nError during Supabase operation: \(error)")
            throw error
        }
    }
    
    func testInvalidTokenHandling() async {
        let invalidToken = "invalid.token.here"
        let verifier = Auth0TokenVerifier()
        
        do {
            _ = try await verifier.verify(try AuthenticationToken(invalidToken))
            XCTFail("Should throw error for invalid token")
        } catch {
            print("Successfully caught invalid token error: \(error)")
            XCTAssert(true, "Successfully caught invalid token")
        }
    }
    
    func testManuallyUpdateUserName() async throws {
        // First verify the token to get the Auth0 ID
        let verifier = Auth0TokenVerifier()  // ← Also fix: let instead of var
          let user = try await verifier.verify(try AuthenticationToken(testToken))

          let sub = user.authenticationInfo.externalId
        
        // Now update the user with a new name
        let userService = await SupabaseUserService()
        let newName = "Updated SK"
        
        print("\nAttempting to update user name:")
        print("Auth0 ID: \(sub)")
        print("New name: \(newName)")
        
        // Update user with new name but keep the same email
//        let updated = try await userService.updateUser(
//            auth0Id: sub,
//            name: newName,
//            email: user.profile.email
//        )
        let existingUser = try await userService.fetchUser(byAuth0Id: sub)
        let updateProfile = try UserProfile(name: newName, email: existingUser!.profile.email)
        let updatedUser = User(
            identifier: existingUser!.identifier,
            profile: updateProfile,
            authenticationInfo: existingUser!.authenticationInfo,
            registrationDate: existingUser!.registrationDate
        )
        let updated = try await userService.updateUser(updatedUser)
        XCTAssertTrue(updated, "Failed to update user name")
        
        // Verify the update
        let fetchedUser = try await userService.fetchUser(byAuth0Id: sub)
        XCTAssertNotNil(fetchedUser, "User should exist")
        XCTAssertEqual(fetchedUser?.profile.name, newName, "Name should be updated")
        
        print("\nUpdated user state:")
        print("ID: \(fetchedUser?.identifier.value ?? "none")")
        print("Auth0 ID: \(fetchedUser?.authenticationInfo.externalId ?? "none")")
        print("Name: \(fetchedUser?.profile.name ?? "none")")
        print("Email: \(fetchedUser?.profile.email ?? "none")")
        print("Created At: \(fetchedUser?.registrationDate ?? Date())")
    }
    
//    func testForgedTokenAccess() async throws {
//        // Create a forged token with modified claims but keeping JWT format
//        let forgedToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiSGFja2VyIiwibmlja25hbWUiOiJoYWNrZXIiLCJuYW1lIjoiSGFja2VyIiwiZW1haWwiOiJoYWNrZXJAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTEyMDgyMywiZXhwIjoxNzU1MTU2ODIzfQ.invalid_signature"
//
//        let verifier = Auth0TokenVerifier()
//        
//        print("\nAttempting to use forged token:")
//        print("Token claims modified to use hacker's information")
//        print("But keeping the same Auth0 ID to attempt user modification")
//        
//        do {
//            
//              let user = try await verifier.verify(try AuthenticationToken(forgedToken))
//
//              // If we get here, something is wrong with our verification
//              XCTFail("Should not verify a forged token. Got user: \(user)")
//
//              // Attempt to modify user data (should not reach this point)
//              let userService = await SupabaseUserService()
//              let sub = user.authenticationInfo.externalId
//              let updated = try await userService.updateUser(
//                  auth0Id: sub,
//                  name: "Hacker",
//                  email: "hacker@example.com"
//              )
//              XCTFail("Should not allow updates with forged token. Update success: \(updated)")
//            
//        } catch {
//            // This is what we expect - the token should fail verification
//            print("✅ Security check passed: Forged token was rejected")
//            print("Error (expected): \(error)")
//        }
//    }
} 
