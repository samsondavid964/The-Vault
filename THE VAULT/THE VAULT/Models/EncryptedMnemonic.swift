import Foundation

struct EncryptedMnemonic: Codable, Identifiable {
    let id: UUID
    let name: String
    let encryptedData: String
    let createdAt: Date
    var lastAccessed: Date
    
    init(name: String, encryptedData: String) {
        self.id = UUID()
        self.name = name
        self.encryptedData = encryptedData
        self.createdAt = Date()
        self.lastAccessed = Date()
    }
} 