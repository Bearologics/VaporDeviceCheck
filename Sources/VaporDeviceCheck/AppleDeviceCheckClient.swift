import Vapor
import JWT

public struct AppleDeviceCheckClient: DeviceCheckClient {
    public let jwkKid: JWKIdentifier
    public let jwkIss: String
    
    public func request(_ request: Request, deviceToken: String, isSandbox: Bool) -> EventLoopFuture<ClientResponse> {
        request.client.post(URI(string: "https://\(isSandbox ? "api.development" : "api").devicecheck.apple.com/v1/validate_device_token")) {
            $0.headers.add(name: .authorization, value: "Bearer \(try signedJwt(for: request))")
            return try $0.content.encode(DeviceCheckRequest(deviceToken: deviceToken))
        }
    }
    
    private func signedJwt(for request: Request) throws -> String {
        try request.jwt.sign(DeviceCheckJWT(iss: jwkIss), kid: jwkKid)
    }
}

private struct DeviceCheckJWT: JWTPayload {
    let iss: String
    let iat: Int = Int(Date().timeIntervalSince1970)
    
    func verify(using signer: JWTSigner) throws {
        //no-op
    }
}
