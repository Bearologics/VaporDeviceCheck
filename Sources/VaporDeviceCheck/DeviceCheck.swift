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
    let jwkKid: JWKIdentifier
    let jwkIss: String
    let excludes: [[PathComponent]]?
    
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
                
        return request.client.post(URI(string: "https://\(isSandbox ? "api.development" : "api").devicecheck.apple.com/v1/validate_device_token")) {
            $0.headers.add(name: .authorization, value: "Bearer \(try signedJwt(for: request))")
            return try $0.content.encode(DeviceCheckRequest(deviceToken: xAppleDeviceToken))
        }
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
        
    private func signedJwt(for request: Request) throws -> String {
        try request.jwt.sign(DeviceCheckJWT(iss: jwkIss), kid: jwkKid)
    }
}

private extension HTTPHeaders.Name {
    static let xAppleDeviceToken = HTTPHeaders.Name("X-Apple-Device-Token")
}

private struct DeviceCheckJWT: JWTPayload {
    let iss: String
    let iat: Int = Int(Date().timeIntervalSince1970)
    
    func verify(using signer: JWTSigner) throws {
        //no-op
    }
}
