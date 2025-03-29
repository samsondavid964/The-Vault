import SwiftUI

struct VaultView: View {
    @StateObject private var viewModel = VaultViewModel()
    @State private var showingDeleteAlert = false
    @State private var mnemonicToDelete: EncryptedMnemonic?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.mnemonics) { mnemonic in
                    VaultItemView(mnemonic: mnemonic, viewModel: viewModel) {
                        mnemonicToDelete = mnemonic
                        showingDeleteAlert = true
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        mnemonicToDelete = viewModel.mnemonics[index]
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle("Vault")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            isRefreshing = true
                            viewModel.refreshMnemonics()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isRefreshing = false
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(.linear(duration: 0.5).repeatCount(1, autoreverses: false), value: isRefreshing)
                    }
                }
            }
            .alert("Delete Mnemonic", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let mnemonic = mnemonicToDelete {
                        withAnimation(.spring()) {
                            viewModel.deleteMnemonic(mnemonic)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this mnemonic? This action cannot be undone.")
            }
        }
    }
}

struct VaultItemView: View {
    let mnemonic: EncryptedMnemonic
    let viewModel: VaultViewModel
    let onDelete: () -> Void
    @State private var showingDecryptedContent = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(mnemonic.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(mnemonic.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring()) {
                        showingDecryptedContent = true
                    }
                }) {
                    Label("View", systemImage: "eye.fill")
                        .foregroundColor(.blue)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
                
                Spacer()
                
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash.fill")
                        .foregroundColor(.red)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingDecryptedContent) {
            DecryptedMnemonicView(mnemonic: mnemonic, viewModel: viewModel)
        }
    }
}

struct DecryptedMnemonicView: View {
    let mnemonic: EncryptedMnemonic
    let viewModel: VaultViewModel
    @Environment(\.dismiss) var dismiss
    @State private var passphrase = ""
    @State private var decryptedText = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isDecrypting = false
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                SecureField("Enter Passphrase", text: $passphrase)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .frame(height: 44)
                
                if !decryptedText.isEmpty {
                    ScrollView {
                        Text(decryptedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                
                Button(action: decryptMnemonic) {
                    HStack {
                        if isDecrypting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text("Decrypt")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .scaleEffect(buttonScale)
                }
                .padding(.horizontal)
                .disabled(passphrase.isEmpty || isDecrypting)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in buttonScale = 0.98 }
                        .onEnded { _ in buttonScale = 1.0 }
                )
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Decrypt Mnemonic")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func decryptMnemonic() {
        withAnimation(.spring()) {
            isDecrypting = true
            viewModel.decryptStoredMnemonic(mnemonic, passphrase: passphrase)
            decryptedText = viewModel.decryptedText
            if decryptedText.hasPrefix("Error:") {
                errorMessage = decryptedText
                showingError = true
            }
            isDecrypting = false
        }
    }
}

#Preview {
    VaultView()
} 