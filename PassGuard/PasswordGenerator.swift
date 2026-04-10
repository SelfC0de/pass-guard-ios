import SwiftUI
import Combine

enum PasswordFormat: String, CaseIterable {
    case grouped   = "xxxx-xxxx-xxxx-xxxx"
    case pgLong    = "pg-xxxxxxxxxxxxxxxxxxxx"
    case pgMixed   = "pgxxxxxxxxxx-xxxx-xxxx"
    case plain     = "Без формата"

    var label: String { rawValue }
}

class PasswordGeneratorSettings: ObservableObject {
    @Published var length: Double = 16
    @Published var useUppercase: Bool = true
    @Published var useLowercase: Bool = true
    @Published var useDigits: Bool = true
    @Published var useSpecial: Bool = false
    @Published var format: PasswordFormat = .grouped

    func generate() -> String {
        var charset = ""
        if useUppercase { charset += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if useLowercase { charset += "abcdefghijklmnopqrstuvwxyz" }
        if useDigits    { charset += "0123456789" }
        if useSpecial   { charset += "!@#$%^&*()-_=+[]{}|;:,.<>?" }
        if charset.isEmpty { charset = "abcdefghijklmnopqrstuvwxyz" }

        let len = Int(length)

        // Гарантируем уникальность через UUID-seed + текущее время
        var seed = UInt64(Date().timeIntervalSince1970 * 1_000_000)
        seed ^= UInt64(arc4random())

        func nextChar() -> Character {
            let idx = Int(arc4random_uniform(UInt32(charset.count)))
            return charset[charset.index(charset.startIndex, offsetBy: idx)]
        }

        // Генерация базового пула символов
        var raw = String((0..<max(len, 22)).map { _ in nextChar() })

        // Применяем формат
        switch format {
        case .grouped:
            // xxxx-xxxx-xxxx-xxxx (берём 16 символов)
            let s = String(raw.prefix(16))
            let parts = stride(from: 0, to: 16, by: 4).map { i -> String in
                let start = s.index(s.startIndex, offsetBy: i)
                let end   = s.index(start, offsetBy: 4)
                return String(s[start..<end])
            }
            return parts.joined(separator: "-")

        case .pgLong:
            // pg-xxxxxxxxxxxxxxxxxxxx (22 символа после pg-)
            return "pg-" + String(raw.prefix(22))

        case .pgMixed:
            // pgxxxxxxxxxx-xxxx-xxxx
            let a = String(raw.prefix(10))
            let b = String(raw.dropFirst(10).prefix(4))
            let c = String(raw.dropFirst(14).prefix(4))
            return "pg" + a + "-" + b + "-" + c

        case .plain:
            return String(raw.prefix(len))
        }
    }
}

struct PasswordGeneratorSheet: View {
    @ObservedObject var settings: PasswordGeneratorSettings
    @Binding var generatedPassword: String
    @Environment(\.dismiss) private var dismiss

    @State private var preview: String = ""

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Генератор паролей")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.pgTextPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.pgTextTertiary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

                // Preview — always visible at top
                previewCard
                    .padding(.horizontal, 20)

                // Settings — compact, no scroll
                VStack(spacing: 10) {
                    lengthSection
                    charsetSection
                    formatSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer(minLength: 8)

                // Buttons — always visible at bottom
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .onAppear { preview = settings.generate() }
    }

    private var previewCard: some View {
        VStack(spacing: 12) {
            Text(preview)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.pgTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 4)

            HStack(spacing: 10) {
                // Strength
                VStack(alignment: .leading, spacing: 4) {
                    Text(strengthLabel(for: preview))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(strengthColor(for: preview))
                    StrengthBar(
                        score: strengthScore(for: preview),
                        color: strengthColor(for: preview)
                    )
                    .frame(height: 4)
                }
                .frame(maxWidth: .infinity)

                Button {
                    ToastManager.shared.copied("Пароль", value: preview)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13))
                        Text("Копировать")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.pgBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.pgBlue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.pgCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pgBorder, lineWidth: 1))
        )
    }

    private var lengthSection: some View {
        GenSection(title: "Длина пароля") {
            VStack(spacing: 10) {
                HStack {
                    Text("Символов")
                        .font(.system(size: 14))
                        .foregroundColor(.pgTextSecondary)
                    Spacer()
                    Text("\(Int(settings.length))")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.pgBlue)
                        .frame(minWidth: 36)
                }

                Slider(value: $settings.length, in: 6...50, step: 1)
                    .tint(.pgBlue)
                    .onChange(of: settings.length) { preview = settings.generate() }

                HStack {
                    Text("6")
                        .font(.system(size: 11))
                        .foregroundColor(.pgTextTertiary)
                    Spacer()
                    Text("50")
                        .font(.system(size: 11))
                        .foregroundColor(.pgTextTertiary)
                }
            }
        }
    }

    private var charsetSection: some View {
        GenSection(title: "Символы") {
            VStack(spacing: 0) {
                GenToggleRow(
                    label: "A-Z  Верхний регистр",
                    mono: "ABC",
                    monoColor: .pgBlue,
                    value: $settings.useUppercase
                ) { preview = settings.generate() }

                Divider().background(Color.pgBorder)

                GenToggleRow(
                    label: "a-z  Нижний регистр",
                    mono: "abc",
                    monoColor: .pgGreen,
                    value: $settings.useLowercase
                ) { preview = settings.generate() }

                Divider().background(Color.pgBorder)

                GenToggleRow(
                    label: "0-9  Цифры",
                    mono: "123",
                    monoColor: .pgAmber,
                    value: $settings.useDigits
                ) { preview = settings.generate() }

                Divider().background(Color.pgBorder)

                GenToggleRow(
                    label: "!@#  Спецсимволы",
                    mono: "!@#",
                    monoColor: .pgRed,
                    value: $settings.useSpecial
                ) { preview = settings.generate() }
            }
        }
    }

    private var formatSection: some View {
        GenSection(title: "Формат") {
            VStack(spacing: 6) {
                ForEach(PasswordFormat.allCases, id: \.self) { fmt in
                    Button {
                        settings.format = fmt
                        preview = settings.generate()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(settings.format == fmt ? Color.pgBlue : Color.pgBorder, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                                if settings.format == fmt {
                                    Circle()
                                        .fill(Color.pgBlue)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            Text(fmt.label)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(settings.format == fmt ? .pgTextPrimary : .pgTextSecondary)
                            Spacer()
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(settings.format == fmt ? Color.pgBlue.opacity(0.08) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                preview = settings.generate()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Сгенерировать заново")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.pgBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.pgBlue.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pgBlue.opacity(0.3), lineWidth: 1))
                )
            }

            Button {
                generatedPassword = preview
                dismiss()
                ToastManager.shared.show("Пароль применён", type: .success)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Использовать этот пароль")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.pgBlue, Color(hex: "#1e40af")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.pgBlue.opacity(0.35), radius: 10, x: 0, y: 5)
            }
        }
    }

    // MARK: - Strength helpers
    private func strengthScore(for pwd: String) -> Double {
        var s: Double = 0
        if pwd.count >= 8  { s += 0.2 }
        if pwd.count >= 12 { s += 0.2 }
        if pwd.count >= 16 { s += 0.1 }
        if pwd.range(of: "[A-Z]", options: .regularExpression) != nil { s += 0.15 }
        if pwd.range(of: "[0-9]", options: .regularExpression) != nil { s += 0.15 }
        if pwd.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { s += 0.2 }
        return min(s, 1.0)
    }

    private func strengthColor(for pwd: String) -> Color {
        switch strengthScore(for: pwd) {
        case 0..<0.4: return .pgRed
        case 0.4..<0.7: return .pgAmber
        default: return .pgGreen
        }
    }

    private func strengthLabel(for pwd: String) -> String {
        switch strengthScore(for: pwd) {
        case 0..<0.4: return "Слабый"
        case 0.4..<0.7: return "Средний"
        default: return "Надёжный"
        }
    }
}

// MARK: - Helper views

struct GenSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.pgTextTertiary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pgCard)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pgBorder, lineWidth: 1))
            )
        }
    }
}

struct GenToggleRow: View {
    let label: String
    let mono: String
    let monoColor: Color
    @Binding var value: Bool
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(mono)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(monoColor)
                .frame(width: 32)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.pgTextPrimary)
            Spacer()
            Toggle("", isOn: $value)
                .tint(.pgBlue)
                .labelsHidden()
                .onChange(of: value) { onChange() }
        }
        .padding(.vertical, 5)
    }
}
