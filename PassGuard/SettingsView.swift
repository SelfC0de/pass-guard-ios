import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var store: CredentialStore

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    securitySection
                    displaySection
                    dangerSection
                    versionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 100)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Настройки")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.pgTextPrimary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var securitySection: some View {
        SettingsSection(title: "Безопасность") {
            SettingsToggle(
                icon: "faceid",
                iconColor: .pgGreen,
                title: "Face ID / Touch ID",
                subtitle: "Разблокировка биометрией",
                value: $settings.biometricsEnabled
            )
            Divider().background(Color.pgBorder)
            SettingsToggle(
                icon: "doc.on.clipboard",
                iconColor: .pgBlue,
                title: "Авто-копировать",
                subtitle: "Копировать пароль при открытии",
                value: $settings.autoCopyOnOpen
            )
        }
    }

    private var displaySection: some View {
        SettingsSection(title: "Отображение") {
            SettingsToggle(
                icon: "eye.slash",
                iconColor: .pgAmber,
                title: "Скрывать пароли",
                subtitle: "Показывать •••• в списке",
                value: $settings.maskPasswords
            )
        }
    }

    private var dangerSection: some View {
        SettingsSection(title: "Данные") {
            Button {
                withAnimation { store.items.removeAll() }
                ToastManager.shared.show("Все записи удалены", icon: "trash.fill", type: .error)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.pgRed.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.pgRed)
                    }
                    Text("Удалить все записи")
                        .font(.system(size: 15))
                        .foregroundColor(.pgRed)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var versionSection: some View {
        VStack(spacing: 4) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 28))
                .foregroundColor(.pgBlue.opacity(0.5))
            Text("PassGuard")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pgTextSecondary)
            Text("v\(settings.appVersion)")
                .font(.system(size: 12))
                .foregroundColor(.pgTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.pgTextTertiary)
                .padding(.leading, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pgCard)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pgBorder, lineWidth: 1))
            )
        }
    }
}

struct SettingsToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var value: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.pgTextPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.pgTextSecondary)
            }
            Spacer()
            Toggle("", isOn: $value)
                .tint(.pgBlue)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
