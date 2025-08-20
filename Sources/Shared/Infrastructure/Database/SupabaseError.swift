import Foundation

public enum SupabaseError: Error {
    case missingConfiguration
    case invalidURL
    case connectionFailed
}