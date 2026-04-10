import SwiftUI

struct AddEditView: View {
    let credential: Credential?
    let onSave: (Credential) -> Void

    @EnvironmentObject var store: CredentialStore

    @State private var draft: Credential = Credential()
    @State private var isEdit: Bool = false

    @FocusState private var focusedURL: Bool
    @FocusState private var focusedLogin: Bool
    @FocusState private var focusedPassword: Bool
    @FocusState private var focusedToken: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.pgBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        fieldsSection
                        saveButton
                        if isEdit { deleteButton }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        focusedURL = false
                        focusedLogin = false
                        focusedPassword = false
                        focusedToken = false
                    }
                    .foregroundColor(.pgBlue)
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear { loadDraft() }
        .onChange(of: credential) { _ in loadDraft() }
    }

    private func loadDraft() {
        if let c = credential {
            draft = c
            isEdit = true
        } else {
            draft = Credential()
            isEdit = false
        }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            InitialsAvatar(
                text: draft.initials,
                color: draft.accentColor,
                size: 48
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(isEdit ? "Редактировать" : "Новая запись")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.pgTextPrimary)
                Text(draft.displayTitle.isEmpty ? "Заполните поля" : draft.displayTitle)
                    .font(.system(size: 13))
                    .foregroundColor(.pgTextSecondary)
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            PGTextField(
                label: "URL / Сайт",
                icon: "link",
                placeholder: "https://example.com",
                text: $draft.url,
                keyboard: .URL,
                focused: $focusedURL
            )

            PGTextField(
                label: "Логин / Email",
                icon: "person",
                placeholder: "user@email.com",
                text: $draft.login,
                keyboard: .emailAddress,
                focused: $focusedLogin
            )

            PGTextField(
                label: "Пароль",
                icon: "key",
                placeholder: "Пароль",
                text: $draft.password,
                isSecure: true,
                focused: $focusedPassword
            )

            if !draft.password.isEmpty {
                HStack(spacing: 8) {
                    StrengthBar(score: draft.strengthScore, color: draft.strengthColor)
                    Text(strengthLabel)
                        .font(.system(size: 11))
                        .foregroundColor(draft.strengthColor)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.top, -6)
            }

            PGTextField(
                label: "Токен / API Key",
                icon: "chevron.left.forwardslash.chevron.right",
                placeholder: "ghp_abc123...",
                text: $draft.token,
                isSecure: true,
                focused: $focusedToken
            )
        }
    }

    private var strengthLabel: String {
        switch draft.strengthScore {
        case 0..<0.4:  return "Слабый"
        case 0.4..<0.7: return "Средний"
        default:        return "Сильный"
        }
    }

    private var saveButton: some View {
        Button {
            focusedURL = false
            focusedLogin = false
            focusedPassword = false
            focusedToken = false
            store.save(draft)
            onSave(draft)
            ToastManager.shared.show(isEdit ? "Сохранено" : "Добавлено", icon: "checkmark.circle.fill")
            if !isEdit { draft = Credential() }
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text(isEdit ? "Сохранить" : "Добавить запись")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
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
        }
        .disabled(draft.url.isEmpty && draft.login.isEmpty && draft.token.isEmpty)
        .opacity((draft.url.isEmpty && draft.login.isEmpty && draft.token.isEmpty) ? 0.4 : 1)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.2), value: draft.url + draft.login + draft.token)
    }

    private var deleteButton: some View {
        Button {
            if let c = credential { store.delete(c) }
            onSave(draft)
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Удалить запись")
            }
            .foregroundColor(.pgRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pgRed.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pgRed.opacity(0.25), lineWidth: 1))
            )
        }
    }
}
