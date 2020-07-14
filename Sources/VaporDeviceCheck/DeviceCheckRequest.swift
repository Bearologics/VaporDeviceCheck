import Vapor

struct DeviceCheckRequest: Content {
    let deviceToken: String
    let transactionId: String = UUID().uuidString
    let timestamp: Int = Int(Date().timeIntervalSince1970 * 1000)
    
    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case transactionId = "transaction_id"
        case timestamp
    }
}
