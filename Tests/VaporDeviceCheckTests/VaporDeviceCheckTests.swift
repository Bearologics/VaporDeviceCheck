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
    
    func testNoDeviceTokenIsProvided_andBailsOut() throws {
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
    
    func testAcceptsValidDeviceTokenHeader_andPerformsNextRequest() throws {
        app.middleware.use(
            DeviceCheck(
                jwkKid: JWKIdentifier(string: "123456"),
                jwkIss: "Test",
                excludes: [["health"]],
                client: FakeDeviceCheckClient(isSuccessful: true)
            )
        )
        
        app.get("check") { req in
            return "OkeyDokey"
        }
        
        try app.test(.GET, "check", headers: ["X-Apple-Device-Token": "123"]) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "OkeyDokey")
        }
    }
    
    func testRejectsInvalidDeviceTokenHeader_andBailsOut() throws {
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
            XCTAssertNotEqual(res.body.string, "OK")
        }
    }

    static var allTests = [
        ("testExcludesRoutes", testExcludesRoutes),
        ("testBailsOutIfNoDeviceTokenIsProvided", testNoDeviceTokenIsProvided_andBailsOut),
        ("testAcceptsValidDeviceTokenHeader", testAcceptsValidDeviceTokenHeader_andPerformsNextRequest),
        ("testRejectsInvalidDeviceTokenHeader", testRejectsInvalidDeviceTokenHeader_andBailsOut)
    ]
}
