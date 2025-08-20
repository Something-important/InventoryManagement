//
//  AuthenticationToken.swift
//  InventoryManagement
//
//  Created by Stephen Barrett on 20/8/2568 BE.
//

public struct AuthenticationToken: Sendable {
      public let value: String

      public init(_ value: String) throws {
          guard !value.isEmpty else {
              throw UserDomainError.invalidToken
          }
          self.value = value
      }
  }
