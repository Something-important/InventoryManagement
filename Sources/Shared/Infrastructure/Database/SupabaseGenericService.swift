import Foundation

@SupabaseActor
public final class SupabaseGenericService: @unchecked Sendable {
    private let client: SupabaseClient
    
    public init(client: SupabaseClient = .shared) {
        self.client = client
    }
    
    public func fetch<T: Decodable>(from table: String) async throws -> [T] {
        let (data, response) = try await client.request(path: table)
        
        guard response.statusCode == 200 else {
            throw SupabaseError.connectionFailed
        }
        
        return try JSONDecoder().decode([T].self, from: data)
    }
}
