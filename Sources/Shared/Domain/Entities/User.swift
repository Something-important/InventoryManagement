//
//  User.swift
//  InventoryManagement
//
//  Created by Stephen Barrett on 20/8/2568 BE.
//

import Foundation


public struct User: Sendable {
      public let identifier: UserIdentifier
      public let profile: UserProfile
      public let authenticationInfo: AuthenticationInfo
      public let registrationDate: Date

      // Business logic methods
      public func isProfileComplete() -> Bool {
          return profile.name != nil && profile.email != nil
      }

      public func canAccessInventoryFeature() -> Bool {
          return authenticationInfo.isVerified && isProfileComplete()
      }

      public func displayName() -> String {
          return profile.name ?? profile.email ?? "Unknown User"
      }
  }

  // Value Objects
  public struct UserIdentifier: Sendable {
      public let value: String

      public init(_ value: String) throws {
          guard !value.isEmpty else {
              throw UserDomainError.invalidIdentifier
          }
          self.value = value
      }
  }

  public struct UserProfile: Sendable {
      public let name: String?
      public let email: String?

      public init(name: String?, email: String?) throws {
          if let email = email {
              guard email.contains("@") else {
                  throw UserDomainError.invalidEmail
              }
          }
          self.name = name
          self.email = email
      }
  }

  public struct AuthenticationInfo: Sendable {
      public let externalId: String
      public let isVerified: Bool
      public let expiresAt: Date?
  }
