import Foundation
import SwiftUI
import CryptoKit

class VaultViewModel: ObservableObject {
    @Published var mnemonics: [EncryptedMnemonic] = []
    @Published var encryptedText: String = ""
    @Published var decryptedText: String = ""
    
    private let storageService = StorageService()
    private let encryptionService = EncryptionService()
    
    init() {
        refreshMnemonics()
    }
    
    func refreshMnemonics() {
        mnemonics = storageService.getAllMnemonics()
    }
    
    func encryptMnemonic(_ mnemonic: String, passphrase: String) {
        do {
            encryptedText = try encryptionService.encrypt(text: mnemonic, passphrase: passphrase)
        } catch {
            encryptedText = "Error: \(error.localizedDescription)"
        }
    }
    
    func decryptMnemonic(_ encryptedText: String, passphrase: String) {
        do {
            decryptedText = try encryptionService.decrypt(text: encryptedText, passphrase: passphrase)
        } catch {
            decryptedText = "Error: \(error.localizedDescription)"
        }
    }
    
    func decryptStoredMnemonic(_ mnemonic: EncryptedMnemonic, passphrase: String) {
        do {
            decryptedText = try encryptionService.decrypt(text: mnemonic.encryptedData, passphrase: passphrase)
            updateLastAccessed(for: mnemonic)
        } catch {
            decryptedText = "Error: \(error.localizedDescription)"
        }
    }
    
    func saveMnemonic(name: String, encryptedData: String) {
        let mnemonic = EncryptedMnemonic(name: name, encryptedData: encryptedData)
        storageService.saveMnemonic(mnemonic)
        refreshMnemonics()
    }
    
    func deleteMnemonic(_ mnemonic: EncryptedMnemonic) {
        storageService.deleteMnemonic(mnemonic)
        refreshMnemonics()
    }
    
    func updateLastAccessed(for mnemonic: EncryptedMnemonic) {
        storageService.updateLastAccessed(for: mnemonic)
    }
} 