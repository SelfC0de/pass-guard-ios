import SwiftUI

struct AddEditView: View {
    let credential: Credential?
    let onSave: (Credential) -> Void

    @EnvironmentObject var store: CredentialStore

    @State private var draft: Credential = Credential()
    @State private var isEdit: Bool = false
    @State private var showGenerator: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @StateObject private var genSettings = PasswordGeneratorSettings()

    @FocusState private var focusedField: FormField?
    enum FormField { case title, login, password, token, url, notes }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#1c1c1e").ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: 20) {
                        iconCard
                        fieldsCard
                        categoryCard
                        if isEdit { deleteSection }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $showGenerator) {
            PasswordGeneratorSheet(settings: genSettings, generatedPassword: $draft.password)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Удалить запись?", isPresented: $showDeleteConfirm) {
            Button("Удалить", role: .destructive) {
                if let c = credential { store.delete(c) }
                onSave(draft)
            }
            Button("Отмена", role: .cancel) {}
        }
        .onAppear { loadDraft() }
        .onChange(of: credential) { loadDraft() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { focusedField = nil }
                    .foregroundColor(.pgBlue)
                    .fontWeight(.medium)
            }
        }
    }

    private func loadDraft() {
        if let c = credential { draft = c; isEdit = true }
        else { draft = Credential(); isEdit = false }
    }

    // MARK: - Nav bar
    private var navBar: some View {
        HStack {
            Button {
                onSave(draft)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.pgTextPrimary)
                }
            }

            Spacer()

            Text(isEdit ? "Редактировать" : "Новый пароль")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.pgTextPrimary)

            Spacer()

            Button {
                focusedField = nil
                store.save(draft)
                onSave(draft)
                ToastManager.shared.show(isEdit ? "Сохранено" : "Добавлено")
            } label: {
                ZStack {
                    Circle()
                        .fill(canSave ? Color.pgBlue : Color.pgBlue.opacity(0.3))
                        .frame(width: 32, height: 32)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(hex: "#1c1c1e"))
    }

    private var canSave: Bool {
        !draft.url.isEmpty || !draft.login.isEmpty || !draft.token.isEmpty
    }

    // MARK: - Icon + title card
    private var iconCard: some View {
        VStack(spacing: 14) {
            // App icon / category icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [draft.category.accent.opacity(0.8), draft.category.accent],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: draft.category.accent.opacity(0.5), radius: 10, x: 0, y: 4)
                Image(systemName: draft.category.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: draft.category)

            // Editable title
            TextField("Название", text: $draft.title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(draft.title.isEmpty ? Color.white.opacity(0.25) : .pgTextPrimary)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: .title)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#2c2c2e"))
        )
    }

    // MARK: - Fields card
    private var fieldsCard: some View {
        VStack(spacing: 0) {
            // Title
            InlineField(
                label: "Название",
                placeholder: "необязательно",
                text: $draft.title,
                isSecure: false,
                keyboard: .default,
                focused: $focusedField,
                field: .title,
                trailingAction: nil,
                trailingIcon: nil
            )

            divider

            // Login
            InlineField(
                label: "Имя пользователя",
                placeholder: "имя пользователя",
                text: $draft.login,
                isSecure: false,
                keyboard: .emailAddress,
                focused: $focusedField,
                field: .login,
                trailingAction: draft.login.isEmpty ? nil : { ToastManager.shared.copied("Логин", value: draft.login) },
                trailingIcon: draft.login.isEmpty ? nil : "doc.on.doc"
            )

            divider

            // Password
            InlineField(
                label: "Пароль",
                placeholder: "пароль",
                text: $draft.password,
                isSecure: true,
                keyboard: .default,
                focused: $focusedField,
                field: .password,
                trailingAction: {
                    focusedField = nil
                    showGenerator = true
                },
                trailingIcon: "wand.and.stars"
            )

            if !draft.password.isEmpty {
                HStack(spacing: 8) {
                    StrengthBar(score: draft.strengthScore, color: draft.strengthColor)
                    Text(strengthLabel)
                        .font(.system(size: 11))
                        .foregroundColor(draft.strengthColor)
                        .frame(width: 56, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "#2c2c2e"))
            }

            divider

            // URL
            InlineField(
                label: "Веб-сайт",
                placeholder: "example.com",
                text: $draft.url,
                isSecure: false,
                keyboard: .URL,
                focused: $focusedField,
                field: .url,
                trailingAction: draft.url.isEmpty ? nil : { ToastManager.shared.copied("URL", value: draft.url) },
                trailingIcon: draft.url.isEmpty ? nil : "doc.on.doc"
            )

            divider

            // Token
            InlineField(
                label: "Токен / API Key",
                placeholder: "необязательно",
                text: $draft.token,
                isSecure: true,
                keyboard: .default,
                focused: $focusedField,
                field: .token,
                trailingAction: draft.token.isEmpty ? nil : { ToastManager.shared.copied("Токен", value: draft.token) },
                trailingIcon: draft.token.isEmpty ? nil : "doc.on.doc"
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#2c2c2e"))
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private var strengthLabel: String {
        switch draft.strengthScore {
        case 0..<0.4:   return "Слабый"
        case 0.4..<0.7: return "Средний"
        default:         return "Сильный"
        }
    }

    // MARK: - Category card
    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array([CredentialCategory.general, .codes, .wifi, .security].enumerated()), id: \.offset) { idx, cat in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        draft.category = cat
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(cat.accent.opacity(0.2))
                                .frame(width: 28, height: 28)
                            Image(systemName: cat.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(cat.accent)
                        }
                        Text(cat == .general ? "Общее" : cat.label)
                            .font(.system(size: 16))
                            .foregroundColor(.pgTextPrimary)
                        Spacer()
                        if draft.category == cat {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.pgBlue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if idx < 3 { divider }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#2c2c2e"))
        )
    }

    // MARK: - Delete
    private var deleteSection: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            Text("Удалить пароль")
                .font(.system(size: 17))
                .foregroundColor(.pgRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#2c2c2e"))
                )
        }
    }
}

// MARK: - Inline field component

struct InlineField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var keyboard: UIKeyboardType
    @FocusState.Binding var focused: AddEditView.FormField?
    let field: AddEditView.FormField
    var trailingAction: (() -> Void)?
    var trailingIcon: String?

    @State private var revealed: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.pgTextPrimary)
                .frame(width: 150, alignment: .leading)

            Group {
                if isSecure && !revealed {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                }
            }
            .font(.system(size: 16))
            .foregroundColor(Color.white.opacity(0.45))
            .focused($focused, equals: field)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .multilineTextAlignment(.trailing)

            if isSecure && !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { revealed.toggle() }
                } label: {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.3))
                        .padding(.leading, 8)
                }
            }

            if let icon = trailingIcon, let action = trailingAction {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.pgBlue.opacity(0.8))
                        .padding(.leading, 8)
                }
            }

            // Paste button
            Button {
                if let clip = UIPasteboard.general.string, !clip.isEmpty {
                    text = clip
                    ToastManager.shared.show("Вставлено из буфера", type: .info)
                }
            } label: {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.2))
                    .padding(.leading, 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
