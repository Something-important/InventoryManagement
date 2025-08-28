import Foundation
#if os(Linux)
import FoundationNetworking
#endif

@SupabaseActor
public final class SupabaseTokenValidator {
    
    public init() {}
    
    public func validateToken(_ token: String) async -> TokenValidationResult {
        // Access SupabaseClient within the SupabaseActor context
        let supabaseClient = SupabaseClient.shared
        
        // Use the SupabaseClient to make the request
        let url = supabaseClient.buildURL(for: "")
        
        print("🔍 Making request to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(supabaseClient.apiKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        print("📤 Request headers:")
        print("Authorization: Bearer [token hidden]")
        print("apikey: [key hidden]")
        
        do {
            let (data, response) = try await supabaseClient.session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return .failure(.invalidResponse)
            }
            
            print("📥 Response status code: \(httpResponse.statusCode)")
            
            // Check if Supabase accepts the token
            print("\nStep 1: Verifying token with Supabase...")
            if !(200...299).contains(httpResponse.statusCode) {
                print("❌ Token verification failed")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("Error: \(errorText)")
                }
                return .failure(.verificationFailed)
            }
            print("✅ Supabase verified the token")
            
            let responseText = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            return .success(supabaseResponse: responseText)
            
        } catch {
            print("❌ Network error: \(error)")
            if let urlError = error as? URLError {
                print("URL Error code: \(urlError.code)")
                print("URL Error description: \(urlError.localizedDescription)")
            }
            return .failure(.networkError)
        }
    }
}

// MARK: - Result Types
public enum TokenValidationResult: Sendable {
    case success(supabaseResponse: String)
    case failure(TokenValidationError)
}

public enum TokenValidationError: Error, Sendable {
    case invalidResponse
    case verificationFailed
    case networkError
}
