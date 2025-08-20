//
//  VerifyTokenUseCase.swift
//  InventoryManagement
//
//  Created by Stephen Barrett on 20/8/2568 BE.
//

import Foundation

public struct VerifyTokenUseCase {
      private let tokenVerifier: TokenVerifierProtocol

      public func execute(token: AuthenticationToken) async throws -> User {
          // 1. Verify the token and get User entity
          let user = try await tokenVerifier.verify(token)

          // 2. Business rule: Check if session is expired
          if let expiresAt = user.authenticationInfo.expiresAt,
             expiresAt < Date() {
              throw UserDomainError.sessionExpired
          }

          // 3. Business rule: Ensure user can access system
          guard user.authenticationInfo.isVerified else {
              throw UserDomainError.userNotVerified
          }

          return user
      }
  }

