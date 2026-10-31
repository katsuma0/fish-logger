import Foundation
import Security

/// Small wrapper around the keychain for the Anthropic API key. Keys never go in UserDefaults.
enum KeychainStore {
    private static let service = "ca.katsumaonishi.FishLogger"

    enum Account: String {
        case anthropicAPIKey = "anthropic-api-key"
    }

    static func string(for account: Account) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }
        return value
    }

    @discardableResult
    static func set(_ value: String?, for account: Account) -> Bool {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        SecItemDelete(baseQuery(account) as CFDictionary)
        guard !trimmed.isEmpty else { return true }
        var item = baseQuery(account)
        item[kSecValueData as String] = Data(trimmed.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    static func hasValue(for account: Account) -> Bool { string(for: account) != nil }

    private static func baseQuery(_ account: Account) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue
        ]
    }
}
