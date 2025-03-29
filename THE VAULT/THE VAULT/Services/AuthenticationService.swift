import Foundation
import LocalAuthentication

class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            self.error = error
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock THE VAULT"
            )
            
            await MainActor.run {
                self.isAuthenticated = success
            }
            
            return success
        } catch {
            await MainActor.run {
                self.error = error
            }
            return false
        }
    }
} 