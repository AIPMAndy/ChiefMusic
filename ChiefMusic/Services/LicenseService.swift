import Foundation
import CryptoKit
import SwiftUI
import IOKit

// MARK: - License Service (MDSKILL 兼容版本)
class LicenseService: ObservableObject {
    static let shared = LicenseService()

    @Published var isActivated: Bool = false
    @Published var licenseInfo: LicenseInfo?
    @Published var trialDaysRemaining: Int = 7
    @Published var isTrialExpired: Bool = false
    @Published var deviceCode: String = ""
    @Published var isOfflineMode: Bool = false
    @Published var offlineDaysRemaining: Int = 0
    @Published var activationError: String?  // 新增：具体的错误信息

    private let userDefaults = UserDefaults.standard
    private let licenseKey = "ChiefMusic_License"
    private let firstLaunchKey = "ChiefMusic_FirstLaunch"
    private let lastVerifiedKey = "ChiefMusic_LastVerified"

    // 配置（与 MDSKILL 共用同一服务器）
    private let apiBaseURL = "http://YOUR_LICENSE_SERVER_HOST:3000"
    private let apiSecret = "YOUR_LICENSE_API_SECRET"
    private let offlineGraceDays = 5
    private let verificationCacheSeconds = 3600  // 验证缓存时间：1小时内不重复验证

    // 后台验证定时器
    private var verificationTimer: Timer?

    init() {
        // Security checks on init
        if SecurityConfig.isDebuggerAttached() {
            print("Security: Debugger detected")
        }

        if !SecurityConfig.verifyIntegrity() {
            print("Security: Integrity check failed")
        }

        self.deviceCode = generateDeviceFingerprint()
        checkLicenseStatus()
        checkTrialStatus()

        // 启动后台验证（每小时）
        startBackgroundVerification()
    }

    // MARK: - Device Fingerprint Generation
    private func generateDeviceFingerprint() -> String {
        // Get hardware UUID
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(platformExpert) }

        guard platformExpert != 0 else {
            return generateFallbackFingerprint()
        }

        guard let serialNumberAsCFString = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformSerialNumberKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeUnretainedValue() as? String else {
            return generateFallbackFingerprint()
        }

        // Generate fingerprint from serial number
        let combined = "\(serialNumberAsCFString)-ChiefMusic"
        let hash = SHA256.hash(data: Data(combined.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

        // 返回 16 位大写十六进制（与 MDSKILL 格式一致）
        return String(hashString.prefix(16)).uppercased()
    }

    private func generateFallbackFingerprint() -> String {
        // Fallback: use hostname + username
        let hostname = ProcessInfo.processInfo.hostName
        let username = NSUserName()
        let combined = "\(hostname)-\(username)-ChiefMusic"
        let hash = SHA256.hash(data: Data(combined.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

        return String(hashString.prefix(16)).uppercased()
    }

    // MARK: - Online Activation
    func validateLicense(_ code: String) -> Bool {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        NSLog("🔵 [ChiefMusic] 开始激活流程: \(trimmedCode)")
        NSLog("🔵 [ChiefMusic] 设备码: \(deviceCode)")
        NSLog("🔵 [ChiefMusic] API地址: \(apiBaseURL)")

        // 启动异步验证
        Task {
            await activateLicenseOnline(trimmedCode)
        }

        // 返回 true 让 UI 显示加载状态（实际结果通过 @Published 更新）
        return true
    }

    @MainActor
    private func activateLicenseOnline(_ licenseKey: String) async {
        NSLog("🔵 [ChiefMusic] 进入 activateLicenseOnline")
        activationError = nil  // 清空之前的错误

        // 海外用户优化：自动重试机制（最多3次）
        var lastError: Error?
        for attempt in 1...3 {
            do {
                NSLog("🔵 [ChiefMusic] 第 \(attempt) 次尝试激活...")
                let result = try await apiRequest(
                    endpoint: "/api/activate",
                    method: "POST",
                    body: [
                        "licenseKey": licenseKey,
                        "deviceId": deviceCode,
                        "deviceInfo": [
                            "platform": "macOS",
                            "model": "ChiefMusic"
                        ]
                    ]
                )

                NSLog("🔵 [ChiefMusic] 收到服务器响应: \(result)")

                guard let success = result["success"] as? Bool, success else {
                    let errorMsg = result["error"] as? String ?? "激活失败"
                    NSLog("❌ [ChiefMusic] 激活失败: \(errorMsg)")

                    let lang = LanguageManager.shared
                    // 根据服务器返回的错误设置友好提示
                    switch errorMsg {
                    case "授权码不存在":
                        activationError = lang.t(.errorLicenseNotExist)
                    case "授权码已被禁用":
                        activationError = lang.t(.errorLicenseDisabled)
                    case "设备数已达上限":
                        activationError = lang.t(.errorDeviceLimit)
                    case "授权码已过期":
                        activationError = lang.t(.errorLicenseExpired)
                    default:
                        activationError = String(format: lang.t(.activationFailedWithError), errorMsg)
                    }
                    return
                }

                // 从 data 对象中提取授权信息
                guard let data = result["data"] as? [String: Any],
                      let licenseData = data["license"] as? [String: Any] else {
                    NSLog("❌ [ChiefMusic] 返回数据格式错误")
                    activationError = "服务器返回数据格式错误，请联系技术支持"
                    return
                }

                let expiresAt = licenseData["expiresAt"] as? String
                let license = LicenseInfo(
                    code: licenseKey,
                    activatedDate: Date(),
                    type: .yearly,
                    deviceCode: deviceCode,
                    expiresAt: expiresAt
                )

                saveLicense(license)

                // 更新最后验证时间
                userDefaults.set(Date().timeIntervalSince1970, forKey: lastVerifiedKey)

                NSLog("✅ [ChiefMusic] License activated online: \(licenseKey)")
                activationError = nil
                return  // 成功后立即返回

            } catch let error as NSError {
                lastError = error
                NSLog("❌ [ChiefMusic] 第 \(attempt) 次尝试失败: \(error.localizedDescription)")

                let lang = LanguageManager.shared
                // 根据错误类型设置友好提示
                if error.domain == NSURLErrorDomain {
                    switch error.code {
                    case NSURLErrorTimedOut:
                        activationError = lang.t(.errorNetworkTimeout) + " (\(attempt)/3)..."
                    case NSURLErrorNotConnectedToInternet:
                        activationError = lang.t(.errorNoInternet)
                        break  // 网络断开，不再重试
                    case NSURLErrorCannotConnectToHost:
                        activationError = lang.t(.errorCannotConnect)
                    default:
                        activationError = String(format: lang.t(.networkErrorRetrying), error.code)
                    }
                }

                // 如果不是最后一次尝试，等待后重试
                if attempt < 3 && error.code != NSURLErrorNotConnectedToInternet {
                    NSLog("🔵 [ChiefMusic] 等待 2 秒后重试...")
                    try? await Task.sleep(nanoseconds: 2_000_000_000)  // 等待2秒
                } else {
                    break
                }
            }
        }

        // 所有重试都失败
        if let error = lastError as? NSError {
            NSLog("❌ [ChiefMusic] 所有重试均失败，最后错误: \(error.localizedDescription)")

            if activationError == nil {
                let lang = LanguageManager.shared
                activationError = lang.t(.errorActivationFailed)
            }
        }
    }

    // MARK: - Online Verification
    func verifyLicenseOnline() async -> (valid: Bool, offline: Bool, daysRemaining: Int) {
        guard let license = licenseInfo else {
            return (false, false, 0)
        }

        let lastVerified = userDefaults.double(forKey: lastVerifiedKey)
        let secondsSinceVerified = Date().timeIntervalSince1970 - lastVerified

        // 优化：1小时内刚验证过，直接返回成功（避免启动卡顿）
        if secondsSinceVerified < Double(verificationCacheSeconds) {
            NSLog("✅ [ChiefMusic] 验证缓存命中（\(Int(secondsSinceVerified))秒前验证过），跳过网络请求")
            return (true, false, 0)
        }

        // 检查离线容错
        let daysSinceVerified = secondsSinceVerified / (60 * 60 * 24)

        // 如果在离线容错期内，允许离线使用
        if daysSinceVerified < Double(offlineGraceDays) {
            let remaining = offlineGraceDays - Int(daysSinceVerified)

            // 尝试在线验证（非阻塞）
            Task.detached {
                await self.tryOnlineVerification(license.code)
            }

            return (true, true, remaining)
        }

        // 超过离线容错期，必须在线验证
        return await tryOnlineVerification(license.code)
    }

    @MainActor
    private func tryOnlineVerification(_ licenseKey: String) async -> (valid: Bool, offline: Bool, daysRemaining: Int) {
        // 海外用户优化：后台验证也加重试机制（2次，比激活少）
        for attempt in 1...2 {
            do {
                NSLog("🔵 [ChiefMusic] 后台验证第 \(attempt) 次尝试...")
                let result = try await apiRequest(
                    endpoint: "/api/verify",
                    method: "POST",
                    body: [
                        "licenseKey": licenseKey,
                        "deviceFingerprint": deviceCode
                    ]
                )

                guard let valid = result["valid"] as? Bool, valid else {
                    let errorMsg = result["error"] as? String ?? "验证失败"
                    NSLog("❌ [ChiefMusic] 在线验证失败: \(errorMsg)")

                    // 如果是设备未授权或授权码被禁用，清除本地授权
                    if errorMsg.contains("设备未授权") || errorMsg.contains("已被禁用") {
                        await MainActor.run {
                            removeLicense()
                        }
                    }

                    return (false, false, 0)
                }

                // 更新最后验证时间
                userDefaults.set(Date().timeIntervalSince1970, forKey: lastVerifiedKey)

                await MainActor.run {
                    isOfflineMode = false
                    offlineDaysRemaining = 0
                }

                NSLog("✅ [ChiefMusic] 后台验证成功")
                return (true, false, 0)

            } catch {
                NSLog("❌ [ChiefMusic] 后台验证第 \(attempt) 次失败: \(error.localizedDescription)")

                // 最后一次尝试失败，进入离线模式
                if attempt == 2 {
                    NSLog("⚠️ [ChiefMusic] 后台验证失败，进入离线模式")
                    return (false, false, 0)
                }

                // 等待1秒后重试（后台验证不需要等太久）
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        return (false, false, 0)
    }

    // MARK: - API Request Helper
    private func apiRequest(endpoint: String, method: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else {
            print("❌ 无效的URL: \(apiBaseURL)\(endpoint)")
            throw NSError(domain: "Invalid URL", code: -1)
        }

        print("🔵 API请求: \(method) \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ChiefMusic", forHTTPHeaderField: "x-app-name")
        request.setValue(apiSecret, forHTTPHeaderField: "x-api-key")  // 使用 x-api-key 而不是签名

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let bodyString = String(data: bodyData, encoding: .utf8) ?? ""

        print("🔵 请求体: \(bodyString)")

        request.httpBody = bodyData
        request.timeoutInterval = 30  // 海外用户需要更长超时时间（5秒 → 30秒）

        print("🔵 发送请求...")
        let (data, response) = try await URLSession.shared.data(for: request)

        print("🔵 收到响应")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效的响应类型")
            throw NSError(domain: "Invalid Response", code: -1)
        }

        print("🔵 HTTP状态码: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ HTTP错误: \(httpResponse.statusCode), 响应: \(responseBody)")
            throw NSError(domain: "HTTP Error", code: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Parse Error", code: -1)
        }

        return json
    }

    // MARK: - Background Verification
    private func startBackgroundVerification() {
        // 每小时验证一次
        verificationTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task {
                let result = await self.verifyLicenseOnline()

                await MainActor.run {
                    if result.offline {
                        print("🔄 后台验证: 离线模式（剩余 \(result.daysRemaining) 天）")
                    } else if result.valid {
                        print("✅ 后台验证: 在线验证成功")
                    } else {
                        print("❌ 后台验证: 验证失败")
                    }
                }
            }
        }
    }

    // MARK: - License Storage
    private func saveLicense(_ license: LicenseInfo) {
        if let encoded = try? JSONEncoder().encode(license) {
            userDefaults.set(encoded, forKey: licenseKey)
            self.licenseInfo = license
            self.isActivated = true
        }
    }

    private func checkLicenseStatus() {
        if let data = userDefaults.data(forKey: licenseKey),
           let license = try? JSONDecoder().decode(LicenseInfo.self, from: data) {
            // Verify device code matches
            if license.deviceCode == deviceCode {
                self.licenseInfo = license
                self.isActivated = true

                // 启动时进行一次在线验证
                Task {
                    let result = await verifyLicenseOnline()
                    await MainActor.run {
                        if result.offline {
                            self.isOfflineMode = true
                            self.offlineDaysRemaining = result.daysRemaining
                        }
                    }
                }
            } else {
                // Device changed, invalidate license
                removeLicense()
            }
        }
    }

    func removeLicense() {
        userDefaults.removeObject(forKey: licenseKey)
        userDefaults.removeObject(forKey: lastVerifiedKey)
        self.licenseInfo = nil
        self.isActivated = false
        self.isOfflineMode = false
        self.offlineDaysRemaining = 0
    }

    // MARK: - Trial Management
    private func checkTrialStatus() {
        // Detect reset attempts
        if TrialProtection.shared.detectResetAttempt() {
            print("⚠️ Trial reset attempt detected and blocked")
        }

        // Check if first launch
        if userDefaults.object(forKey: firstLaunchKey) == nil {
            // First launch - start trial with multi-layer protection
            let startDate = TrialProtection.shared.recordTrialStart()
            userDefaults.set(true, forKey: firstLaunchKey)
            trialDaysRemaining = 7
            isTrialExpired = false
            print("✅ Trial started: \(startDate)")
        } else {
            // Get trial status from protected storage
            let (valid, remaining) = TrialProtection.shared.isTrialValid()
            trialDaysRemaining = remaining
            isTrialExpired = !valid

            if !valid {
                print("⏰ Trial expired")
            }
        }
    }

    func canUseApp() -> Bool {
        return isActivated || !isTrialExpired
    }

    func resetTrial() {
        // For testing only - requires admin privileges
        #if DEBUG
        TrialProtection.shared.adminReset()
        userDefaults.removeObject(forKey: firstLaunchKey)
        userDefaults.removeObject(forKey: lastVerifiedKey)
        checkTrialStatus()
        print("🔧 Trial reset (DEBUG mode only)")
        #else
        print("❌ Trial reset disabled in release builds")
        #endif
    }

    deinit {
        verificationTimer?.invalidate()
    }
}

// MARK: - License Info Model
struct LicenseInfo: Codable {
    let code: String
    let activatedDate: Date
    let type: LicenseType
    let deviceCode: String
    let expiresAt: String?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: activatedDate)
    }

    var formattedExpiresAt: String? {
        guard let expiresAt = expiresAt,
              let date = ISO8601DateFormatter().date(from: expiresAt) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

enum LicenseType: String, Codable {
    case trial = "Trial"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var displayName: String {
        let lang = LanguageManager.shared
        switch self {
        case .trial: return lang.t(.licenseTypeTrial)
        case .monthly: return lang.t(.licenseTypeMonthly)
        case .yearly: return lang.t(.licenseTypeYearly)
        }
    }
}

// MARK: - License Generator (for distribution - 服务端使用)
struct LicenseGenerator {
    private static let validationSalt = "YOUR_VALIDATION_SALT"

    static func generate(type: LicenseType) -> String {
        let prefix = "CHIEF"

        // Segment 1: Type + Random
        let typePrefix: String
        switch type {
        case .monthly: typePrefix = "M"
        case .yearly: typePrefix = "Y"
        case .trial: typePrefix = "X"
        }
        let segment1 = typePrefix + randomAlphanumeric(length: 4)

        // Segment 2: License ID (random)
        let segment2 = randomAlphanumeric(length: 5)

        // Segment 3: Random
        let segment3 = randomAlphanumeric(length: 5)

        // Segment 4: Checksum
        let checksum = generateChecksum(prefix: prefix, seg1: segment1, seg2: segment2, seg3: segment3)

        return "\(prefix)-\(segment1)-\(segment2)-\(segment3)-\(checksum)"
    }

    private static func generateChecksum(prefix: String, seg1: String, seg2: String, seg3: String) -> String {
        let combined = "\(prefix)-\(seg1)-\(seg2)-\(seg3)-\(validationSalt)"
        let hash = SHA256.hash(data: Data(combined.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        let checksum = String(hashString.prefix(5)).uppercased()
        return checksum.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
    }

    private static func randomAlphanumeric(length: Int) -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Exclude confusing chars: I, O, 0, 1
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
