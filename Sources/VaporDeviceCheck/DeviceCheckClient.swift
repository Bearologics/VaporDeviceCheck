import Vapor

public protocol DeviceCheckClient {
    func request(_ request: Request, xAppleDeviceToken: String, isSandbox: Bool) -> EventLoopFuture<ClientResponse>
}
