import Foundation

// Request body when creating a new user row
struct UserCreateBody: Encodable {
    let auth0_id: String
    let name: String?
    let email: String?
}

// Request body when updating an existing user
struct UserUpdateBody: Encodable {
    let name: String?
    let email: String?
}

// Response object mapping a user record from the "users" table
public struct User: Codable, Sendable {  // Added Sendable conformance
    let id: Int
    let auth0Id: String
    let name: String?
    let email: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case auth0Id = "auth0_id"
        case name
        case email
        case createdAt = "created_at"
    }
}
