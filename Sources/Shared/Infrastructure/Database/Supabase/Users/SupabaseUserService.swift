import Foundation
#if os(Linux)
import FoundationNetworking
#endif

@SupabaseActor
public final class SupabaseUserService: @unchecked Sendable {
    private let client: SupabaseClient

    public init(client: SupabaseClient = .shared) {
        self.client = client
    }

    public func createUser(auth0Id: String, name: String?, email: String?) async throws -> Bool {
        let body = UserCreateBody(auth0_id: auth0Id, name: name, email: email)
        let (_, response) = try await client.request(
            path: "users",
            method: "POST",
            body: body
        )
        return response.statusCode == 201
    }

    public func fetchUser(byAuth0Id id: String) async throws -> User? {
        let (data, response) = try await client.request(
            path: "users",
            query: "auth0_id=eq.\(id)"
        )
        guard response.statusCode == 200 else { return nil }
        
        // ✅ Fix: Custom date decoding for ISO8601 + fractional seconds
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = formatter.date(from: dateStr) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid date format"
                )
            }
            return date
        }
        
        let persistenceModel = try decoder.decode([UserPersistenceModel].self, from: data).first
        
        do {
              return try persistenceModel?.toDomainEntity()
          } catch {
              throw SupabaseError.dataCorruption(underlying: error)
          }
    }

    public func updateUser(_ user: User) async throws -> Bool {
        let persistenceModel = UserPersistenceModel.fromDomainEntity(user)
        let body = UserUpdateBody(name: persistenceModel.name, email: persistenceModel.email)
        
        let (_, response) = try await client.request(
            path: "users",
            method: "PATCH",
            query: "auth0_id=eq.\(persistenceModel.auth0_id)",
            body: body
        )
    return response.statusCode == 200 || response.statusCode == 204
}


    public func deleteUser(auth0Id: String) async throws -> Bool {
        let (_, response) = try await client.request(
            path: "users",
            method: "DELETE",
            query: "auth0_id=eq.\(auth0Id)"
        )
        return response.statusCode == 204
    }
}
