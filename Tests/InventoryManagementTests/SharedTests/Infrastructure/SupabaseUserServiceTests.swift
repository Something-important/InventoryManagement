import XCTest
@testable import InventoryManagement

final class SupabaseUserServiceTests: XCTestCase {

    private var userService: SupabaseUserService!
    private var testAuth0Id: String!

    override func setUp() async throws {
        try await super.setUp()
        userService = await SupabaseUserService(client: .shared)
        testAuth0Id = "test-\(UUID().uuidString)"
        print("✅ Using Supabase URL:", ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "MISSING")
    }

    func testFullUserCRUD() async throws {
        print("🔍 Starting User CRUD Integration Test")
        
        let initialName = "Test User"
        let initialEmail = "test@example.com"
        // let existingTestUserAuth0Id = "test-9DB7CDD9-7D11-415D-BCE9-41289C350C35"
        
        // 1️⃣ CREATE user
        let created = try await userService.createUser(
            auth0Id: testAuth0Id,
            name: initialName,
            email: initialEmail
        )
        print("📦 createUser() returned:", created)
        XCTAssertTrue(created)
        
        // 2️⃣ FETCH user
        var fetchedUser = try await userService.fetchUser(byAuth0Id: testAuth0Id)
        print("📥 fetchUser() returned:", String(describing: fetchedUser))
        XCTAssertEqual(fetchedUser?.profile.name, initialName)
        XCTAssertEqual(fetchedUser?.profile.email, initialEmail)
        
        // 3️⃣ UPDATE user
        let updatedName = "Updated User"
        let updatedEmail = "updated@example.com"
        let existingUser = try await userService.fetchUser(byAuth0Id: testAuth0Id)
        let updatedProfile = try UserProfile(name: updatedName, email: updatedEmail)
          let updatedUserEntity = User(
              identifier: existingUser!.identifier,
              profile: updatedProfile,
              authenticationInfo: existingUser!.authenticationInfo,
              registrationDate: existingUser!.registrationDate
          )

          let updated = try await userService.updateUser(updatedUserEntity)

        print("✏️ updateUser() returned:", updated)
        XCTAssertTrue(updated)
        
        // 4️⃣ FETCH after update
        fetchedUser = try await userService.fetchUser(byAuth0Id: testAuth0Id)
        print("📥 fetchUser() after update returned:", String(describing: fetchedUser))
        XCTAssertEqual(fetchedUser?.profile.name, updatedName)
        XCTAssertEqual(fetchedUser?.profile.email, updatedEmail)
        
        // 5️⃣ DELETE user
//        let deleted = try await userService.deleteUser(auth0Id: testAuth0Id)
//        print("🗑 deleteUser() returned:", deleted)
//        XCTAssertTrue(deleted)
        
        // 6️⃣ FETCH after delete
        fetchedUser = try await userService.fetchUser(byAuth0Id: testAuth0Id)
        print("📥 fetchUser() after delete returned:", String(describing: fetchedUser))
        XCTAssertNil(fetchedUser, "User should not exist after deletion")
        
        print("✅ User CRUD Integration Test completed successfully")
    }
}
