//
//  UserRepositoryProtocol.swift
//  InventoryManagement
//
//  Created by Stephen Barrett on 20/8/2568 BE.
//

public protocol UserRepositoryProtocol {
      func fetchUser(by identifier: UserIdentifier) async throws -> User?
      func createUser(_ user: User) async throws -> Bool
  }
