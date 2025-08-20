import Foundation
#if os(Linux)
import FoundationNetworking
#endif

@globalActor public actor SupabaseActor {
    public static let shared = SupabaseActor()
}

@SupabaseActor
public final class SupabaseClient: @unchecked Sendable {
    public static let shared = SupabaseClient()
    
    private var supabaseUrl: String
    private var supabaseKey: String
    internal let session: URLSession
    private var isInitialized: Bool = false
    
    private init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        
        guard let url = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let key = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_KEY"] else {
            fatalError("Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables.")
        }
        
        self.supabaseUrl = url
        self.supabaseKey = key
        self.isInitialized = true
    }
    
    internal var apiKey: String {
        supabaseKey
    }
    
    internal func buildURL(for path: String) -> URL {
        URL(string: "\(supabaseUrl)/rest/v1/\(path)")!
    }
}