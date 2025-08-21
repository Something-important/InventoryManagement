import XCTest
@testable import InventoryManagement

final class Auth0UserIntegrationTests: XCTestCase {
    // MARK: - Test Configuration
    let testToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTIwVDA3OjE4OjU5LjE1NVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTc5OTkyOCwiZXhwIjoxNzU1ODM1OTI4LCJzaWQiOiJLSUpaZXBQdUZyZWItVFh6WG9DY3RycE9GMElYMHl6SiIsIm5vbmNlIjoiYUhVemNVbDZjV3BoZFhscmRFUmZja2hwZGkxTlNGUjVheTFvTGxsc1kwOVFRa2RDYjJ3MlpsVllVZz09In0.beqWA6KwzhM_7UenAu9A0qB4XEXlCNO5Z4_BPh34qLePCGq2VxsqJ6d1Fl0h1DOWfhFNd6hFsFTdSOszBknKttO7GW7IpE_zeb7OBvcT5bO-eGz8KC1fsqBkUamYXd9x14lPkBs_Hde7yVm2d3MB4N4WSyjeLLEzi7hTwWUtgP8MweSDms6n1zhk1aGDKF_iavXi0bskRFAqsfUH1nRivecAqiYhke84QvT04DeXDOLBUpdPYLOeDnIreYErVe7cqzTmdaVCRxTdayXj5eK6Kyn9DvCRhZGh3qlJGU8ycNbNJoYfqLW4BIxNkaRRj1DCZfkoz4Bl6zA5G-L1fuRrmA"
    
    static let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
    static let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_KEY"] ?? ""
    
    // MARK: - Setup & Teardown
    override class func setUp() {
        super.setUp()
        setenv("AUTH0_ISSUER", "https://dev-6d0hq63qae558wkg.us.auth0.com/", 1)
        setenv("SUPABASE_URL", supabaseUrl, 1)
        setenv("SUPABASE_SERVICE_KEY", supabaseKey, 1)
    }
    
    override class func tearDown() {
        unsetenv("AUTH0_ISSUER")
        unsetenv("SUPABASE_URL")
        unsetenv("SUPABASE_SERVICE_KEY")
        super.tearDown()
    }
    
    override func setUp() async throws {
        try await super.setUp()
        print("\nEnvironment Setup:")
        print("SUPABASE_URL: \(Self.supabaseUrl)")
        print("SUPABASE_SERVICE_KEY: \(Self.supabaseKey.prefix(10))...")
    }
    
    override func tearDown() async throws {
        await Task.yield()
        try await Task.sleep(nanoseconds: 100_000_000)
        try await super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    /// Tests creating a new user from Auth0 token data with existence check
    func testCreateUserWithExistenceCheck() async throws {
        // 1. Verify token and extract user data
        let verifier = Auth0TokenVerifier()
        let token = try AuthenticationToken(testToken)
        let auth0User = try await verifier.verify(token)
        let userService = await SupabaseUserService()
        
        // 2. Check if user already exists
        let existingUser = try await userService.fetchUser(byAuth0Id: auth0User.authenticationInfo.externalId)
        
        if existingUser == nil {
            // 3. Create new user only if doesn't exist
            let created = try await userService.createUser(
                auth0Id: auth0User.authenticationInfo.externalId,
                name: auth0User.profile.name ?? "Unknown",
                email: auth0User.profile.email ?? "no-email@example.com"
            )
            XCTAssertTrue(created, "Failed to create new user")
            
            // 4. Verify user was created with correct token data
            let newUser = try await userService.fetchUser(byAuth0Id: auth0User.authenticationInfo.externalId)
            XCTAssertNotNil(newUser, "User should exist after creation")
            XCTAssertEqual(newUser?.profile.name, auth0User.profile.name)
            XCTAssertEqual(newUser?.profile.email, auth0User.profile.email)
        } else {
            print("✅ User already exists, skipping creation")
        }
    }
    
    /// Tests updating user info directly from token data
    func testUpdateUserWithTokenInfo() async throws {
        // 1. Get user info from token
        let verifier = Auth0TokenVerifier()
        let token = try AuthenticationToken(testToken)
        let auth0User = try await verifier.verify(token)
        let userService = await SupabaseUserService()
        
        // 2. Get existing user
        let existingUser = try await userService.fetchUser(byAuth0Id: auth0User.authenticationInfo.externalId)
        guard let existingUser = existingUser else {
            XCTFail("User should exist before update")
            return
        }
        
        // 3. Update user with token data
        let updatedProfile = try UserProfile(
            name: auth0User.profile.name,
            email: auth0User.profile.email
        )
        let updatedUser = User(
            identifier: existingUser.identifier,
            profile: updatedProfile,
            authenticationInfo: auth0User.authenticationInfo,
            registrationDate: existingUser.registrationDate
        )
        
        let updated = try await userService.updateUser(updatedUser)
        XCTAssertTrue(updated, "Failed to update user with token data")
        
        // 4. Verify update was successful
        let fetchedUser = try await userService.fetchUser(byAuth0Id: auth0User.authenticationInfo.externalId)
        XCTAssertEqual(fetchedUser?.profile.name, auth0User.profile.name, "Name should be updated from token")
        XCTAssertEqual(fetchedUser?.profile.email, auth0User.profile.email, "Email should be updated from token")
    }
    
    /// Tests updating user with manually provided info
    func testManualUserUpdate() async throws {
        // 1. Get user info from token
        let verifier = Auth0TokenVerifier()
        let token = try AuthenticationToken(testToken)
        let auth0User = try await verifier.verify(token)
        let userService = await SupabaseUserService()
        
        // 2. Get existing user
        let existingUser = try await userService.fetchUser(byAuth0Id: auth0User.authenticationInfo.externalId)
        guard let existingUser = existingUser else {
            XCTFail("User should exist before update")
            return
        }
        
        // 3. Update user with manual data
        let newName = "Updated SK"
        let updatedProfile = try UserProfile(
            name: newName,
            email: existingUser.profile.email
        )
        let updatedUser = User(
            identifier: existingUser.identifier,
            profile: updatedProfile,
            authenticationInfo: existingUser.authenticationInfo,
            registrationDate: existingUser.registrationDate
        )
        
        let updated = try await userService.updateUser(updatedUser)
        XCTAssertTrue(updated, "Failed to update user with manual data")
        
        // 4. Verify update was successful
        let fetchedUser = try await userService.fetchUser(byAuth0Id: auth0User.authenticationInfo.externalId)
        XCTAssertEqual(fetchedUser?.profile.name, newName, "Name should be updated to manual value")
        XCTAssertEqual(fetchedUser?.profile.email, existingUser.profile.email, "Email should remain unchanged")
    }

    /// Tests that invalid tokens cannot be used to modify user data
    func testUpdateWithBadToken() async throws {
        // 1. Setup with valid token first
        let verifier = Auth0TokenVerifier()
        let token = try AuthenticationToken(testToken)
        let validUser = try await verifier.verify(token)
        let userService = await SupabaseUserService()
        
        // 2. Get existing user data
        let existingUser = try await userService.fetchUser(byAuth0Id: validUser.authenticationInfo.externalId)
        guard let existingUser = existingUser else {
            XCTFail("User should exist before attempting bad token update")
            return
        }
        
        // 3. Attempt update with bad token
        let badToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTIwVDA3OjE4OjU5LjE1NVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NTc5OTkyOCwiZXhwIjoxNzU1ODM1OTI4LCJzaWQiOiJLSUpaZXBQdUZyZWItVFh6WG9DY3RycE9GMElYMHl6SiIsIm5vbmNlIjoiYUhVemNVbDZjV3BoZFhscmRFUmZja2hwZGkxTlNGUjVheTFvTGxsc1kwOVFRa2RDYjJ3MlpsVllVZz09In0.invalid_signature"
        
        do {
            _ = try await verifier.verify(try AuthenticationToken(badToken))
            XCTFail("Should not verify token with invalid signature")
        } catch TokenError.signatureInvalid {
            print("✅ Successfully rejected token with invalid signature")
            
            // 4. Verify user data remains unchanged
            let unchangedUser = try await userService.fetchUser(byAuth0Id: validUser.authenticationInfo.externalId)
            XCTAssertNotNil(unchangedUser, "Should still find user")
            XCTAssertEqual(unchangedUser?.profile.name, existingUser.profile.name, "Name should be unchanged")
            XCTAssertEqual(unchangedUser?.profile.email, existingUser.profile.email, "Email should be unchanged")
        }
    }
} 
