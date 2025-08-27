import Foundation
#if os(Linux)
import FoundationNetworking
#endif

public actor SupabaseAuthService: TokenAuthenticationService {
    private let supabaseUrl: String
    private let supabaseAnonKey: String
    
    public init(config: SupabaseConfig) {
        self.supabaseUrl = config.supabaseUrl
        self.supabaseAnonKey = config.supabaseAnonKey
    }
    
    public func verifyToken(_ token: String) async -> TokenVerificationResult {
        // Use /rest/v1/ endpoint to verify token access
        // This endpoint returns the API schema if the token is valid
        // We use this instead of /auth/v1/user because it's simpler and matches the React app
        let baseUrl = supabaseUrl.hasSuffix("/") ? String(supabaseUrl.dropLast()) : supabaseUrl
        guard let url = URL(string: "\(baseUrl)/rest/v1/") else {
            return .failure(.invalidToken)
        }
        
        print("🔍 Making request to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        print("📤 Request headers:")
        print("Authorization: Bearer [token hidden]")
        print("apikey: [key hidden]")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return .failure(.invalidResponse)
            }
            
            print("📥 Response status code: \(httpResponse.statusCode)")
            
            // Step 1: Check if Supabase accepts the token
            print("\nStep 1: Verifying token with Supabase...")
            if !(200...299).contains(httpResponse.statusCode) {
                print("❌ Token verification failed")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("Error: \(errorText)")
                }
                return .failure(.verificationFailed)
            }
            print("✅ Supabase verified the token")
            
            // Step 2: Decode the token
            print("\nStep 2: Decoding token contents...")
            let parts = token.split(separator: ".")
            guard parts.count == 3,
                  let payloadData = Data(base64Encoded: base64URLtoBase64(String(parts[1]))) else {
                print("❌ Invalid token format")
                return .failure(.invalidToken)
            }
            
            guard let userData = try? JSONDecoder().decode(UserData.self, from: payloadData) else {
                print("❌ Could not decode token data")
                return .failure(.invalidToken)
            }
            
            // Show the decoded data
            print("\n📋 Token Header:")
            if let headerData = Data(base64Encoded: base64URLtoBase64(String(parts[0]))),
               let headerDict = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any] {
                print("Algorithm: \(headerDict["alg"] ?? "N/A")")
                print("Type: \(headerDict["typ"] ?? "N/A")")
                print("Key ID: \(headerDict["kid"] ?? "N/A")")
            }
            
            print("\n📦 Decoded Token Information:")
            print("══════════════════════════════════════")
            
            if let payloadDict = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                // First show provider info
                if let sub = payloadDict["sub"] as? String {
                    let parts = sub.split(separator: "|")
                    if parts.count == 2 {
                        print("🔐 Authentication Provider")
                        print("   Provider: \(parts[0].capitalized)")
                        print("   User ID:  \(parts[1])")
                        print("──────────────────────────────────────")
                    }
                }
                
                // Then show user info
                print("👤 User Information")
                if let name = payloadDict["name"] as? String {
                    print("   Name:     \(name)")
                }
                if let email = payloadDict["email"] as? String {
                    print("   Email:    \(email)")
                }
                if let verified = payloadDict["email_verified"] as? Bool {
                    print("   Verified: \(verified ? "✅ Yes" : "❌ No")")
                }
                if payloadDict["picture"] != nil {
                    print("   Picture:  Available")
                }
                print("──────────────────────────────────────")
                
                // Then show token validity
                print("🕒 Token Validity")
                if let iat = payloadDict["iat"] as? TimeInterval {
                    let issuedDate = Date(timeIntervalSince1970: iat)
                    print("   Issued:   \(issuedDate.formatted())")
                }
                if let exp = payloadDict["exp"] as? TimeInterval {
                    let expiryDate = Date(timeIntervalSince1970: exp)
                    let now = Date()
                    let timeLeft = expiryDate.timeIntervalSince(now)
                    let hoursLeft = Int(timeLeft / 3600)
                    let minutesLeft = Int((timeLeft.truncatingRemainder(dividingBy: 3600)) / 60)
                    
                    print("   Expires:  \(expiryDate.formatted())")
                    if timeLeft > 0 {
                        print("   Valid for: \(hoursLeft)h \(minutesLeft)m ✅")
                    } else {
                        print("   Status:   Expired ❌")
                    }
                }
                print("──────────────────────────────────────")
                
                // Show security info
                print("🔒 Security Information")
                if let iss = payloadDict["iss"] as? String {
                    print("   Issuer:   \(iss)")
                }
                if let aud = payloadDict["aud"] as? String {
                    print("   Audience: \(aud)")
                }
                
                // Finally show any additional fields
                let standardFields = Set(["name", "email", "email_verified", "picture", "iss", "aud", "exp", "iat", "sub"])
                let additionalFields = payloadDict.keys.filter { !standardFields.contains($0) }
                if !additionalFields.isEmpty {
                    print("──────────────────────────────────────")
                    print("ℹ️  Additional Information")
                    for field in additionalFields.sorted() {
                        let value = payloadDict[field] ?? "N/A"
                        let fieldName = field.replacingOccurrences(of: "_", with: " ").capitalized
                        print("   \(fieldName.padding(toLength: 10, withPad: " ", startingAt: 0)): \(value)")
                    }
                }
                print("══════════════════════════════════════")
            }
            
            let responseText = String(data: data, encoding: .utf8)
            return .success(userData: userData, supabaseResponse: responseText)
        } catch {
            print("❌ Network error: \(error)")
            if let urlError = error as? URLError {
                print("URL Error code: \(urlError.code)")
                print("URL Error description: \(urlError.localizedDescription)")
            }
            return .failure(.networkError)
        }
    }
}

extension SupabaseAuthService {
    private func base64URLtoBase64(_ value: String) -> String {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        return base64
    }
}

public struct SupabaseConfig {
    let supabaseUrl: String
    let supabaseAnonKey: String
    
    public init(supabaseUrl: String, supabaseAnonKey: String) {
        self.supabaseUrl = supabaseUrl
        self.supabaseAnonKey = supabaseAnonKey
    }
    
    public static func fromEnvironment() throws -> SupabaseConfig {
        guard let url = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
            throw TokenVerificationError.missingConfiguration
        }
        
        return SupabaseConfig(
            supabaseUrl: url,
            supabaseAnonKey: key
        )
    }
}
