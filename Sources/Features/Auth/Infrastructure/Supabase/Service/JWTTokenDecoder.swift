import Foundation

public final class JWTTokenDecoder {
    
    public init() {}
    
    public func decodeToken(_ token: String) -> JWTDecodingResult {
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
        
        return .success(userData: userData)
    }
    
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

// MARK: - Result Types
public enum JWTDecodingResult: Sendable {
    case success(userData: UserData)
    case failure(JWTDecodingError)
}

public enum JWTDecodingError: Error, Sendable {
    case invalidToken
}
