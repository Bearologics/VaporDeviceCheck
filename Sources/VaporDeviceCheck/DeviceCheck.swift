import Vapor
import JWT

public struct DeviceCheckRequest: Content {
    let deviceToken: String
    let transactionId: String = UUID().uuidString
    let timestamp: Int = Int(Date().timeIntervalSince1970 * 1000)
    
    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case transactionId = "transaction_id"
        case timestamp
    }
}

public struct NoAppleDeviceTokenError: DebuggableError {
    public var identifier: String = "NoAppleDeviceTokenError"
    public var reason: String = "No X-Apple-Device-Token header provided."
}

public struct DeviceCheck: Middleware {
    let excludes: [[PathComponent]]?
    let client: DeviceCheckClient
    
    public init(jwkKid: JWKIdentifier, jwkIss: String, excludes: [[PathComponent]]? = nil, client: DeviceCheckClient? = nil) {
        self.excludes = excludes
        self.client = client ?? AppleDeviceCheckClient(jwkKid: jwkKid, jwkIss: jwkIss)
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        requestDeviceCheck(on: request, chainingTo: next, isSandbox: false)
    }

    private func requestDeviceCheck(on request: Request, chainingTo next: Responder, isSandbox: Bool) -> EventLoopFuture<Response> {
        if excludes?.map({ $0.string }).contains(where: { $0 == request.route?.path.string }) ?? false {
            return next.respond(to: request)
        }
        
        guard let xAppleDeviceToken = request.headers.first(name: .xAppleDeviceToken) else {
            return request.eventLoop.makeFailedFuture(NoAppleDeviceTokenError())
        }
                
        return client.request(request, deviceToken: xAppleDeviceToken, isSandbox: isSandbox)
            .flatMap { res in
                if res.status == .ok {
                    return next.respond(to: request)
                }
                
                if isSandbox {
                    return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
                }
                
                return self.requestDeviceCheck(on: request, chainingTo: next, isSandbox: true)
        }
    }
}
