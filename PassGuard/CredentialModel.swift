import Foundation
import SwiftUI

enum CredentialCategory: String, CaseIterable, Codable {
    case general  = "general"
    case codes    = "codes"
    case wifi     = "wifi"
    case security = "security"

    var label: String {
        switch self {
        case .general:  return "Все"
        case .codes:    return "Коды"
        case .wifi:     return "Wi-Fi"
        case .security: return "Безопасность"
        }
    }

    var icon: String {
        switch self {
        case .general:  return "square.grid.2x2.fill"
        case .codes:    return "barcode"
        case .wifi:     return "wifi"
        case .security: return "lock.shield.fill"
        }
    }

    var accent: Color {
        switch self {
        case .general:  return .pgBlue
        case .codes:    return .pgAmber
        case .wifi:     return .pgGreen
        case .security: return .pgPurple
        }
    }
}

struct Credential: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var url: String = ""
    var login: String = ""
    var password: String = ""
    var token: String = ""
    var category: CredentialCategory = .general
    var createdAt: Date = Date()

    var displayTitle: String {
        if !url.isEmpty {
            return url
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "www.", with: "")
                .components(separatedBy: "/").first ?? url
        }
        if !login.isEmpty { return login }
        return "Без названия"
    }

    var initials: String {
        displayTitle.first?.uppercased() ?? "?"
    }

    var accentColor: Color { category.accent }

    var strengthScore: Double {
        let p = password
        guard !p.isEmpty else { return 0 }
        var score: Double = 0
        if p.count >= 8  { score += 0.2 }
        if p.count >= 12 { score += 0.2 }
        if p.count >= 16 { score += 0.1 }
        if p.range(of: "[A-Z]", options: .regularExpression) != nil { score += 0.15 }
        if p.range(of: "[0-9]", options: .regularExpression) != nil { score += 0.15 }
        if p.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { score += 0.2 }
        return min(score, 1.0)
    }

    var strengthColor: Color {
        switch strengthScore {
        case 0..<0.4:   return .pgRed
        case 0.4..<0.7: return .pgAmber
        default:         return .pgGreen
        }
    }
}

extension Color {
    static let pgBackground    = Color(hex: "#09090f")
    static let pgSecondary     = Color(hex: "#0f0f1c")
    static let pgCard          = Color(hex: "#13131f")
    static let pgBorder        = Color(white: 1, opacity: 0.07)
    static let pgBlue          = Color(hex: "#2563eb")
    static let pgBlueDim       = Color(hex: "#1e3a5f")
    static let pgPurple        = Color(hex: "#7c3aed")
    static let pgGreen         = Color(hex: "#16a34a")
    static let pgAmber         = Color(hex: "#d97706")
    static let pgRed           = Color(hex: "#dc2626")
    static let pgTextPrimary   = Color(hex: "#e0e8ff")
    static let pgTextSecondary = Color(white: 1, opacity: 0.35)
    static let pgTextTertiary  = Color(white: 1, opacity: 0.18)

    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        h = h.hasPrefix("#") ? String(h.dropFirst()) : h
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8)  & 0xFF) / 255
        let b = Double(val         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

class CredentialStore: ObservableObject {
    @Published var items: [Credential] = []
    private let key = "pg_credentials_v1"

    init() { load() }

    func save(_ c: Credential) {
        if let idx = items.firstIndex(where: { $0.id == c.id }) {
            items[idx] = c
        } else {
            items.insert(c, at: 0)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    func delete(_ c: Credential) {
        items.removeAll { $0.id == c.id }
        persist()
    }

    func deleteAll() {
        items.removeAll()
        persist()
    }

    func items(for category: CredentialCategory) -> [Credential] {
        if category == .general { return items }
        return items.filter { $0.category == category }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Credential].self, from: data)
        else { return }
        items = decoded
    }
}
