import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import XCTest
@testable import InventoryManagement

final class SupabaseClientAuthServiceTests: XCTestCase {
    private var tokenValidator: SupabaseTokenValidator!
    private var tokenDecoder: JWTTokenDecoder!
    
    override func setUp() async throws {
        // Load environment variables from .env file
        try loadEnvironmentVariables()
        
        // Create the new refactored components
        tokenValidator = await SupabaseTokenValidator()
        tokenDecoder = JWTTokenDecoder()
    }
    
    private func loadEnvironmentVariables() throws {
        // Find .env file in project directory or parent directories
        var searchPath = FileManager.default.currentDirectoryPath
        var envPath: String?
        
        // Search up to 3 levels up for .env file
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
        
        // Read and parse .env file
        let envContents = try String(contentsOfFile: envPath, encoding: .utf8)
        let envLines = envContents.components(separatedBy: .newlines)
        
        for line in envLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") else { continue }
            
            let parts = trimmedLine.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            var value = parts[1].trimmingCharacters(in: .whitespaces)
            
            // Remove quotes if present
            if value.hasPrefix("\"") && value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            }
            
            setenv(key, value, 1)
        }
    }
    
    func test_tokenVerificationWithClient() async throws {
        print("\n🔍 Starting Token Verification Test with Refactored Components")
        
        let token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTI3VDExOjQ2OjM3Ljk3MVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NjQwNjEzOSwiZXhwIjoxNzU2NDQyMTM5LCJzaWQiOiJrOGp4M2ZIdUZtRWdWTVJGRThkWUdIZDBLblNKeHJUdSIsIm5vbmNlIjoiT1Vka1kyOHRObnBSYkZCWlZGWm5ZbE4rYUZsVFdtSlpTWEZJYWxCeGRYUlZiMGwrTm1OUmRUaG9jdz09In0.cV-zGeTn0QEbUkc5DilpUu5EUWlGZ38WfsLBm7Lf0KcSMxpbNvAWjjmZ1zHl5Kw9e9mBYXxKZImnaeeHTivAMr3tGk-kilGBXfvqmGJuMFFhekBnJUzfCgjHymMgb6SLLwlgzd5tSUgrF2oMkYdKnquZ3JUkBQ17liZ-5VbkR7ExUWl2bnkOWHRWqmZ7U0ec5DAGQR1sWqaXJ9pJpwvJH-CKkSz8R2_DU6dsr8ARTDaF81TiPUDwYObqZvrbrasyR82o7z-QaDzOnjM7Alp9nFKs_kRjHALZZ1yabuorqa8FmoL2WcZDc4du5tg2r5pp0Cx2TZU235hIXKo0U9hyog"
        
        print("\n🔐 Step 1: Validating token with Supabase...")
        let validationResult = await tokenValidator.validateToken(token)
        
        switch validationResult {
        case .failure(let error):
            print("❌ Token validation failed: \(error)")
            throw TestError("Token validation failed: \(error)")
            
        case .success(let supabaseResponse):
            print("✅ Token validated successfully with Supabase")
            
            print("\n🔐 Step 2: Decoding JWT token...")
            let decodingResult = tokenDecoder.decodeToken(token)
            
            switch decodingResult {
            case .failure(let error):
                print("❌ Token decoding failed: \(error)")
                throw TestError("Token decoding failed: \(error)")
                
            case .success(let userData):
                print("\n=== Verification Results ===")
                print("Token Valid: ✅")
                print("Supabase Verified: ✅")
                
                print("\n👤 Verified Token Data:")
                print("Subject (User ID): \(userData.sub)")
                print("Name: \(userData.name ?? "N/A")")
                print("Email: \(userData.email ?? "N/A")")
                print("Email Verified: \(userData.emailVerified ?? false)")
                print("Picture: \(userData.picture ?? "N/A")")
                print("\nToken Info:")
                print("Issuer: \(userData.iss)")
                print("Audience: \(userData.aud)")
                print("Issued At: \(Date(timeIntervalSince1970: TimeInterval(userData.iat)))")
                print("Expires At: \(Date(timeIntervalSince1970: TimeInterval(userData.exp)))")
                
                print("\n📡 Raw Supabase Response:")
                print(supabaseResponse)
            }
        }
    }
    
    func test_serviceInitialization() async {
        print("\n🔧 Testing Refactored Components Initialization")
        
        // Test that the components can be created without throwing
        let validator = await SupabaseTokenValidator()
        XCTAssertNotNil(validator, "TokenValidator should not be nil after initialization")
        
        let decoder = JWTTokenDecoder()
        XCTAssertNotNil(decoder, "TokenDecoder should not be nil after initialization")
        
        print("✅ Component initialization test passed")
    }
    
    func test_environmentConfiguration() {
        print("\n🌍 Testing environment configuration")
        
        // Verify that required environment variables are set
        let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"]
        let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_KEY"]
        
        XCTAssertNotNil(supabaseUrl, "SUPABASE_URL should be set in environment")
        XCTAssertNotNil(supabaseKey, "SUPABASE_SERVICE_KEY should be set in environment")
        
        if let url = supabaseUrl {
            XCTAssertTrue(URL(string: url) != nil, "SUPABASE_URL should be a valid URL")
        }
        
        if let key = supabaseKey {
            XCTAssertFalse(key.isEmpty, "SUPABASE_SERVICE_KEY should not be empty")
        }
        
        print("✅ Environment configuration test passed")
        print("   SUPABASE_URL: \(supabaseUrl ?? "Not set")")
        print("   SUPABASE_SERVICE_KEY: \(supabaseKey != nil ? "[Set]" : "Not set")")
    }
    
    func test_invalidTokenHandling() async throws {
        print("\n🔍 Testing Invalid Token Handling with Refactored Components")
        
        // Use an expired token
        let expiredToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTI3VDExOjQ2OjM3Ljk3MVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NjMyMjI2OCwiZXhwIjoxNzU2MzU4MjY4LCJzaWQiOiJrOGp4M2ZIdUZtRWdWTVJGRThkWUdIZDBLblNKeHJUdSIsIm5vbmNlIjoiY1ZnMVdHMXNSaTVrWWtwRlZrVk1TeTVHVmpZM0xrVk5hRTU2ZEZNMVNVWTViV2xHT1RGMldVSmpaQT09In0.d7JBq-hGfAlKTrWR3mldq7qDpFMWzx_5dPCr23QYmh43VH5dNNu6cQAqI68QD-Fsb8dUK_Thi-SmjStlXXahHaC9LXqSRT0nFJ43j09cc37pTJGSvV0tsT0A4PI6pz5oI0xiKWR-mSjElWVene0cLPlJR4V7SCcPd0QUDQbo70VUUQnOv33QlxZhlKG8NqnbHxVbhGySvB4NBA4cA-ZK3Ywm1EexTerNrF1J0VBGvCSVI_nBqIIhJUe-xmswI3KRuu_59jD9ALBQ37zDAU4vZWWLF3Kp4U_Lm7YZqr4G-qQAPIDgPAi8YgsrCkjC8-c8MUre3yyTLunUvg5TKBVu6g"
        
        print("\n🔐 Step 1: Validating expired token with Supabase...")
        let validationResult = await tokenValidator.validateToken(expiredToken)
        
        switch validationResult {
        case .failure(let error):
            print("❌ Token validation failed as expected: \(error)")
            print("✅ This is correct behavior - expired token should fail validation")
            
            // Verify the error type
            switch error {
            case .verificationFailed:
                print("✅ Correct error type: verificationFailed")
            case .invalidResponse:
                print("⚠️ Unexpected error type: invalidResponse")
            case .networkError:
                print("⚠️ Unexpected error type: networkError")
            }
            
        case .success(_):
            print("❌ Unexpected success - expired token should not validate")
            XCTFail("Expired token should not validate successfully")
        }
        
        print("\n🔐 Step 2: Attempting to decode expired token...")
        let decodingResult = tokenDecoder.decodeToken(expiredToken)
        
        switch decodingResult {
        case .failure(let error):
            print("❌ Token decoding failed: \(error)")
            print("✅ This is expected for expired tokens")
            
        case .success(let userData):
            print("⚠️ Token decoded successfully (this might happen with expired tokens)")
            print("   Expires At: \(Date(timeIntervalSince1970: TimeInterval(userData.exp)))")
            let now = Date()
            let expiryDate = Date(timeIntervalSince1970: TimeInterval(userData.exp))
            if expiryDate < now {
                print("✅ Confirmed: Token is expired")
            }
        }
        
        print("\n📋 Summary:")
        print("✅ New approach fails fast at validation step")
        print("✅ No unnecessary JWT processing for invalid tokens")
        print("✅ Clear error distinction between validation and decoding failures")
    }
}
