import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var store: CredentialStore
    @StateObject private var pinStore = PinStore.shared

    @State private var showDeleteConfirm = false
    @State private var showPinSetup = false
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var exportFormat: ExportFormat = .json
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var importError: String? = nil
    @State private var showImportError = false
    @State private var importSuccess: String? = nil

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    securitySection
                    pinSection
                    displaySection
                    dataSection
                    versionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 100)
            }
        }
        // PIN Setup sheet
        .sheet(isPresented: $showPinSetup) {
            PinEntryView(mode: .setup, onSuccess: {
                showPinSetup = false
                ToastManager.shared.show("Временной PIN включён", type: .success)
            }, onCancel: { showPinSetup = false })
        }
        // Export sheet
        .sheet(isPresented: $showExportSheet) {
            ExportView(store: store)
        }
        // Import file picker
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json, .commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        // Share sheet
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        // Alerts
        .alert("Удалить все записи?", isPresented: $showDeleteConfirm) {
            Button("Удалить", role: .destructive) {
                withAnimation { store.deleteAll() }
                ToastManager.shared.show("Все записи удалены", type: .error)
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Это действие нельзя отменить.")
        }
        .alert("Ошибка импорта", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }

    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text("Настройки")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.pgTextPrimary)
            Spacer()
        }.padding(.bottom, 4)
    }

    private var securitySection: some View {
        SettingsSection(title: "Безопасность") {
            SettingsToggle(icon: "faceid", iconColor: .pgGreen,
                title: "Face ID / Touch ID", subtitle: "Требовать при открытии",
                value: $settings.biometricsEnabled)
            Divider().background(Color.pgBorder).padding(.vertical, 2)
            SettingsToggle(icon: "doc.on.clipboard", iconColor: .pgBlue,
                title: "Авто-копирование", subtitle: "Копировать пароль при открытии записи",
                value: $settings.autoCopyOnOpen)
        }
    }

    private var pinSection: some View {
        SettingsSection(title: "Временной PIN-код") {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pgBlue.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 14))
                        .foregroundColor(.pgBlue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("PIN = текущее время")
                        .font(.system(size: 15))
                        .foregroundColor(.pgTextPrimary)
                    Text("Например, 14:35 → PIN 1435")
                        .font(.system(size: 12))
                        .foregroundColor(.pgTextSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { pinStore.hasPin },
                    set: { val in
                        pinStore.hasPin = val
                        ToastManager.shared.show(val ? "Временной PIN включён" : "PIN отключён",
                            type: val ? .success : .info)
                    }
                ))
                .tint(.pgBlue)
                .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }

    private var displaySection: some View {
        SettingsSection(title: "Отображение") {
            SettingsToggle(icon: "eye.slash", iconColor: .pgAmber,
                title: "Скрывать пароли", subtitle: "Показывать •••• в списке",
                value: $settings.maskPasswords)
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "Данные") {
            SettingsButton(icon: "square.and.arrow.up", iconColor: .pgGreen,
                title: "Экспорт", subtitle: "JSON, CSV или TXT") {
                showExportSheet = true
            }
            Divider().background(Color.pgBorder).padding(.vertical, 2)
            SettingsButton(icon: "square.and.arrow.down", iconColor: .pgBlue,
                title: "Импорт", subtitle: "JSON, CSV или TXT") {
                showImportPicker = true
            }
            Divider().background(Color.pgBorder).padding(.vertical, 2)
            SettingsButton(icon: "trash", iconColor: .pgRed,
                title: "Удалить все записи",
                subtitle: "\(store.items.count) \(pluralRecords(store.items.count))") {
                showDeleteConfirm = true
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

    // MARK: - Import handler

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let e):
            importError = e.localizedDescription
            showImportError = true
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let ext = url.pathExtension.lowercased()
                let imported: [Credential]
                switch ext {
                case "json": imported = try importJSON(data)
                case "csv":  imported = try importCSV(data)
                default:     imported = try importTXT(data)
                }
                // Merge: skip duplicates by id
                var added = 0
                for item in imported {
                    if !store.items.contains(where: { $0.id == item.id }) {
                        store.save(item)
                        added += 1
                    }
                }
                ToastManager.shared.show("Импортировано: \(added)", type: .success)
            } catch {
                importError = error.localizedDescription
                showImportError = true
            }
        }
    }

    private func pluralRecords(_ n: Int) -> String {
        let m10 = n % 10, m100 = n % 100
        if m10 == 1 && m100 != 11 { return "запись" }
        if (2...4).contains(m10) && !(11...14).contains(m100) { return "записи" }
        return "записей"
    }
}

// MARK: - Export View (sheet)

struct ExportView: View {
    let store: CredentialStore
    @Environment(\.dismiss) private var dismiss
    @State private var format: ExportFormat = .json
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.pgTextTertiary)
                    }
                    Spacer()
                    Text("Экспорт данных")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.pgTextPrimary)
                    Spacer()
                    Color.clear.frame(width: 22)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                VStack(spacing: 16) {
                    // Format picker
                    SettingsSection(title: "Формат") {
                        VStack(spacing: 0) {
                            ForEach(Array(ExportFormat.allCases.enumerated()), id: \.offset) { idx, fmt in
                                Button {
                                    format = fmt
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.pgBlue.opacity(0.15))
                                                .frame(width: 32, height: 32)
                                            Image(systemName: fmt.icon)
                                                .font(.system(size: 14))
                                                .foregroundColor(.pgBlue)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(fmt.rawValue)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.pgTextPrimary)
                                            Text(formatDescription(fmt))
                                                .font(.system(size: 12))
                                                .foregroundColor(.pgTextSecondary)
                                        }
                                        Spacer()
                                        if format == fmt {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.pgBlue)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                if idx < ExportFormat.allCases.count - 1 {
                                    Divider().background(Color.pgBorder)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Stats
                    HStack(spacing: 12) {
                        statCard(value: "\(store.items.count)", label: "Записей")
                        statCard(value: "\(store.items.filter { !$0.password.isEmpty }.count)", label: "С паролем")
                        statCard(value: "\(store.items.filter { !$0.token.isEmpty }.count)", label: "С токеном")
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Button {
                        doExport()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Экспортировать \(store.items.count) записей")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: [.pgGreen, Color(hex: "#15803d")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                    }
                    .disabled(store.items.isEmpty)
                    .opacity(store.items.isEmpty ? 0.4 : 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    private func formatDescription(_ fmt: ExportFormat) -> String {
        switch fmt {
        case .json: return "Полный экспорт, пригоден для импорта"
        case .csv:  return "Таблица, открывается в Excel"
        case .txt:  return "Текстовый файл, удобно читать"
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.pgTextPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.pgTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.pgCard)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pgBorder, lineWidth: 1)))
    }

    private func doExport() {
        let data: Data?
        switch format {
        case .json: data = exportJSON(store.items)
        case .csv:  data = exportCSV(store.items)
        case .txt:  data = exportTXT(store.items)
        }
        guard let data = data else { return }
        let filename = "passguard_export_\(Int(Date().timeIntervalSince1970)).\(format.ext)"
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tmp)
        shareItems = [tmp]
        showShare = true
    }
}

// MARK: - Reusable components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.pgTextTertiary)
                .padding(.leading, 4).padding(.bottom, 8)
            VStack(spacing: 0) { content }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.pgCard)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pgBorder, lineWidth: 1)))
        }
    }
}

struct SettingsToggle: View {
    let icon: String; let iconColor: Color
    let title: String; let subtitle: String
    @Binding var value: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15)).foregroundColor(.pgTextPrimary)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.pgTextSecondary)
            }
            Spacer()
            Toggle("", isOn: $value).tint(.pgBlue).labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct SettingsButton: View {
    let icon: String; let iconColor: Color
    let title: String; let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15)).foregroundColor(.pgTextPrimary)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(.system(size: 12)).foregroundColor(.pgTextSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.pgTextTertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
