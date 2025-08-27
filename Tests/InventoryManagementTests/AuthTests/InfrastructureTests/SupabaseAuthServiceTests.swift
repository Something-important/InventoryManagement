import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import XCTest
@testable import InventoryManagement

final class SupabaseAuthServiceTests: XCTestCase {
    private var authService: SupabaseAuthService!
    
    override func setUp() async throws {
        // Load environment variables from .env file
        try loadEnvironmentVariables()
        
        let config = try SupabaseConfig.fromEnvironment()
        authService = SupabaseAuthService(config: config)
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
    
    func test_tokenVerification() async throws {
        print("\n🔍 Starting Token Verification Test")
        
        let token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im1QcjRFZmZCSDJuRUFYYVY1ZGt2ViJ9.eyJnaXZlbl9uYW1lIjoiU0siLCJuaWNrbmFtZSI6InN1bWl0cmVkaHUwNyIsIm5hbWUiOiJTSyIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJOGV2bUhtVG9kX0lsSVlLb1hRMXFWbEtuSU1OMXFJSnVxbG41emtJdkxTMkpwclhncD1zOTYtYyIsInVwZGF0ZWRfYXQiOiIyMDI1LTA4LTI3VDExOjQ2OjM3Ljk3MVoiLCJlbWFpbCI6InN1bWl0cmVkaHUwN0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6Ly9kZXYtNmQwaHE2M3FhZTU1OHdrZy51cy5hdXRoMC5jb20vIiwiYXVkIjoiR3JOZTFwRTFmbnFYS2M1Ylc3dE5ETnlzekhuY2JsMVAiLCJzdWIiOiJnb29nbGUtb2F1dGgyfDExNjcxOTQzNTk4OTU3NjM4MDYxMCIsImlhdCI6MTc1NjMyMjI2OCwiZXhwIjoxNzU2MzU4MjY4LCJzaWQiOiJrOGp4M2ZIdUZtRWdWTVJGRThkWUdIZDBLblNKeHJUdSIsIm5vbmNlIjoiY1ZnMVdHMXNSaTVrWWtwRlZrVk1TeTVHVmpZM0xrVk5hRTU2ZEZNMVNVWTViV2xHT1RGMldVSmpaQT09In0.d7JBq-hGfAlKTrWR3mldq7qDpFMWzx_5dPCr23QYmh43VH5dNNu6cQAqI68QD-Fsb8dUK_Thi-SmjStlXXahHaC9LXqSRT0nFJ43j09cc37pTJGSvV0tsT0A4PI6pz5oI0xiKWR-mSjElWVene0cLPlJR4V7SCcPd0QUDQbo70VUUQnOv33QlxZhlKG8NqnbHxVbhGySvB4NBA4cA-ZK3Ywm1EexTerNrF1J0VBGvCSVI_nBqIIhJUe-xmswI3KRuu_59jD9ALBQ37zDAU4vZWWLF3Kp4U_Lm7YZqr4G-qQAPIDgPAi8YgsrCkjC8-c8MUre3yyTLunUvg5TKBVu6g"
        
        print("\n🔐 Verifying token...")
        let result = await authService.verifyToken(token)
        
        print("\n=== Verification Results ===")
        print("Token Valid: \(result.isValid ? "✅" : "❌")")
        print("Supabase Verified: \(result.supabaseVerified ? "✅" : "❌")")
        
        if let userData = result.userData {
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
        }
        
        if let response = result.rawResponse {
            print("\n📡 Raw Supabase Response:")
            print(response)
        }
        
        if !result.isValid {
            print("\n❌ Verification failed")
            if let error = result.error {
                print("Error: \(error)")
            }
            throw TestError("Token verification failed")
        }
    }
}

