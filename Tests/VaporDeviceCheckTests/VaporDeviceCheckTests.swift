import JWT
import XCTVapor
@testable import VaporDeviceCheck

final class VaporDeviceCheckTests: XCTestCase {
    var app: Application!
    
    override func setUp() {
        app = Application(.testing)
    }
    
    override func tearDown() {
        app.shutdown()
        app = nil
    }
    
    func testExcludesRoutes() throws {
        app.middleware.use(
            DeviceCheck(
                jwkKid: JWKIdentifier(string: "123456"),
                jwkIss: "Test",
                excludes: [["health"]]
            )
        )
        
        app.get("health") { req in
            return "OK"
        }
        
        try app.test(.GET, "health") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
    
    func testBailsOutIfNoDeviceTokenIsProvided() throws {
        app.middleware.use(
            DeviceCheck(
                jwkKid: JWKIdentifier(string: "123456"),
                jwkIss: "Test",
                excludes: [["health"]]
            )
        )
        
        app.get("check") { req in
            return "OK"
        }
        
        try app.test(.GET, "check") { res in
            XCTAssertEqual(res.status, .internalServerError)
            XCTAssertTrue(res.body.string.contains("NoAppleDeviceTokenError.NoAppleDeviceTokenError: No X-Apple-Device-Token header provided."))
        }
    }
    
    func testAcceptsValidDeviceTokenHeader() throws {
        app.middleware.use(
            DeviceCheck(
                jwkKid: JWKIdentifier(string: "123456"),
                jwkIss: "Test",
                excludes: [["health"]],
                client: FakeDeviceCheckClient(isSuccessful: true)
            )
        )
        
        app.get("check") { req in
            return "OK"
        }
        
        try app.test(.GET, "check", headers: ["X-Apple-Device-Token": "123"]) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
    
    func testRejectsInvalidDeviceTokenHeader() throws {
        app.middleware.use(
            DeviceCheck(
                jwkKid: JWKIdentifier(string: "123456"),
                jwkIss: "Test",
                excludes: [["health"]],
                client: FakeDeviceCheckClient(isSuccessful: false)
            )
        )
        
        app.get("check") { req in
            return "OK"
        }
        
        try app.test(.GET, "check", headers: ["X-Apple-Device-Token": "123"]) { res in
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    static var allTests = [
        ("testExcludesRoutes", testExcludesRoutes),
        ("testBailsOutIfNoDeviceTokenIsProvided", testBailsOutIfNoDeviceTokenIsProvided),
        ("testAcceptsValidDeviceTokenHeader", testAcceptsValidDeviceTokenHeader),
        ("testRejectsInvalidDeviceTokenHeader", testRejectsInvalidDeviceTokenHeader)
    ]
}
