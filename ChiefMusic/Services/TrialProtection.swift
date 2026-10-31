import Foundation
import Security
import CryptoKit
import IOKit

// MARK: - Trial Protection Service
// Multi-layer trial protection to prevent easy bypass
class TrialProtection {
    static let shared = TrialProtection()

    private let keychainService = "com.chiefmusic.trial"
    private let keychainAccount = "trial_data"
    private let hiddenFileMarker = ".cm_trial_marker"

    private init() {}

    // MARK: - Trial Start Recording
    func recordTrialStart() -> Date {
        let now = Date()

        // Layer 1: Keychain (hardest to delete)
        saveToKeychain(date: now)

        // Layer 2: Hidden file in system location
        saveToHiddenFile(date: now)

        // Layer 3: UserDefaults (easiest to delete, but we check others first)
        UserDefaults.standard.set(now, forKey: "ChiefMusic_TrialStart")

        return now
    }

    // MARK: - Trial Start Retrieval
    func getTrialStartDate() -> Date? {
        // Priority: Keychain > Hidden File > UserDefaults
        // Use the EARLIEST date found (prevents reset attacks)

        var dates: [Date] = []

        // Check Keychain
        if let keychainDate = loadFromKeychain() {
            dates.append(keychainDate)
        }

        // Check Hidden File
        if let fileDate = loadFromHiddenFile() {
            dates.append(fileDate)
        }

        // Check UserDefaults
        if let defaultsDate = UserDefaults.standard.object(forKey: "ChiefMusic_TrialStart") as? Date {
            dates.append(defaultsDate)
        }

        // Return earliest date (most conservative approach)
        return dates.min()
    }

    // MARK: - Trial Validation
    func isTrialValid() -> (valid: Bool, daysRemaining: Int) {
        guard let startDate = getTrialStartDate() else {
            // No trial record found - this is first launch
            return (valid: true, daysRemaining: 7)
        }

        let daysPassed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let daysRemaining = max(0, 7 - daysPassed)

        return (valid: daysRemaining > 0, daysRemaining: daysRemaining)
    }

    // MARK: - Keychain Storage
    private func saveToKeychain(date: Date) {
        let data = try! JSONEncoder().encode(date)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let date = try? JSONDecoder().decode(Date.self, from: data) else {
            return nil
        }

        return date
    }

    // MARK: - Hidden File Storage
    private func getHiddenFilePath() -> URL? {
        // Store in Application Support (survives app deletion but not system reinstall)
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let chiefMusicDir = appSupport.appendingPathComponent("ChiefMusic", isDirectory: true)
        try? FileManager.default.createDirectory(at: chiefMusicDir, withIntermediateDirectories: true)

        return chiefMusicDir.appendingPathComponent(hiddenFileMarker)
    }

    private func saveToHiddenFile(date: Date) {
        guard let filePath = getHiddenFilePath() else { return }

        let data = try! JSONEncoder().encode(date)
        try? data.write(to: filePath, options: .atomic)

        // Make file hidden
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: filePath.path)
    }

    private func loadFromHiddenFile() -> Date? {
        guard let filePath = getHiddenFilePath(),
              let data = try? Data(contentsOf: filePath),
              let date = try? JSONDecoder().decode(Date.self, from: data) else {
            return nil
        }

        return date
    }

    // MARK: - Hardware Fingerprint
    func getHardwareFingerprint() -> String {
        // Combine multiple hardware identifiers
        var components: [String] = []

        // Serial number
        if let serial = getSerialNumber() {
            components.append(serial)
        }

        // Platform UUID
        if let uuid = getPlatformUUID() {
            components.append(uuid)
        }

        // MAC address (primary network interface)
        if let mac = getMACAddress() {
            components.append(mac)
        }

        let combined = components.joined(separator: "-")
        let hash = SHA256.hash(data: Data(combined.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func getSerialNumber() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(platformExpert) }

        guard platformExpert != 0 else { return nil }

        return IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformSerialNumberKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeUnretainedValue() as? String
    }

    private func getPlatformUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(platformExpert) }

        guard platformExpert != 0 else { return nil }

        return IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeUnretainedValue() as? String
    }

    private func getMACAddress() -> String? {
        // Get MAC address of primary network interface
        var macAddress: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)

            // Look for en0 (primary ethernet/wifi)
            if name == "en0" {
                let addrCopy = interface.ifa_addr.pointee
                if addrCopy.sa_family == UInt8(AF_LINK) {
                    let data = withUnsafeBytes(of: addrCopy) { bytes in
                        Data(bytes)
                    }

                    // Extract MAC address bytes
                    if data.count >= 20 {
                        let macBytes = data.subdata(in: 14..<20)
                        macAddress = macBytes.map { String(format: "%02x", $0) }.joined(separator: ":")
                    }
                }
            }
        }

        return macAddress
    }

    // MARK: - Reset Protection
    func detectResetAttempt() -> Bool {
        // Check if UserDefaults was cleared but Keychain/File still exist
        let hasKeychainData = loadFromKeychain() != nil
        let hasFileData = loadFromHiddenFile() != nil
        let hasUserDefaultsData = UserDefaults.standard.object(forKey: "ChiefMusic_TrialStart") != nil

        // If Keychain or File exists but UserDefaults is missing, it's likely a reset attempt
        if (hasKeychainData || hasFileData) && !hasUserDefaultsData {
            // Restore UserDefaults from Keychain/File
            if let date = getTrialStartDate() {
                UserDefaults.standard.set(date, forKey: "ChiefMusic_TrialStart")
            }
            return true
        }

        return false
    }

    // MARK: - Admin Reset (for testing only)
    func adminReset() {
        // Delete from all locations
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)

        if let filePath = getHiddenFilePath() {
            try? FileManager.default.removeItem(at: filePath)
        }

        UserDefaults.standard.removeObject(forKey: "ChiefMusic_TrialStart")
        UserDefaults.standard.removeObject(forKey: "ChiefMusic_FirstLaunch")
    }
}
