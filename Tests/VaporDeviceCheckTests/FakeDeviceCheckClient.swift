import Vapor
import VaporDeviceCheck

struct FakeDeviceCheckClient: DeviceCheckClient {
    func request(_ request: Request, deviceToken: String, isSandbox: Bool) -> EventLoopFuture<ClientResponse> {
        if deviceToken == "C0RR3CT" {
            return request.eventLoop.makeSucceededFuture(ClientResponse(status: .ok, headers: request.headers, body: nil))
        } else {
            return request.eventLoop.makeSucceededFuture(ClientResponse(status: .unauthorized, headers: request.headers, body: nil))
        }
    }
}
