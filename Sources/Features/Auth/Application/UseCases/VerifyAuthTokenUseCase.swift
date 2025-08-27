import Foundation

public struct VerifyAuthTokenUseCase {
    private let authService: TokenAuthenticationService
    
    public init(authService: TokenAuthenticationService) {
        self.authService = authService
    }
    
    public func execute(_ token: String) async throws -> UserData {
        let result = await authService.verifyToken(token)
        let userData = try authService.validateTokenResult(result)
        
        // Check if token is expired
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(userData.exp))
        guard expiryDate > Date() else {
            throw AuthenticationError.tokenExpired
        }
        
        return userData
    }
}
