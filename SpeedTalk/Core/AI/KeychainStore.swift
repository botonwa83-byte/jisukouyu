import Foundation
import Security

/// API 密钥存储。
///
/// 只在本机保存，可访问性 `WhenUnlockedThisDeviceOnly`，不进 iCloud 钥匙串备份。
/// 出错抛错而不是吞掉，让设置页能明确告知保存失败。
enum KeychainStore {
    private static let service = "com.speedtalk.app.api"

    enum KeychainError: LocalizedError {
        case unexpectedStatus(OSStatus)
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .unexpectedStatus(let status): return "钥匙串操作失败（状态 \(status)）"
            case .encodingFailed: return "密钥编码失败"
            }
        }
    }

    static func save(_ value: String, account: String = "apiKey") throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.encodingFailed }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // 先删后写，避免重复项
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query.merging([kSecValueData as String: data]) { _, new in new } as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    static func read(account: String = "apiKey") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String = "apiKey") {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
