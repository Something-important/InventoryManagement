import XCTest
@testable import InventoryManagement

final class SupabaseClientTests: XCTestCase {
    
    private var healthService: SupabaseHealthService!
    private var genericService: SupabaseGenericService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use the actual shared client (env vars must already be set before tests run)
        healthService = await SupabaseHealthService(client: .shared)
        genericService = await SupabaseGenericService(client: .shared)
        
        print("✅ Test setup: Using Supabase URL: \(ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "MISSING")")
    }
    
    func testCreateHealthCheckAndFetch() async throws {
        print("🔍 Starting Health Check Integration Test")
        
        // 1. Create or verify health check table/row
        let created = try await healthService.upsertHealthCheck()
        print("📦 upsertHealthCheck() returned: \(created)")
        XCTAssertTrue(created, "Should create or update the health check record")
        
        // 2. Check latest health status
        let healthy = try await healthService.checkHealth()
        print("💚 checkHealth() returned: \(healthy)")
        XCTAssertTrue(healthy, "Latest health check should be healthy")
        
        // 3. Fetch records from the health_check table via GenericService
        let records: [HealthCheck] = try await genericService.fetch(from: "health_check")
        print("📊 Fetched \(records.count) record(s) from 'health_check': \(records)")
        
        XCTAssertFalse(records.isEmpty, "Should have at least one record")
        
        // Check if the latest record is recent (within the last minute)
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        XCTAssertTrue(records[0].checkedAt > oneMinuteAgo, "Latest record should be recent (within last minute)")
        
        print("✅ Integration Test completed successfully")
    }
}

// MARK: - Test helper model for decoding
struct HealthCheck: Codable {
    let id: Int
    let checkedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case checkedAt = "checked_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        
        let dateString = try container.decode(String.self, forKey: .checkedAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .checkedAt,
                in: container,
                debugDescription: "Invalid date format"
            )
        }
        checkedAt = date
    }
}
