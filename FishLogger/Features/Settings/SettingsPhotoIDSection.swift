import SwiftUI

/// Photo ID switch, the Anthropic API key, and which Claude model to call.
/// The key lives in the keychain; this screen only ever shows its last four characters.
struct SettingsPhotoIDSection: View {
    @Environment(AppSettings.self) private var settings
    @State private var keyDraft = ""
    @State private var hasSavedKey = false
    @State private var savedKeySuffix = ""
    @State private var modelDraft = ""
    @State private var showingSaveError = false

    private static let consoleURL = URL(string: "https://console.anthropic.com")!

    var body: some View {
        @Bindable var settings = settings
        let keyPlaceholder: String = hasSavedKey ? "Paste a new key to replace it" : "Paste your Anthropic API key"
        Section {
            Toggle("Identify fish from photos", isOn: $settings.photoIDEnabled)
                .onAppear(perform: loadState)

            if hasSavedKey {
                LabeledContent("Key saved", value: savedKeyDescription)
            }

            SecureField(keyPlaceholder, text: $keyDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { saveKey() }
                .alert("Could not save the key", isPresented: $showingSaveError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("The keychain did not accept it. Try again.")
                }

            HStack(spacing: 12) {
                Button {
                    saveKey()
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedKeyDraft.isEmpty)

                Button(role: .destructive) {
                    removeKey()
                } label: {
                    Text("Remove")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!hasSavedKey)
            }
            .controlSize(.large)

            HStack(spacing: 12) {
                Text("Model")
                TextField(AppSettings.defaultClaudeModel, text: $modelDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospaced())
                    .onChange(of: modelDraft) { _, newValue in
                        commitModelDraft(newValue)
                    }
                    .onChange(of: settings.claudeModel) { _, newValue in
                        syncModelDraft(newValue)
                    }
                Button("Reset") {
                    resetModel()
                }
                .buttonStyle(.borderless)
                .disabled(settings.claudeModel == AppSettings.defaultClaudeModel)
            }

            Link(destination: Self.consoleURL) {
                Label("Open console.anthropic.com", systemImage: "arrow.up.right.square")
            }
        } header: {
            Text("Photo ID")
        } footer: {
            Text("Photos go to Anthropic only when you tap Identify. Each ID costs a few cents on your API account. Get a key at console.anthropic.com.")
        }
    }

    private var savedKeyDescription: String {
        savedKeySuffix.isEmpty ? "Yes" : "Ends in \(savedKeySuffix)"
    }

    private var trimmedKeyDraft: String {
        keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadState() {
        loadKeyState()
        modelDraft = settings.claudeModel
    }

    private func loadKeyState() {
        let key = KeychainStore.string(for: .anthropicAPIKey) ?? ""
        hasSavedKey = !key.isEmpty
        // A key this short is not a real key, and showing four of its characters would show all of it.
        savedKeySuffix = key.count > 8 ? String(key.suffix(4)) : ""
    }

    private func saveKey() {
        let key = trimmedKeyDraft
        guard !key.isEmpty else { return }
        if KeychainStore.set(key, for: .anthropicAPIKey) {
            keyDraft = ""
            loadKeyState()
            Haptics.logged()
        } else {
            showingSaveError = true
            Haptics.error()
        }
    }

    private func removeKey() {
        KeychainStore.set(nil, for: .anthropicAPIKey)
        keyDraft = ""
        loadKeyState()
        Haptics.tap()
    }

    /// An empty field keeps the last model instead of snapping back to the default mid-edit.
    private func commitModelDraft(_ draft: String) {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != settings.claudeModel else { return }
        settings.claudeModel = trimmed
    }

    /// Picks up changes made elsewhere, such as Reset all settings.
    private func syncModelDraft(_ model: String) {
        if modelDraft.trimmingCharacters(in: .whitespacesAndNewlines) != model {
            modelDraft = model
        }
    }

    private func resetModel() {
        settings.claudeModel = AppSettings.defaultClaudeModel
        modelDraft = AppSettings.defaultClaudeModel
        Haptics.tap()
    }
}
