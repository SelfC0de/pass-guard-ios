import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var store: CredentialStore
    @State private var showDeleteConfirm = false

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
        .alert("Удалить все записи?", isPresented: $showDeleteConfirm) {
            Button("Удалить", role: .destructive) {
                withAnimation { store.items.removeAll() }
                ToastManager.shared.show("Все записи удалены", type: .error)
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }

    private var header: some View {
        HStack {
            Text("Настройки")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.pgTextPrimary)
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
                subtitle: "Требовать при открытии",
                value: $settings.biometricsEnabled
            )
            Divider().background(Color.pgBorder).padding(.vertical, 2)
            SettingsToggle(
                icon: "doc.on.clipboard",
                iconColor: .pgBlue,
                title: "Авто-копирование",
                subtitle: "Копировать пароль при открытии записи",
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
                showDeleteConfirm = true
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Удалить все записи")
                            .font(.system(size: 15))
                            .foregroundColor(.pgRed)
                        Text("\(store.items.count) \(pluralRecords(store.items.count))")
                            .font(.system(size: 12))
                            .foregroundColor(.pgTextTertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func pluralRecords(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "запись" }
        if (2...4).contains(mod10) && !(11...14).contains(mod100) { return "записи" }
        return "записей"
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
