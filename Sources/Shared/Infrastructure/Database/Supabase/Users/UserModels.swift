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
struct UserPersistenceModel: Codable {
let id: Int
let auth0_id: String
let name: String?
let email: String?
let created_at: Date

// Mapping to/from Domain Entity
func toDomainEntity() throws -> User {
    let identifier = try UserIdentifier(auth0_id)
    let profile = try UserProfile(name: name, email: email)
    let authInfo = AuthenticationInfo(externalId: auth0_id, isVerified: true, expiresAt: nil)

    return User(
        identifier: identifier,
        profile: profile,
        authenticationInfo: authInfo,
        registrationDate: created_at
    )
}

static func fromDomainEntity(_ user: User) -> UserPersistenceModel {
    return UserPersistenceModel(
        id: 0, // Will be set by database
        auth0_id: user.identifier.value,
        name: user.profile.name,
        email: user.profile.email,
        created_at: user.registrationDate
    )
}
}
