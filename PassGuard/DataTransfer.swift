import SwiftUI
import UniformTypeIdentifiers

// MARK: - Export

func exportJSON(_ items: [Credential]) -> Data? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return try? encoder.encode(items)
}

func exportCSV(_ items: [Credential]) -> Data? {
    var lines = ["title,url,login,password,token,category,created"]
    for c in items {
        let row = [c.title, c.url, c.login, c.password, c.token,
                   c.category.rawValue, ISO8601DateFormatter().string(from: c.createdAt)]
            .map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }
            .joined(separator: ",")
        lines.append(row)
    }
    return lines.joined(separator: "\n").data(using: .utf8)
}

func exportTXT(_ items: [Credential]) -> Data? {
    var lines: [String] = ["PassGuard Export — \(Date().formatted())", String(repeating: "─", count: 40)]
    for (i, c) in items.enumerated() {
        lines.append("\n[\(i+1)] \(c.displayTitle)")
        if !c.title.isEmpty    { lines.append("  Название : \(c.title)") }
        if !c.url.isEmpty      { lines.append("  URL      : \(c.url)") }
        if !c.login.isEmpty    { lines.append("  Логин    : \(c.login)") }
        if !c.password.isEmpty { lines.append("  Пароль   : \(c.password)") }
        if !c.token.isEmpty    { lines.append("  Токен    : \(c.token)") }
        lines.append("  Категория: \(c.category.label)")
    }
    return lines.joined(separator: "\n").data(using: .utf8)
}

// MARK: - Import

enum ImportError: LocalizedError {
    case empty, parseError(String), noItems

    var errorDescription: String? {
        switch self {
        case .empty: return "Файл пустой"
        case .parseError(let s): return "Ошибка парсинга: \(s)"
        case .noItems: return "Записи не найдены"
        }
    }
}

func importJSON(_ data: Data) throws -> [Credential] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let items = try decoder.decode([Credential].self, from: data)
    guard !items.isEmpty else { throw ImportError.noItems }
    return items
}

func importCSV(_ data: Data) throws -> [Credential] {
    guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { throw ImportError.empty }
    let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
    guard lines.count > 1 else { throw ImportError.noItems }

    // Parse header
    let headers = parseCSVRow(lines[0])
    func idx(_ name: String) -> Int? { headers.firstIndex(of: name) }

    var result: [Credential] = []
    for line in lines.dropFirst() {
        let cols = parseCSVRow(line)
        func col(_ name: String) -> String { idx(name).map { $0 < cols.count ? cols[$0] : "" } ?? "" }
        var c = Credential()
        c.title    = col("title")
        c.url      = col("url")
        c.login    = col("login")
        c.password = col("password")
        c.token    = col("token")
        if let cat = CredentialCategory(rawValue: col("category")) { c.category = cat }
        result.append(c)
    }
    guard !result.isEmpty else { throw ImportError.noItems }
    return result
}

func importTXT(_ data: Data) throws -> [Credential] {
    guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { throw ImportError.empty }
    var result: [Credential] = []
    var current: Credential? = nil

    for line in text.components(separatedBy: "\n") {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("[") && t.contains("]") {
            if let prev = current { result.append(prev) }
            current = Credential()
        } else if let c = current {
            var cr = c
            if t.hasPrefix("Название :") { cr.title    = extract(t, "Название :") }
            if t.hasPrefix("URL      :") { cr.url      = extract(t, "URL      :") }
            if t.hasPrefix("Логин    :") { cr.login    = extract(t, "Логин    :") }
            if t.hasPrefix("Пароль   :") { cr.password = extract(t, "Пароль   :") }
            if t.hasPrefix("Токен    :") { cr.token    = extract(t, "Токен    :") }
            current = cr
        }
    }
    if let last = current { result.append(last) }
    guard !result.isEmpty else { throw ImportError.noItems }
    return result
}

private func extract(_ line: String, _ prefix: String) -> String {
    line.components(separatedBy: ": ").dropFirst().joined(separator: ": ").trimmingCharacters(in: .whitespaces)
}

private func parseCSVRow(_ row: String) -> [String] {
    var fields: [String] = []
    var cur = ""
    var inQuotes = false
    var i = row.startIndex
    while i < row.endIndex {
        let ch = row[i]
        if ch == "\"" {
            if inQuotes && row.index(after: i) < row.endIndex && row[row.index(after: i)] == "\"" {
                cur += "\""
                i = row.index(after: i)
            } else {
                inQuotes.toggle()
            }
        } else if ch == "," && !inQuotes {
            fields.append(cur); cur = ""
        } else {
            cur.append(ch)
        }
        i = row.index(after: i)
    }
    fields.append(cur)
    return fields
}

// MARK: - Share sheet helper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Export format

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv  = "CSV"
    case txt  = "TXT"

    var ext: String { rawValue.lowercased() }
    var icon: String {
        switch self {
        case .json: return "curlybraces"
        case .csv:  return "tablecells"
        case .txt:  return "doc.text"
        }
    }
    var mime: UTType {
        switch self {
        case .json: return .json
        case .csv:  return .commaSeparatedText
        case .txt:  return .plainText
        }
    }
}
