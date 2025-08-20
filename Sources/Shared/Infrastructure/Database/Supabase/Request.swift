import Foundation
#if os(Linux)
import FoundationNetworking
#endif

@SupabaseActor
extension SupabaseClient {
    public func request(
        path: String,
        method: String = "GET",
        query: String? = nil,
        body: Encodable? = nil,
        extraHeaders: [String: String]? = nil // ✅ New parameter for custom headers
    ) async throws -> (Data, HTTPURLResponse) {
        
        // Build full path with optional query string
        var fullPath = path
        if let query, !query.isEmpty {
            fullPath += "?\(query)"
        }
        
        // Create the request URL
        let url = buildURL(for: fullPath)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Required Supabase auth headers
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        // Optional extra headers
        if let headers = extraHeaders {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // JSON encode body if provided
        if let body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.connectionFailed
        }
        
        return (data, httpResponse)
    }
}
