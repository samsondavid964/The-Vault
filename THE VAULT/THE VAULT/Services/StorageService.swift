import Foundation

class StorageService {
    private let userDefaults = UserDefaults.standard
    private let key = "encrypted_mnemonics"
    
    func saveMnemonic(_ mnemonic: EncryptedMnemonic) {
        var mnemonics = getAllMnemonics()
        mnemonics.append(mnemonic)
        save(mnemonics)
    }
    
    func getAllMnemonics() -> [EncryptedMnemonic] {
        guard let data = userDefaults.data(forKey: key),
              let mnemonics = try? JSONDecoder().decode([EncryptedMnemonic].self, from: data) else {
            return []
        }
        return mnemonics
    }
    
    func deleteMnemonic(_ mnemonic: EncryptedMnemonic) {
        var mnemonics = getAllMnemonics()
        mnemonics.removeAll { $0.id == mnemonic.id }
        save(mnemonics)
    }
    
    func updateLastAccessed(for mnemonic: EncryptedMnemonic) {
        var mnemonics = getAllMnemonics()
        if let index = mnemonics.firstIndex(where: { $0.id == mnemonic.id }) {
            var updatedMnemonic = mnemonic
            updatedMnemonic.lastAccessed = Date()
            mnemonics[index] = updatedMnemonic
            save(mnemonics)
        }
    }
    
    private func save(_ mnemonics: [EncryptedMnemonic]) {
        if let encoded = try? JSONEncoder().encode(mnemonics) {
            userDefaults.set(encoded, forKey: key)
        }
    }
} 