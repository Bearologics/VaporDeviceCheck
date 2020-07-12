import Vapor
import VaporDeviceCheck

struct FakeDeviceCheckClient: DeviceCheckClient {
    let isSuccessful: Bool
    
    func request(_ request: Request, xAppleDeviceToken: String, isSandbox: Bool) -> EventLoopFuture<ClientResponse> {
        if isSuccessful {
            return request.eventLoop.makeSucceededFuture(ClientResponse(status: .ok, headers: request.headers, body: nil))
        } else {
            return request.eventLoop.makeSucceededFuture(ClientResponse(status: .unauthorized, headers: request.headers, body: nil))
        }
    }
}
