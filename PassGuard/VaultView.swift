import SwiftUI

struct VaultView: View {
    @EnvironmentObject var store: CredentialStore
    @EnvironmentObject var settings: SettingsStore
    @State private var search: String = ""
    @State private var selectedCategory: CredentialCategory = .general
    @State private var editTarget: Credential? = nil
    @State private var showDeleteAll: Bool = false
    @FocusState private var searchFocused: Bool

    var filtered: [Credential] {
        let base = store.items(for: selectedCategory)
        if search.isEmpty { return base }
        let q = search.lowercased()
        return base.filter {
            $0.url.lowercased().contains(q) ||
            $0.login.lowercased().contains(q) ||
            $0.displayTitle.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            categoryCards
            searchBar
            list
        }
        .background(Color.pgBackground)
        .sheet(item: $editTarget) { cred in
            AddEditView(credential: cred, onSave: { updated in
                // Only save if something actually changed
                if updated != cred {
                    store.save(updated)
                }
                editTarget = nil
            })
            .id(cred.id)
        }
        .alert("Удалить все записи?", isPresented: $showDeleteAll) {
            Button("Удалить всё", role: .destructive) {
                withAnimation {
                    store.deleteAll()
                    selectedCategory = .general
                }
                ToastManager.shared.show("Все записи удалены", type: .error)
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Это действие нельзя отменить. Будут удалены все \(store.items.count) \(pluralRecords(store.items.count)).")
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PassGuard")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.pgTextPrimary)
                Text("\(store.items.count) \(pluralRecords(store.items.count))")
                    .font(.system(size: 12))
                    .foregroundColor(.pgTextSecondary)
            }
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 20))
                    .foregroundColor(.pgBlue)

                if !store.items.isEmpty {
                    Button {
                        showDeleteAll = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 17))
                            .foregroundColor(.pgRed.opacity(0.8))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: - Category cards (2x2 grid)
    private var categoryCards: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
            spacing: 10
        ) {
            ForEach(CredentialCategory.allCases, id: \.self) { cat in
                CategoryCard(
                    category: cat,
                    count: cat == .general ? store.items.count : store.items(for: cat).count,
                    isSelected: selectedCategory == cat
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = cat
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Search
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

    // MARK: - List
    private var list: some View {
        Group {
            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: emptyIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.pgTextTertiary)
                    Text(emptyTitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.pgTextSecondary)
                    Text(emptySubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.pgTextTertiary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.horizontal, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filtered) { cred in
                            CredentialRow(credential: cred)
                                .onTapGesture { editTarget = cred }
                                .contextMenu {
                                    if !cred.login.isEmpty {
                                        Button { ToastManager.shared.copied("Логин", value: cred.login) }
                                        label: { Label("Копировать логин", systemImage: "person") }
                                    }
                                    if !cred.password.isEmpty {
                                        Button { ToastManager.shared.copied("Пароль", value: cred.password) }
                                        label: { Label("Копировать пароль", systemImage: "key") }
                                    }
                                    if !cred.token.isEmpty {
                                        Button { ToastManager.shared.copied("Токен", value: cred.token) }
                                        label: { Label("Копировать токен", systemImage: "chevron.left.forwardslash.chevron.right") }
                                    }
                                    if !cred.url.isEmpty {
                                        Button { ToastManager.shared.copied("URL", value: cred.url) }
                                        label: { Label("Копировать URL", systemImage: "link") }
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

    private var emptyIcon: String {
        switch selectedCategory {
        case .general:  return store.items.isEmpty ? "lock.slash" : "magnifyingglass"
        case .codes:    return "barcode"
        case .wifi:     return "wifi.slash"
        case .security: return "lock.shield"
        }
    }

    private var emptyTitle: String {
        if !search.isEmpty { return "Ничего не найдено" }
        switch selectedCategory {
        case .general:  return "Нет записей"
        case .codes:    return "Нет кодов"
        case .wifi:     return "Нет Wi-Fi"
        case .security: return "Нет записей безопасности"
        }
    }

    private var emptySubtitle: String {
        if !search.isEmpty { return "Попробуйте изменить запрос" }
        return "Добавьте запись через вкладку «Добавить»"
    }

    private func pluralRecords(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "запись" }
        if (2...4).contains(mod10) && !(11...14).contains(mod100) { return "записи" }
        return "записей"
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: CredentialCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(category.accent.opacity(isSelected ? 0.28 : 0.14))
                        .frame(width: 42, height: 42)
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(category.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? category.accent : .pgTextPrimary)
                        .lineLimit(1)
                    Text("\(count) " + plural(count))
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? category.accent.opacity(0.7) : .pgTextSecondary)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(category.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? category.accent.opacity(0.08) : Color.pgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? category.accent.opacity(0.5) : Color.pgBorder,
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func plural(_ n: Int) -> String {
        let m10 = n % 10, m100 = n % 100
        if m10 == 1 && m100 != 11 { return "запись" }
        if (2...4).contains(m10) && !(11...14).contains(m100) { return "записи" }
        return "записей"
    }
}

// MARK: - Credential Row

struct CredentialRow: View {
    let credential: Credential
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        HStack(spacing: 14) {
            FaviconView(
                urlString: credential.url,
                fallbackText: credential.initials,
                fallbackColor: credential.accentColor,
                size: 36
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
                        categoryPill(text: "Токен", color: .pgAmber)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                categoryPill(text: credential.category.label, color: credential.category.accent)
                    .opacity(credential.category == .general ? 0 : 1)
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
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pgBorder, lineWidth: 1))
        )
    }

    private func categoryPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
