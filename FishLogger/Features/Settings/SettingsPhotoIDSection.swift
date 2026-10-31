import SwiftUI

/// The Photo ID row on the main Settings page, showing Off, On, or No key. The switch, the key,
/// and the model live a level down, the way stock Settings keeps technical options out of the main list.
struct SettingsPhotoIDRow: View {
    @Environment(AppSettings.self) private var settings
    /// Read from the keychain when the row shows, including on the way back from the Photo ID page.
    @State private var hasSavedKey = false

    var body: some View {
        SettingsLinkRow("Photo ID", systemImage: "camera.viewfinder", color: .systemGray, value: status) {
            SettingsPhotoIDView()
        }
        .onAppear {
            hasSavedKey = KeychainStore.hasValue(for: .anthropicAPIKey)
        }
    }

    private var status: String {
        if !settings.photoIDEnabled { return "Off" }
        return hasSavedKey ? "On" : "No key"
    }
}

/// Photo ID switch, the Anthropic API key, and which Claude model to call.
/// The key lives in the keychain; this screen only ever shows its last four characters.
struct SettingsPhotoIDView: View {
    @Environment(AppSettings.self) private var settings
    @State private var keyDraft = ""
    @State private var hasSavedKey = false
    @State private var savedKeySuffix = ""
    @State private var modelDraft = ""
    @State private var showingSaveError = false
    @State private var confirmingRemove = false

    private static let consoleURL = URL(string: "https://console.anthropic.com")!

    var body: some View {
        @Bindable var settings = settings
        List {
            Section {
                Toggle("Photo ID", isOn: $settings.photoIDEnabled)
            } footer: {
                Text("Suggests the species from a photo, using Claude. Photos go to Anthropic only when you tap Identify. Each ID costs a few cents on your API account. The checklist works offline either way.")
            }

            if settings.photoIDEnabled {
                keySection
                advancedSection
            }
        }
        .settingsListStyle()
        .navigationTitle("Photo ID")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadState)
        // Picks up changes made elsewhere, such as Reset settings on the Data page.
        .onChange(of: settings.claudeModel) { _, newValue in
            syncModelDraft(newValue)
        }
        .alert("Could not save the key", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The keychain did not accept it. Try again.")
        }
    }

    // MARK: Sections

    private var keySection: some View {
        let keyPlaceholder: String = hasSavedKey ? "Paste a new key to replace it" : "Paste your Anthropic API key"
        return Section {
            LabeledContent("Key", value: savedKeyDescription)

            SecureField(keyPlaceholder, text: $keyDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { saveKey() }

            Button("Save key") {
                saveKey()
            }
            .disabled(trimmedKeyDraft.isEmpty)

            if hasSavedKey {
                Button("Remove key", role: .destructive) {
                    confirmingRemove = true
                }
                .confirmationDialog("Remove the API key?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                    Button("Remove key", role: .destructive) {
                        removeKey()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Photo ID stops working until you add a key again. The checklist still works.")
                }
            }

            Link("Get a key at console.anthropic.com", destination: Self.consoleURL)
        } header: {
            Text("Anthropic API key")
        } footer: {
            Text("Your key stays in this iPhone's keychain and is only sent to Anthropic.")
        }
    }

    private var advancedSection: some View {
        Section {
            LabeledContent("Model") {
                TextField(AppSettings.defaultClaudeModel, text: $modelDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                    .onChange(of: modelDraft) { _, newValue in
                        commitModelDraft(newValue)
                    }
            }
            Button("Use the default model") {
                resetModel()
            }
            .disabled(settings.claudeModel == AppSettings.defaultClaudeModel)
        } header: {
            Text("Advanced")
        } footer: {
            Text("Which Claude model Photo ID asks. Leave it on the default unless you have a reason to change it.")
        }
    }

    // MARK: Key

    private var savedKeyDescription: String {
        guard hasSavedKey else { return "Not saved" }
        return savedKeySuffix.isEmpty ? "Saved" : "Ends in \(savedKeySuffix)"
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

    /// No haptic on success: the Key row changing to "Ends in ..." is the confirmation.
    private func saveKey() {
        let key = trimmedKeyDraft
        guard !key.isEmpty else { return }
        if KeychainStore.set(key, for: .anthropicAPIKey) {
            keyDraft = ""
            loadKeyState()
        } else {
            showingSaveError = true
            Haptics.error()
        }
    }

    private func removeKey() {
        KeychainStore.set(nil, for: .anthropicAPIKey)
        keyDraft = ""
        loadKeyState()
        Haptics.warning()
    }

    // MARK: Model

    /// An empty field keeps the last model instead of snapping back to the default mid-edit.
    private func commitModelDraft(_ draft: String) {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != settings.claudeModel else { return }
        settings.claudeModel = trimmed
    }

    private func syncModelDraft(_ model: String) {
        if modelDraft.trimmingCharacters(in: .whitespacesAndNewlines) != model {
            modelDraft = model
        }
    }

    private func resetModel() {
        settings.claudeModel = AppSettings.defaultClaudeModel
        modelDraft = AppSettings.defaultClaudeModel
    }
}

#Preview {
    NavigationStack {
        SettingsPhotoIDView()
    }
    .environment(AppSettings.shared)
}
