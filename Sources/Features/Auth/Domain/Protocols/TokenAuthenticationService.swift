import Foundation

public protocol TokenAuthenticationService {
    /// Verifies a token and returns the authentication data if valid
    /// - Parameter token: The raw token string to verify
    /// - Returns: TokenVerificationResult containing:
    ///   - isValid: Whether the token is valid
    ///   - userData: Decoded user data from token if valid
    ///   - error: Any error that occurred during verification
    func verifyToken(_ token: String) async -> TokenVerificationResult
}



// Add extension to make error handling cleaner in use cases
extension TokenAuthenticationService {
    func validateTokenResult(_ result: TokenVerificationResult) throws -> UserData {
        guard result.isValid, let userData = result.userData else {
            switch result.error {
            case .invalidToken:
                throw AuthenticationError.invalidToken
            case .networkError:
                throw AuthenticationError.networkError
            case .verificationFailed:
                throw AuthenticationError.verificationFailed
            case .invalidResponse:
                throw AuthenticationError.invalidResponse
            case .missingConfiguration:
                throw AuthenticationError.configurationError
            case .none:
                throw AuthenticationError.unknown
            }
        }
        return userData
    }
}
