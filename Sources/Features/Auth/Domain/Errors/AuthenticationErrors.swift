import Foundation

// Infrastructure level errors (from services)
public enum TokenVerificationError: Error {
    case invalidToken
    case missingConfiguration
    case networkError
    case invalidResponse
    case verificationFailed
}

// Domain level errors (for business logic)
public enum AuthenticationError: Error {
    case invalidToken
    case networkError
    case verificationFailed
    case invalidResponse
    case configurationError
    case unknown
    case tokenExpired
}
