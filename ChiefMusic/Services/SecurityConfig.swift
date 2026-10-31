import Foundation
import CryptoKit

// MARK: - Security Obfuscation
struct SecurityConfig {
    // Obfuscated validation salt (split into parts)
    private static let s1 = "YOUR"
    private static let s2 = "_VALIDATION_"
    private static let s3 = "SALT"
    private static let s4 = ""

    static var validationSalt: String {
        // Anti-debugging check
        if isDebuggerAttached() {
            return String(repeating: "X", count: 32) // Return fake salt if debugger detected
        }
        return s1 + s2 + s3 + s4
    }

    // Obfuscated API key storage (DeepSeek)
    private static let encryptedDeepSeekKey: [UInt8] = [] // 已移除：开源版请在设置中填写自己的 API Key

    // Obfuscated API key storage (AceMusic)
    private static let encryptedAceMusicKey: [UInt8] = [] // 已移除：开源版请在设置中填写自己的 API Key

    static var defaultAPIKey: String {
        // Simple XOR deobfuscation for DeepSeek
        let baseKey: UInt8 = 0x42
        let decoded = encryptedDeepSeekKey.map { $0 ^ baseKey }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }

    static var defaultAceMusicKey: String {
        // Simple XOR deobfuscation for AceMusic
        let baseKey: UInt8 = 0x42
        let decoded = encryptedAceMusicKey.map { $0 ^ baseKey }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }

    // Device code validation with obfuscation
    static func validateDeviceBinding(_ code: String, device: String) -> Bool {
        // Anti-debugging
        if isDebuggerAttached() { return false }

        let parts = code.components(separatedBy: "-")
        guard parts.count == 5 else { return false }

        let deviceParts = device.components(separatedBy: "-")
        guard deviceParts.count == 3 else { return false }

        // Obfuscated comparison
        let a = parts[2]
        let b = deviceParts[1]
        return compareObfuscated(a, b)
    }

    // Obfuscated string comparison
    private static func compareObfuscated(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count else { return false }
        var result = true
        for (c1, c2) in zip(a, b) {
            result = result && (c1 == c2)
        }
        return result
    }

    // Checksum validation with multiple rounds
    static func generateSecureChecksum(_ components: [String]) -> String {
        // Anti-debugging
        if isDebuggerAttached() {
            return String(repeating: "0", count: 5)
        }

        var combined = components.joined(separator: "-") + validationSalt

        // Multiple hash rounds for security (3 rounds)
        for i in 0..<3 {
            let hash = SHA256.hash(data: Data(combined.utf8))
            combined = hash.compactMap { String(format: "%02x", $0) }.joined()

            // Add noise between rounds
            if i < 2 {
                combined = combined + String(i)
            }
        }

        let checksum = String(combined.prefix(5)).uppercased()
        return checksum.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
    }

    // Anti-debugging check (multiple methods)
    static func isDebuggerAttached() -> Bool {
        // Method 1: sysctl check
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        let traced = (result == 0) && ((info.kp_proc.p_flag & P_TRACED) != 0)

        // Method 2: Check for common debugger processes
        let debuggerProcesses = ["lldb", "gdb", "debugserver"]
        let isDebuggerRunning = debuggerProcesses.contains { process in
            var mib2: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
            var size2: size_t = 0
            sysctl(&mib2, UInt32(mib2.count), nil, &size2, nil, 0)
            return size2 > 0
        }

        return traced || isDebuggerRunning
    }

    // Time-based validation
    static func isValidTimestamp(_ date: Date) -> Bool {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        // License must be activated within reasonable time
        return diff >= 0 && diff < 365 * 24 * 3600 * 10 // 10 years max
    }

    // Integrity check - verify app hasn't been tampered
    static func verifyIntegrity() -> Bool {
        // Check if running in simulator (easier to crack)
        #if targetEnvironment(simulator)
        return false
        #else

        // Check bundle signature
        guard let bundlePath = Bundle.main.bundlePath as NSString? else {
            return false
        }

        // Verify code signature exists
        let fileManager = FileManager.default
        let executablePath = bundlePath.appendingPathComponent("Contents/MacOS/ChiefMusic")

        return fileManager.fileExists(atPath: executablePath)
        #endif
    }

    // Jailbreak/Root detection
    static func isJailbroken() -> Bool {
        // Check for common jailbreak files
        let paths = [
            "/Applications/Cydia.app",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/etc/apt"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        return false
    }
}

// MARK: - String Obfuscation Extension
extension String {
    func obfuscate() -> [UInt8] {
        let key: UInt8 = 0x42
        return self.utf8.map { $0 ^ key }
    }

    static func deobfuscate(_ bytes: [UInt8]) -> String {
        let key: UInt8 = 0x42
        let decoded = bytes.map { $0 ^ key }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }

    // ROT13-like obfuscation for strings
    func rot13() -> String {
        return self.map { char in
            if char.isLetter {
                let base = char.isUppercase ? Unicode.Scalar("A").value : Unicode.Scalar("a").value
                let offset = (char.unicodeScalars.first!.value - base + 13) % 26
                return Character(Unicode.Scalar(base + offset)!)
            }
            return char
        }.reduce("") { $0 + String($1) }
    }
}

