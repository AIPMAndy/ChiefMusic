import SwiftUI
import CoreImage.CIFilterBuiltins

struct LicenseView: View {
    @EnvironmentObject var licenseService: LicenseService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) var dismiss

    @State private var licenseCode: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isValidating: Bool = false
    @State private var showCopiedToast: Bool = false
    @State private var showQRCode: Bool = false
    @State private var showSuccessMessage: Bool = false

    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        ZStack {
            colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Success Message Overlay
                if showSuccessMessage {
                    ZStack {
                        colors.bg.opacity(0.95).ignoresSafeArea()

                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.green)

                            Text(lang.t(.activationSuccess))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(colors.textPrimary)

                            if let expiresAt = licenseService.licenseInfo?.formattedExpiresAt {
                                Text("\(lang.t(.activationSuccessExpiry)) \(expiresAt)")
                                    .font(.system(size: 15))
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        .padding()
                    }
                    .transition(.opacity)
                    .zIndex(999)
                }

                // Close button - always visible at top
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }

                // Scrollable content
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(colors.accent)

                    Text(lang.t(.activateTitle))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(colors.textPrimary)

                    if licenseService.isActivated {
                        if licenseService.isOfflineMode {
                            Text("\(lang.t(.activatedOffline))\(licenseService.offlineDaysRemaining)\(lang.t(.offlineDays))")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        } else {
                            Text(lang.t(.activated))
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                    } else if !licenseService.isTrialExpired {
                        Text("\(lang.t(.trialRemaining)) \(licenseService.trialDaysRemaining) \(lang.t(.days))")
                            .font(.system(size: 14))
                            .foregroundColor(colors.textSecondary)
                    } else {
                        Text(lang.t(.trialExpired))
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 40)

                // License Info (if activated)
                if let info = licenseService.licenseInfo {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(lang.t(.licenseType))
                                .foregroundColor(colors.textSecondary)
                            Spacer()
                            Text(info.type.displayName)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text(lang.t(.activationDate))
                                .foregroundColor(colors.textSecondary)
                            Spacer()
                            Text(info.formattedDate)
                                .foregroundColor(colors.textPrimary)
                        }

                        HStack {
                            Text(lang.t(.licenseKeyLabel))
                                .foregroundColor(colors.textSecondary)
                            Spacer()
                            Text(info.code)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(colors.textPrimary)
                        }

                        HStack {
                            Text(lang.t(.deviceCode) + ":")
                                .foregroundColor(colors.textSecondary)
                            Spacer()
                            Text(licenseService.deviceCode)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(colors.textPrimary)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.bgCard)
                    )
                    .padding(.horizontal, 40)
                }

                // Device Code Display (if not activated)
                if !licenseService.isActivated {
                    VStack(spacing: 12) {
                        Text(lang.t(.deviceCode))
                            .font(.system(size: 14))
                            .foregroundColor(colors.textSecondary)

                        HStack {
                            Text(licenseService.deviceCode)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(colors.textPrimary)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colors.bgCard)
                                )

                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(licenseService.deviceCode, forType: .string)
                                showCopiedToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopiedToast = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: showCopiedToast ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 14))
                                        .foregroundColor(showCopiedToast ? .green : colors.accent)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colors.bgCard)
                                )
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                showQRCode.toggle()
                            }) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 14))
                                    .foregroundColor(colors.accent)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(colors.bgCard)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        if showCopiedToast {
                            Text(lang.t(.deviceCodeCopied))
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }

                        // QR Code
                        if showQRCode {
                            VStack(spacing: 8) {
                                let qrText = "\(lang.t(.deviceCode)): \(licenseService.deviceCode)\n\(lang.t(.qrCodeContact))"
                                if let qrImage = generateQRCode(from: qrText) {
                                    Image(nsImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .frame(width: 150, height: 150)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                }

                                Text(lang.t(.scanQRCode))
                                    .font(.system(size: 10))
                                    .foregroundColor(colors.textSecondary.opacity(0.7))
                            }
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .scale))
                        }

                        Text(lang.t(.deviceCodeHint))
                            .font(.system(size: 11))
                            .foregroundColor(colors.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .animation(.easeInOut(duration: 0.2), value: showCopiedToast)
                    .animation(.easeInOut(duration: 0.3), value: showQRCode)
                }

                // Input Section (if not activated)
                if !licenseService.isActivated {
                    VStack(spacing: 16) {
                        Text(lang.t(.enterLicenseKey))
                            .font(.system(size: 14))
                            .foregroundColor(colors.textSecondary)

                        TextField(lang.t(.licenseKeyPlaceholder), text: $licenseCode)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colors.bgCard)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(showError ? Color.red : colors.accent.opacity(0.3), lineWidth: 1)
                            )
                            .autocorrectionDisabled()
                            .onChange(of: licenseCode) { oldValue, newValue in
                                // 自动转大写
                                var formatted = newValue.uppercased()

                                // 移除所有短横线
                                let cleaned = formatted.replacingOccurrences(of: "-", with: "")

                                // 如果达到完整长度（25个字符：CHIEF + 20个字符），自动格式化
                                if cleaned.count == 25 {
                                    formatted = formatLicenseKey(cleaned)
                                } else if cleaned.count > 25 {
                                    // 超过长度，截断
                                    let truncated = String(cleaned.prefix(25))
                                    formatted = formatLicenseKey(truncated)
                                } else {
                                    // 未达到长度，保持用户输入（转大写后）
                                    formatted = cleaned
                                }

                                // 只有当格式化后的值与当前值不同时才更新（避免无限循环）
                                if formatted != licenseCode {
                                    licenseCode = formatted
                                }
                            }

                        if showError {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }

                        Button(action: validateLicense) {
                            HStack {
                                if isValidating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                        .padding(.trailing, 4)
                                    Text(lang.t(.activating))
                                        .fontWeight(.semibold)
                                } else {
                                    Text(lang.t(.activateButton))
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colors.accent)
                            )
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(licenseCode.isEmpty || isValidating)
                        .opacity(licenseCode.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()

                // Purchase Section
                if !licenseService.isActivated {
                    VStack(spacing: 16) {
                        // Feature List
                        VStack(spacing: 16) {
                            Text(lang.t(.whyActivate))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: 10) {
                                featureRow(icon: "sparkles", text: lang.t(.featureUnlimited), colors: colors)
                                featureRow(icon: "text.bubble", text: lang.t(.featureLyrics), colors: colors)
                                featureRow(icon: "paintpalette", text: lang.t(.featureStyles), colors: colors)
                                featureRow(icon: "square.and.arrow.down", text: lang.t(.featureImport), colors: colors)
                                featureRow(icon: "text.alignleft", text: lang.t(.featureSyncLyrics), colors: colors)
                                featureRow(icon: "arrow.triangle.2.circlepath", text: lang.t(.featureMultiDevice), colors: colors)
                                featureRow(icon: "headphones", text: lang.t(.featurePrioritySupport), colors: colors)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(colors.bgCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(colors.accent.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 40)

                        // Pricing Cards
                        HStack(spacing: 16) {
                            // Monthly Plan
                            VStack(spacing: 12) {
                                Text(lang.t(.monthlyPlan))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(colors.textSecondary)

                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(lang.t(.priceMonthlyCurrency))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(colors.accent)
                                    Text(lang.t(.priceMonthly))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(colors.accent)
                                    Text(lang.t(.perMonth))
                                        .font(.system(size: 13))
                                        .foregroundColor(colors.textSecondary)
                                }

                                Text("2 \(lang.t(.devices))")
                                    .font(.system(size: 11))
                                    .foregroundColor(colors.textSecondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.bgCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(colors.accent.opacity(0.3), lineWidth: 1)
                                    )
                            )

                            // Yearly Plan (Recommended)
                            VStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text(lang.t(.yearlyPlan))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)

                                    Text(lang.t(.recommended))
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                }

                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(lang.t(.priceYearlyCurrency))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(lang.t(.priceYearly))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(lang.t(.perYear))
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.9))
                                }

                                let savingsText = lang.t(.devicesSave)
                                Text(savingsText)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [colors.accent, colors.accent.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .padding(.horizontal, 40)

                        // Contact Button with Multiple Channels
                        Button(action: {
                            showContactDialog()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 18))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lang.t(.contactPurchase))
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(lang.t(.purchaseContactInfo))
                                        .font(.system(size: 12))
                                        .opacity(0.9)
                                }
                            }
                        }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 40)
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    // Trial users: prominent "Continue Trial" button
                    if !licenseService.isTrialExpired && !licenseService.isActivated {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16))
                                let buttonText = "\(lang.t(.continueTrialButton)) (\(licenseService.trialDaysRemaining) \(lang.t(.days)))"
                                Text(buttonText)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 40)
                    }

                    if licenseService.isActivated {
                        Button(action: {
                            licenseService.removeLicense()
                        }) {
                            Text(lang.t(.removeLicense))
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: { dismiss() }) {
                        let closeText = licenseService.canUseApp() ?
                            lang.t(.menuClose) :
                            lang.t(.menuExit)
                        Text(closeText)
                            .font(.system(size: 13))
                            .foregroundColor(colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 30)
            }
        }
        .frame(width: 500, height: 720)
        }
    }

    private func validateLicense() {
        isValidating = true
        showError = false

        if licenseService.validateLicense(licenseCode) {
            // 验证已启动，等待异步结果
            // 海外用户优化：延长等待时间到 35 秒（30秒超时 + 5秒缓冲）
            // 通过监听 licenseService.isActivated 的变化来更新 UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 35.0) {
                if !self.licenseService.isActivated {
                    self.showError = true
                    // 使用更具体的错误信息
                    self.errorMessage = self.licenseService.activationError ?? lang.t(.activationFailedDefault)
                    self.isValidating = false
                } else {
                    // 激活成功，显示成功消息
                    self.isValidating = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showSuccessMessage = true
                    }

                    // 2秒后自动关闭授权界面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.dismiss()
                    }
                }
            }
        } else {
            showError = true
            errorMessage = lang.t(.errorInvalidFormat)
            isValidating = false
        }
    }

    // MARK: - Contact Dialog
    private func showContactDialog() {
        let alert = NSAlert()
        alert.messageText = lang.t(.contactPurchase)

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lang.t(.contactCopied), forType: .string)
        alert.informativeText = lang.t(.purchaseDetailsInfo)

        alert.alertStyle = .informational
        alert.addButton(withTitle: lang.t(.menuOK))
        alert.runModal()
    }

    // MARK: - License Key Formatter
    private func formatLicenseKey(_ raw: String) -> String {
        // CHIEFXXXXXXXXXXXXXXXXX → CHIEF-XXXXX-XXXXX-XXXXX-XXXXX
        guard raw.count == 25 else { return raw }

        let parts = [
            String(raw.prefix(5)),              // CHIEF
            String(raw.dropFirst(5).prefix(5)), // 5 chars
            String(raw.dropFirst(10).prefix(5)), // 5 chars
            String(raw.dropFirst(15).prefix(5)), // 5 chars
            String(raw.dropFirst(20))            // 5 chars
        ]
        return parts.joined(separator: "-")
    }

    // MARK: - QR Code Generator
    private func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up the QR code
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return NSImage(cgImage: cgImage, size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height))
    }

    // MARK: - Feature Row Helper
    private func featureRow(icon: String, text: String, colors: ThemeColors) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(colors.accent)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(colors.textPrimary)

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(colors.textSecondary.opacity(0.5))
        }
    }
}

// MARK: - Trial Expired View
struct TrialExpiredView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var lang: LanguageManager
    @State private var showLicenseView = false

    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        ZStack {
            colors.bg.ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                VStack(spacing: 12) {
                    Text(lang.t(.trialExpiredTitle))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(colors.textPrimary)

                    Text(lang.t(.trialExpiredMessage))
                        .font(.system(size: 14))
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: { showLicenseView = true }) {
                    Text(lang.t(.enterLicenseButton))
                        .fontWeight(.semibold)
                        .frame(width: 200)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colors.accent)
                        )
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text(lang.t(.exitApp))
                        .font(.system(size: 13))
                        .foregroundColor(colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showLicenseView) {
            LicenseView()
        }
    }
}

#Preview {
    LicenseView()
        .environmentObject(LicenseService.shared)
        .environmentObject(ThemeManager.shared)
}
