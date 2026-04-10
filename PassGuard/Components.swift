import SwiftUI

struct PGTextField: View {
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    @FocusState.Binding var focused: Bool

    @State private var revealed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.pgTextSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.pgTextTertiary)
                    .frame(width: 20)

                Group {
                    if isSecure && !revealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboard)
                    }
                }
                .font(.system(size: 15))
                .foregroundColor(.pgTextPrimary)
                .focused($focused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                HStack(spacing: 6) {
                    if isSecure {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { revealed.toggle() }
                        } label: {
                            Image(systemName: revealed ? "eye.slash" : "eye")
                                .font(.system(size: 13))
                                .foregroundColor(.pgTextTertiary)
                        }
                    }

                    Button {
                        if let clip = UIPasteboard.general.string {
                            text = clip
                            ToastManager.shared.show("Вставлено", icon: "doc.on.clipboard.fill")
                        }
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 13))
                            .foregroundColor(.pgTextTertiary)
                    }

                    if !text.isEmpty {
                        Button {
                            UIPasteboard.general.string = text
                            ToastManager.shared.show("Скопировано", icon: "checkmark.circle.fill")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 13))
                                .foregroundColor(.pgBlue.opacity(0.8))
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focused ? Color.pgBlue.opacity(0.5) : Color.pgBorder, lineWidth: focused ? 1.5 : 1)
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: focused)
        }
    }
}

struct StrengthBar: View {
    let score: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.06))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * score)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: score)
            }
        }
        .frame(height: 4)
    }
}

struct InitialsAvatar: View {
    let text: String
    let color: Color
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .overlay(Circle().stroke(color.opacity(0.35), lineWidth: 1))
            Text(text)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

struct CopyButton: View {
    let value: String
    let label: String

    var body: some View {
        Button {
            UIPasteboard.general.string = value
            ToastManager.shared.show("\(label) скопирован", icon: "checkmark.circle.fill")
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 14))
                .foregroundColor(.pgBlue.opacity(0.7))
                .frame(width: 32, height: 32)
                .background(Color.pgBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
