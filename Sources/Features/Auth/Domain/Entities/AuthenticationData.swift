import Foundation

public struct UserData: Codable, Sendable {
    // Standard Claims
    public let sub: String          // Subject (User ID)
    public let aud: String          // Audience
    public let iss: String          // Issuer
    public let iat: Int             // Issued At
    public let exp: Int             // Expires At
    
    // User Profile Claims
    public let name: String?
    public let email: String?
    public let emailVerified: Bool?
    public let picture: String?
    public let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case sub, aud, iss, iat, exp
        case name
        case email
        case emailVerified = "email_verified"
        case picture
        case updatedAt = "updated_at"
    }
}

public struct TokenVerificationResult: Sendable {
    public let isValid: Bool
    public let userData: UserData?
    public let supabaseVerified: Bool
    public let error: TokenVerificationError?
    public let rawResponse: String?
    
    public static func success(userData: UserData, supabaseResponse: String?) -> TokenVerificationResult {
        return TokenVerificationResult(
            isValid: true,
            userData: userData,
            supabaseVerified: true,
            error: nil,
            rawResponse: supabaseResponse
        )
    }
    
    public static func failure(_ error: TokenVerificationError, response: String? = nil) -> TokenVerificationResult {
        return TokenVerificationResult(
            isValid: false,
            userData: nil,
            supabaseVerified: false,
            error: error,
            rawResponse: response
        )
    }
}


