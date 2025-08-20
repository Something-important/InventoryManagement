//
//  TokenVerifierProtocol.swift
//  InventoryManagement
//
//  Created by Stephen Barrett on 20/8/2568 BE.
//

public protocol TokenVerifierProtocol {
      func verify(_ token: AuthenticationToken) async throws -> User
  }
