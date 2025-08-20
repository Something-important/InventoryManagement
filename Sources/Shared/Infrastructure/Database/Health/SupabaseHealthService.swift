import Foundation
#if os(Linux)
import FoundationNetworking
#endif

/// Request body for the health check upsert
private struct HealthCheckUpsertBody: Encodable {
    let checked_at: String
}

@SupabaseActor
public final class SupabaseHealthService: @unchecked Sendable {
    private let client: SupabaseClient
    
    public init(client: SupabaseClient = .shared) {
        self.client = client
    }
    
    /// Upserts (insert if not exists, else update) health check record
    public func upsertHealthCheck() async throws -> Bool {
        var headers: [String: String] = [:]
        headers["Prefer"] = "resolution=merge-duplicates"
        
        // Build request body using a Codable struct
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let body = HealthCheckUpsertBody(
            checked_at: formatter.string(from: Date())
        )
        
        let (data, response) = try await client.request(
            path: "health_check",
            method: "PATCH",
            query: "id=eq.1",
            body: body,
            extraHeaders: headers
        )
        
        print("🔄 Upsert response: Status=\(response.statusCode), Data=\(String(data: data, encoding: .utf8) ?? "none")")
        return response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 204
    }
    
    /// Checks if the system is healthy based on the latest record
    public func checkHealth() async throws -> Bool {
        let (data, response) = try await client.request(
            path: "health_check",
            query: "select=checked_at&order=checked_at.desc&limit=1"
        )
        
        print("🔍 Health check response: Status=\(response.statusCode), Data=\(String(data: data, encoding: .utf8) ?? "none")")
        
        guard response.statusCode == 200 else { return false }
        
        let results = try JSONDecoder().decode([[String: String]].self, from: data)
        guard let latestCheckStr = results.first?["checked_at"] else { return false }
        
        // Parse the timestamp
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let latestCheck = formatter.date(from: latestCheckStr) else { return false }
        
        // Check if the timestamp is within the last minute
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        return latestCheck > oneMinuteAgo
    }
}

