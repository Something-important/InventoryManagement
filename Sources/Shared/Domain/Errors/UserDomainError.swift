//
//  UserDomainError.swift
//  InventoryManagement
//
//  Created by Claude on 20/8/2568 BE.
//

import Foundation

/// Domain errors specific to User entity and related value objects
public enum UserDomainError: Error, Equatable {
    case invalidIdentifier
    case invalidEmail
    case emptyName
    case profileIncomplete
    case invalidToken
    case sessionExpired
    case userNotVerified
}

extension UserDomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidIdentifier:
            return "User identifier cannot be empty"
        case .invalidEmail:
            return "Email address must contain @ symbol"
        case .emptyName:
            return "User name cannot be empty"
        case .profileIncomplete:
            return "User profile is incomplete"
        case .invalidToken:
            return "Invalid token"
        case .sessionExpired:
            return "Session expired"
        case .userNotVerified:
            return "User not verified, cannot access system"
        }
    }
}
