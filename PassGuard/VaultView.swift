import SwiftUI

struct VaultView: View {
    @EnvironmentObject var store: CredentialStore
    @State private var search: String = ""
    @State private var editTarget: Credential? = nil
    @FocusState private var searchFocused: Bool

    var filtered: [Credential] {
        if search.isEmpty { return store.items }
        let q = search.lowercased()
        return store.items.filter {
            $0.url.lowercased().contains(q) ||
            $0.login.lowercased().contains(q) ||
            $0.displayTitle.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            searchBar
            list
        }
        .background(Color.pgBackground)
        .sheet(item: $editTarget) { cred in
            AddEditView(credential: cred, onSave: { updated in
                store.save(updated)
                editTarget = nil
            })
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PassGuard")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.pgTextPrimary)
                Text("\(store.items.count) записей")
                    .font(.system(size: 12))
                    .foregroundColor(.pgTextSecondary)
            }
            Spacer()
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 22))
                .foregroundColor(.pgBlue)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.pgTextTertiary)

            TextField("Поиск...", text: $search)
                .font(.system(size: 15))
                .foregroundColor(.pgTextPrimary)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Отмена") {
                            search = ""
                            searchFocused = false
                        }
                        .foregroundColor(.pgBlue)
                    }
                }

            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.pgTextTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pgSecondary)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pgBorder, lineWidth: 1))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var list: some View {
        Group {
            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "lock.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.pgTextTertiary)
                    Text(store.items.isEmpty ? "Нет записей" : "Ничего не найдено")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.pgTextSecondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filtered) { cred in
                            CredentialRow(credential: cred)
                                .onTapGesture { editTarget = cred }
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = cred.login
                                        ToastManager.shared.show("Логин скопирован")
                                    } label: { Label("Копировать логин", systemImage: "person") }

                                    Button {
                                        UIPasteboard.general.string = cred.password
                                        ToastManager.shared.show("Пароль скопирован")
                                    } label: { Label("Копировать пароль", systemImage: "key") }

                                    if !cred.token.isEmpty {
                                        Button {
                                            UIPasteboard.general.string = cred.token
                                            ToastManager.shared.show("Токен скопирован")
                                        } label: { Label("Копировать токен", systemImage: "chevron.left.forwardslash.chevron.right") }
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        withAnimation { store.delete(cred) }
                                    } label: { Label("Удалить", systemImage: "trash") }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

struct CredentialRow: View {
    let credential: Credential
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        HStack(spacing: 14) {
            InitialsAvatar(
                text: credential.initials,
                color: credential.accentColor
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(credential.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pgTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if !credential.login.isEmpty {
                        Text(credential.login)
                            .font(.system(size: 11))
                            .foregroundColor(.pgTextSecondary)
                            .lineLimit(1)
                    }
                    if !credential.token.isEmpty {
                        Text("Token")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.pgAmber)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.pgAmber.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if !credential.password.isEmpty {
                    StrengthBar(score: credential.strengthScore, color: credential.strengthColor)
                        .frame(width: 36)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.pgTextTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.pgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.pgBorder, lineWidth: 1)
                )
        )
    }
}
