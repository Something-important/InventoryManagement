import Foundation
import XCTest
#if os(Linux)
import FoundationNetworking
#endif
@testable import InventoryManagement

final class SupabaseAuthIntegrationTests: XCTestCase {
    private var authService: SupabaseAuthService!
    private var userService: SupabaseUserService!
    
    // Test token with long expiry for testing
    private let testToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTI3VDExOjQ2OjM3Ljk3MVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NjMyMjI2OCwiZXhwIjoxNzU2MzU4MjY4LCJzaWQiOiJrOGp4M2ZIdUZtRWdWTVJGRThkWUdIZDBLblNKeHJUdSIsIm5vbmNlIjoiY1ZnMVdHMXNSaTVrWWtwRlZrVk1TeTVHVmpZM0xrVk5hRTU2ZEZNMVNVWTViV2xHT1RGMldVSmpaQT09In0.d7JBq-hGfAlKTrWR3mldq7qDpFMWzx_5dPCr23QYmh43VH5dNNu6cQAqI68QD-Fsb8dUK_Thi-SmjStlXXahHaC9LXqSRT0nFJ43j09cc37pTJGSvV0tsT0A4PI6pz5oI0xiKWR-mSjElWVene0cLPlJR4V7SCcPd0QUDQbo70VUUQnOv33QlxZhlKG8NqnbHxVbhGySvB4NBA4cA-ZK3Ywm1EexTerNrF1J0VBGvCSVI_nBqIIhJUe-xmswI3KRuu_59jD9ALBQ37zDAU4vZWWLF3Kp4U_Lm7YZqr4G-qQAPIDgPAi8YgsrCkjC8-c8MUre3yyTLunUvg5TKBVu6g"
    
    override func setUp() async throws {
        try await super.setUp()
        try loadEnvironmentVariables()
        let config = try SupabaseConfig.fromEnvironment()
        authService = SupabaseAuthService(config: config)
        userService = await SupabaseUserService(client: .shared)
    }
    
    func test_tokenVerificationAndUserSync() async throws {
        print("\n🔍 Starting Token Verification and User Sync Test")
        
        // 1. Verify token
        let verificationResult = await authService.verifyToken(testToken)
        guard verificationResult.isValid, let userData = verificationResult.userData else {
            throw TestError("Token verification failed")
        }
        
        print("\n✅ Token verified successfully")
        print("User ID: \(userData.sub)")
        print("Name: \(userData.name ?? "N/A")")
        print("Email: \(userData.email ?? "N/A")")
        
        // 2. Check if user exists
        let existingUser = try await userService.fetchUser(byAuth0Id: userData.sub)
        
        if existingUser == nil {
            // 3. Create new user if doesn't exist
            let created = try await userService.createUser(
                auth0Id: userData.sub,
                name: userData.name ?? "Unknown",
                email: userData.email ?? "no-email@example.com"
            )
            
            if !created {
                throw TestError("Failed to create new user")
            }
            print("\n✅ Created new user")
            
            // 4. Verify user was created correctly
            let newUser = try await userService.fetchUser(byAuth0Id: userData.sub)
            guard let newUser = newUser else {
                throw TestError("User not found after creation")
            }
            
            if newUser.profile.name != userData.name {
                throw TestError("Name mismatch after creation")
            }
            if newUser.profile.email != userData.email {
                throw TestError("Email mismatch after creation")
            }
            
            print("✅ User data verified after creation")
        } else {
            print("\n✅ User already exists, skipping creation")
            
            // 5. Update existing user if needed
            let updatedProfile = try UserProfile(
                name: userData.name,
                email: userData.email
            )
            let updatedUser = User(
                identifier: existingUser!.identifier,
                profile: updatedProfile,
                authenticationInfo: AuthenticationInfo(
                    externalId: userData.sub,
                    isVerified: userData.emailVerified ?? false,
                    expiresAt: Date(timeIntervalSince1970: TimeInterval(userData.exp))
                ),
                registrationDate: existingUser!.registrationDate
            )
            
            let updated = try await userService.updateUser(updatedUser)
            if !updated {
                throw TestError("Failed to update existing user")
            }
            print("✅ Updated existing user")
        }
    }
    
    func test_invalidTokenHandling() async throws {
        print("\n🔍 Starting Invalid Token Test")
        
        // Test with malformed token
        let malformedToken = "not.a.valid.token"
        let malformedResult = await authService.verifyToken(malformedToken)
        if malformedResult.isValid {
            throw TestError("Malformed token should be rejected")
        }
        print("✅ Rejected malformed token")
        
        // Test with expired token
        let expiredToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDIzLTA4LTI3VDExOjQ2OjM3Ljk3MVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTY5MzEzNzk5NywiZXhwIjoxNjkzMTczOTk3LCJzaWQiOiJrOGp4M2ZIdUZtRWdWTVJGRThkWUdIZDBLblNKeHJUdSIsIm5vbmNlIjoiY1ZnMVdHMXNSaTVrWWtwRlZrVk1TeTVHVmpZM0xrVk5hRTU2ZEZNMVNVWTViV2xHT1RGMldVSmpaQT09In0.invalid_signature"
        let expiredResult = await authService.verifyToken(expiredToken)
        if expiredResult.isValid {
            throw TestError("Expired token should be rejected")
        }
        print("✅ Rejected expired token")
        
        // Test with invalid signature
        let invalidSignatureToken = testToken + ".tampered"
        let invalidSignatureResult = await authService.verifyToken(invalidSignatureToken)
        if invalidSignatureResult.isValid {
            throw TestError("Token with invalid signature should be rejected")
        }
        print("✅ Rejected token with invalid signature")
    }
    
    private func loadEnvironmentVariables() throws {
        var searchPath = FileManager.default.currentDirectoryPath
        var envPath: String?
        
        for _ in 0...3 {
            let testPath = searchPath + "/.env"
            if FileManager.default.fileExists(atPath: testPath) {
                envPath = testPath
                break
            }
            searchPath = (searchPath as NSString).deletingLastPathComponent
        }
        
        guard let envPath = envPath else {
            print("⚠️ No .env file found in current directory or parent directories")
            return
        }
        
        let envContents = try String(contentsOfFile: envPath, encoding: .utf8)
        let envLines = envContents.components(separatedBy: .newlines)
        
        for line in envLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") else { continue }
            
            let parts = trimmedLine.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            var value = parts[1].trimmingCharacters(in: .whitespaces)
            
            if value.hasPrefix("\"") && value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            }
            
            setenv(key, value, 1)
        }
    }
}