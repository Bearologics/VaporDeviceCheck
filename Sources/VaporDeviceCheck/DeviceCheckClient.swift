import Vapor

public protocol DeviceCheckClient {
    func request(_ request: Request, deviceToken: String, isSandbox: Bool) -> EventLoopFuture<ClientResponse>
}
