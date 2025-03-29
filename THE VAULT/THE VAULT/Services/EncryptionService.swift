import Foundation
import CryptoKit

class EncryptionService {
    enum EncryptionError: Error {
        case invalidKey
        case encryptionFailed
        case decryptionFailed
        case invalidData
    }
    
    // Derive a key from the passphrase
    private func deriveKey(from passphrase: String) throws -> SymmetricKey {
        let salt = "THE_VAULT_SALT".data(using: .utf8)!
        let keyData = passphrase.data(using: .utf8)!
        
        return SymmetricKey(data: SHA256.hash(data: keyData + salt))
    }
    
    // Encrypt text using AES-GCM
    func encrypt(text: String, passphrase: String) throws -> String {
        guard let textData = text.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        
        do {
            let key = try deriveKey(from: passphrase)
            let nonce = try AES.GCM.Nonce(data: Data(repeating: 0, count: 12))
            let sealedBox = try AES.GCM.seal(textData, using: key, nonce: nonce)
            
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            
            return combined.base64EncodedString()
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }
    
    // Decrypt text using AES-GCM
    func decrypt(text: String, passphrase: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: text) else {
            throw EncryptionError.invalidData
        }
        
        do {
            let key = try deriveKey(from: passphrase)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw EncryptionError.decryptionFailed
            }
            
            return decryptedString
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
} 