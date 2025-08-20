//
//  Auth0TokenVerifier.swift
//  InventoryManagement
//
//  Created by Stephen Barrett on 20/8/2568 BE.
//

import Foundation
import JWTKit

actor Auth0TokenVerifier: TokenVerifierProtocol {
    let issuer: String
    private var jwksKeys: [String: JWTKit.JWK] = [:]
    
    init() {
        guard let issuer = ProcessInfo.processInfo.environment["AUTH0_ISSUER"] else {
            fatalError("Auth0 configuration missing. Please set AUTH0_ISSUER environment variable.")
        }
        self.issuer = issuer
    }
    
    func verify(_ token: AuthenticationToken) async throws -> User {
        // Split JWT into header, payload, signature
        let parts = token.value.split(separator: ".")
        guard parts.count == 3 else {
            throw TokenError.invalidFormat
        }
        
        let headerData = try base64UrlDecode(String(parts[0]))
        let payloadData = try base64UrlDecode(String(parts[1]))
        
        // Parse header
        guard let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let kid = header["kid"] as? String else {
            throw TokenError.invalidHeader
        }
        
        // Load JWKS keys if empty
        if jwksKeys.isEmpty {
            try fetchJWKS()
        }
        
        // Verify signature using the JWK
        guard let jwk = jwksKeys[kid] else {
            throw TokenError.keyNotFound
        }
        
        let signers = JWTSigners()
        try signers.use(jwk: jwk)
        
        // Verify the token signature
        _ = try signers.verify(token.value, as: Auth0Payload.self)
        
        // Parse payload for validation
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw TokenError.invalidPayload
        }
        
        // Validate claims
        try validateClaims(payload)
        
        let identifier = try UserIdentifier(payload["sub"] as? String ?? "")
         let profile = try UserProfile(
             name: payload["name"] as? String,
             email: payload["email"] as? String
         )
         let expirationDate = Date(timeIntervalSince1970: payload["exp"] as? TimeInterval ?? 0)
         let authInfo = AuthenticationInfo(
             externalId: payload["sub"] as? String ?? "",
             isVerified: payload["email_verified"] as? Bool ?? false,
             expiresAt: expirationDate
         )

         return User(
             identifier: identifier,
             profile: profile,
             authenticationInfo: authInfo,
             registrationDate: Date() // You might want to use "iat" (issued at) if available
         )
    }
    
    private func fetchJWKS() throws {
        let url = URL(string: "\(issuer).well-known/jwks.json")!
        let data = try Data(contentsOf: url)
        let jwks = try JSONDecoder().decode(JWKSResponse.self, from: data)
        
        for key in jwks.keys {
            let jwkJson = """
            {
                "kid": "\(key.kid)",
                "kty": "\(key.kty)",
                "n": "\(key.n)",
                "e": "\(key.e)",
                "alg": "RS256"
            }
            """
            jwksKeys[key.kid] = try JWTKit.JWK(json: jwkJson)
        }
    }
    
    private func validateClaims(_ payload: [String: Any]) throws {
        guard let iss = payload["iss"] as? String,
              let exp = payload["exp"] as? TimeInterval else {
            throw TokenError.invalidPayload
        }
        
        if iss != issuer {
            throw TokenError.issuerMismatch
        }
        if Date().timeIntervalSince1970 > exp {
            throw TokenError.tokenExpired
        }
    }
    
    private func base64UrlDecode(_ input: String) throws -> Data {
        var base64 = input.replacingOccurrences(of: "-", with: "+")
                         .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let data = Data(base64Encoded: base64) else {
            throw TokenError.invalidBase64
        }
        return data
    }
}

// Auth0 JWT Payload structure
struct Auth0Payload: JWTPayload {
    var issuer: String
    var audience: String
    var expiresAt: Date
    var issuedAt: Date
    var subject: String?
    var email: String?
    var emailVerified: Bool?
    var name: String?
    var nickname: String?
    var picture: String?
    
    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case audience = "aud"
        case expiresAt = "exp"
        case issuedAt = "iat"
        case subject = "sub"
        case email
        case emailVerified = "email_verified"
        case name
        case nickname
        case picture
    }
    
    func verify(using signer: JWTSigner) throws {
        // Verification is handled in TokenVerifier
    }
}

// JWKS Response structure
struct JWKSResponse: Codable {
    let keys: [JWK]
}

struct JWK: Codable {
    let kid: String
    let kty: String
    let n: String
    let e: String
}

enum TokenError: Error {
    case invalidFormat
    case invalidBase64
    case invalidHeader
    case keyNotFound
    case signatureInvalid
    case invalidPayload
    case issuerMismatch
    case audienceMismatch
    case tokenExpired
    case invalidKeyData
}
