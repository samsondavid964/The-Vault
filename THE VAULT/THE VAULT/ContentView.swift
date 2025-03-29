//
//  ContentView.swift
//  THE VAULT
//
//  Created by Edafe on 18/03/2025.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Image(systemName: "lock.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 1 : 0)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text("THE VAULT")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                Text("Secure Your Mnemonics")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showMainApp = true
                }
            }
        }
        .opacity(showMainApp ? 0 : 1)
        .animation(.easeIn(duration: 0.3), value: showMainApp)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = VaultViewModel()
    @State private var selectedTab = 0
    @State private var showLaunchScreen = true
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                            withAnimation {
                                showLaunchScreen = false
                            }
                        }
                    }
            } else {
                TabView(selection: $selectedTab) {
                    EncryptView(viewModel: viewModel)
                        .tabItem {
                            Label("Encrypt", systemImage: "lock")
                        }
                        .tag(0)
                    
                    DecryptView(viewModel: viewModel)
                        .tabItem {
                            Label("Decrypt", systemImage: "lock.open")
                        }
                        .tag(1)
                    
                    VaultView()
                        .tabItem {
                            Label("Vault", systemImage: "lock.shield")
                        }
                        .tag(2)
                    
                    BlogView()
                        .tabItem {
                            Label("Blog", systemImage: "book")
                        }
                        .tag(3)
                }
                .accentColor(.blue)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTextField<Field: Hashable>: View {
    let title: String
    let text: Binding<String>
    let isSecure: Bool
    let focus: FocusState<Field?>.Binding
    let height: CGFloat
    let field: Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Group {
                if isSecure {
                    SecureField("", text: text)
                        .textContentType(.password)
                        .focused(focus, equals: field)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            focus.wrappedValue = nil
                        }
                } else {
                    TextEditor(text: text)
                        .focused(focus, equals: field)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            focus.wrappedValue = nil
                        }
                }
            }
            .frame(minHeight: height)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct CustomButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isEnabled: Bool
    let color: Color
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .padding(.trailing, 8)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: isEnabled ? [color, color.opacity(0.8)] : [Color.gray.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1 : 0.98)
        .animation(.spring(response: 0.3), value: isEnabled)
    }
}

struct EncryptView: View {
    @ObservedObject var viewModel: VaultViewModel
    @State private var mnemonic = ""
    @State private var passphrase = ""
    @State private var showingResult = false
    @State private var showingSaveDialog = false
    @State private var isEncrypting = false
    @State private var selectedInfoTab = 0
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    enum Field {
        case mnemonic, passphrase
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Security Banner
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                        Text("End-to-End Encrypted")
                            .font(.headline)
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    
                    // Main Content
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Secure Your Wallet")
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Protect your wallet's recovery phrase with strong encryption")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)
                        
                        // Info Tabs
                        VStack(spacing: 16) {
                            HStack {
                                Button(action: { selectedInfoTab = 0 }) {
                                    Text("What is this?")
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(selectedInfoTab == 0 ? Color.blue : Color.clear)
                                        .foregroundColor(selectedInfoTab == 0 ? .white : .primary)
                                        .cornerRadius(20)
                                }
                                
                                Button(action: { selectedInfoTab = 1 }) {
                                    Text("Security Tips")
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(selectedInfoTab == 1 ? Color.blue : Color.clear)
                                        .foregroundColor(selectedInfoTab == 1 ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
                            )
                            
                            // Info Content
                            VStack(alignment: .leading, spacing: 12) {
                                if selectedInfoTab == 0 {
                                    InfoView(
                                        title: "What is a Recovery Phrase?",
                                        description: "A recovery phrase (or mnemonic) is a series of 12 or 24 words that serves as a backup for your crypto wallet. Anyone with access to these words can control your funds.",
                                        icon: "key.fill"
                                    )
                                    InfoView(
                                        title: "Why Encrypt It?",
                                        description: "Encrypting your recovery phrase adds an extra layer of security. Even if someone finds your backup, they can't access your funds without the passphrase.",
                                        icon: "lock.shield.fill"
                                    )
                                } else {
                                    InfoView(
                                        title: "Use a Strong Passphrase",
                                        description: "Create a unique passphrase that's at least 12 characters long with a mix of letters, numbers, and symbols.",
                                        icon: "key.fill"
                                    )
                                    InfoView(
                                        title: "Store Safely",
                                        description: "Keep your encrypted backup and passphrase in separate, secure locations. Never share them with anyone.",
                                        icon: "folder.fill.badge.person.crop"
                                    )
                                }
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color.black : Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        // Input Fields
                        VStack(spacing: 24) {
                            // Mnemonic Input
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Recovery Phrase")
                                        .font(.headline)
                                    Spacer()
                                    Text("Required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                TextEditor(text: $mnemonic)
                                    .frame(height: 100)
                                    .padding(12)
                                    .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .overlay(
                                        Group {
                                            if mnemonic.isEmpty {
                                                Text("Enter your 12 or 24-word recovery phrase")
                                                    .foregroundColor(.gray.opacity(0.5))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 16)
                                            }
                                        }
                                    , alignment: .topLeading)
                                    .focused($focusedField, equals: .mnemonic)
                                
                                Text("Separate each word with a space")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Passphrase Input
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Encryption Passphrase")
                                        .font(.headline)
                                    Spacer()
                                    Text("Required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                SecureField("Create a strong passphrase", text: $passphrase)
                                    .textContentType(.newPassword)
                                    .padding(16)
                                    .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .focused($focusedField, equals: .passphrase)
                                
                                Text("This passphrase will be required to decrypt your backup")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Encrypt Button
                        Button(action: {
                            focusedField = nil
                            isEncrypting = true
                            viewModel.encryptMnemonic(mnemonic, passphrase: passphrase)
                            withAnimation(.spring()) {
                                showingResult = true
                            }
                        }) {
                            HStack {
                                if isEncrypting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 8)
                                }
                                Image(systemName: "lock.fill")
                                Text("Encrypt Securely")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                !mnemonic.isEmpty && !passphrase.isEmpty && !isEncrypting ?
                                Color.blue :
                                Color.gray.opacity(0.3)
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .disabled(mnemonic.isEmpty || passphrase.isEmpty || isEncrypting)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Encrypt Mnemonic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                ResultView(encryptedText: viewModel.encryptedText) {
                    showingSaveDialog = true
                }
            }
            .alert("Save to Vault", isPresented: $showingSaveDialog) {
                TextField("Name", text: .constant(""))
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    withAnimation(.spring()) {
                        viewModel.saveMnemonic(name: "Encrypted Mnemonic", encryptedData: viewModel.encryptedText)
                    }
                }
            } message: {
                Text("Enter a name for this mnemonic")
            }
        }
    }
}

struct InfoView: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct DecryptView: View {
    @ObservedObject var viewModel: VaultViewModel
    @State private var encryptedText = ""
    @State private var passphrase = ""
    @State private var showingResult = false
    @State private var isDecrypting = false
    @State private var selectedInfoTab = 0
    @FocusState private var focusedField: Field?
    @Environment(\.colorScheme) private var colorScheme
    
    enum Field {
        case encryptedText, passphrase
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Security Banner
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                        Text("Secure Decryption")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    
                    // Main Content
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Decrypt Your Backup")
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Restore access to your wallet's recovery phrase")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)
                        
                        // Info Tabs
                        VStack(spacing: 16) {
                            HStack {
                                Button(action: { selectedInfoTab = 0 }) {
                                    Text("Instructions")
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(selectedInfoTab == 0 ? Color.blue : Color.clear)
                                        .foregroundColor(selectedInfoTab == 0 ? .white : .primary)
                                        .cornerRadius(20)
                                }
                                
                                Button(action: { selectedInfoTab = 1 }) {
                                    Text("Security Tips")
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(selectedInfoTab == 1 ? Color.blue : Color.clear)
                                        .foregroundColor(selectedInfoTab == 1 ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
                            )
                            
                            // Info Content
                            VStack(alignment: .leading, spacing: 12) {
                                if selectedInfoTab == 0 {
                                    InfoView(
                                        title: "How to Decrypt",
                                        description: "Enter your encrypted backup text and the passphrase you used to encrypt it. Make sure you're in a private location when viewing the decrypted phrase.",
                                        icon: "key.fill"
                                    )
                                    InfoView(
                                        title: "Verify the Result",
                                        description: "After decryption, verify that your recovery phrase contains exactly 12 or 24 words. Each word should be from the BIP39 word list.",
                                        icon: "checkmark.shield.fill"
                                    )
                                } else {
                                    InfoView(
                                        title: "Private Environment",
                                        description: "Ensure no one can see your screen or camera while viewing your recovery phrase.",
                                        icon: "eye.slash.fill"
                                    )
                                    InfoView(
                                        title: "Clear History",
                                        description: "After restoring your wallet, clear your clipboard and close this app.",
                                        icon: "trash.fill"
                                    )
                                }
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color.black : Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        // Input Fields
                        VStack(spacing: 24) {
                            // Encrypted Text Input
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Encrypted Backup")
                                        .font(.headline)
                                    Spacer()
                                    Text("Required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                TextEditor(text: $encryptedText)
                                    .frame(height: 100)
                                    .padding(12)
                                    .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .overlay(
                                        Group {
                                            if encryptedText.isEmpty {
                                                Text("Paste your encrypted backup text here")
                                                    .foregroundColor(.gray.opacity(0.5))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 16)
                                            }
                                        }
                                    , alignment: .topLeading)
                                    .focused($focusedField, equals: .encryptedText)
                                
                                Text("This is the encrypted text you saved previously")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Passphrase Input
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Decryption Passphrase")
                                        .font(.headline)
                                    Spacer()
                                    Text("Required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                SecureField("Enter your passphrase", text: $passphrase)
                                    .textContentType(.password)
                                    .padding(16)
                                    .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .focused($focusedField, equals: .passphrase)
                                
                                Text("Use the same passphrase you used for encryption")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Decrypt Button
                        Button(action: {
                            focusedField = nil
                            isDecrypting = true
                            viewModel.decryptMnemonic(encryptedText, passphrase: passphrase)
                            withAnimation(.spring()) {
                                showingResult = true
                            }
                        }) {
                            HStack {
                                if isDecrypting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 8)
                                }
                                Image(systemName: "lock.open.fill")
                                Text("Decrypt Securely")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                !encryptedText.isEmpty && !passphrase.isEmpty && !isDecrypting ?
                                Color.blue :
                                Color.gray.opacity(0.3)
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .disabled(encryptedText.isEmpty || passphrase.isEmpty || isDecrypting)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Decrypt Mnemonic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                ResultView(encryptedText: viewModel.decryptedText)
            }
        }
    }
}

struct ResultView: View {
    let encryptedText: String
    var onSave: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var isCopied = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    Text("Result")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding()
                    
                    Text(encryptedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            UIPasteboard.general.string = encryptedText
                            withAnimation {
                                isCopied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    isCopied = false
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text(isCopied ? "Copied!" : "Copy")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        if let onSave = onSave {
                            Button(action: onSave) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
