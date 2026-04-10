import SwiftUI

// Extracts base domain from any URL string
func extractDomain(_ raw: String) -> String? {
    var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if !s.contains("://") { s = "https://" + s }
    guard let host = URLComponents(string: s)?.host, !host.isEmpty else { return nil }
    // Strip "www."
    return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
}

// In-memory cache: domain -> image data
final class FaviconCache {
    static let shared = FaviconCache()
    private var cache: [String: UIImage] = [:]
    private var failed: Set<String> = []

    func get(_ domain: String) -> UIImage? { cache[domain] }
    func set(_ domain: String, image: UIImage) { cache[domain] = image }
    func markFailed(_ domain: String) { failed.insert(domain) }
    func hasFailed(_ domain: String) -> Bool { failed.contains(domain) }
}

// Favicon URLs to try in order
func faviconURLs(for domain: String) -> [URL] {
    let sources = [
        "https://www.google.com/s2/favicons?domain=\(domain)&sz=64",
        "https://icons.duckduckgo.com/ip3/\(domain).ico",
        "https://\(domain)/favicon.ico",
    ]
    return sources.compactMap { URL(string: $0) }
}

@MainActor
class FaviconViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    private var domain: String?

    func load(from urlString: String) {
        guard let domain = extractDomain(urlString), domain != self.domain else { return }
        self.domain = domain

        if let cached = FaviconCache.shared.get(domain) {
            image = cached
            return
        }
        if FaviconCache.shared.hasFailed(domain) { return }

        Task {
            await tryLoad(domain: domain, urls: faviconURLs(for: domain))
        }
    }

    private func tryLoad(domain: String, urls: [URL]) async {
        for url in urls {
            if let img = await fetchImage(url: url) {
                FaviconCache.shared.set(domain, image: img)
                image = img
                return
            }
        }
        FaviconCache.shared.markFailed(domain)
    }

    private func fetchImage(url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let img = UIImage(data: data),
                  img.size.width > 4 // filter out 1x1 placeholder pixels
            else { return nil }
            return img
        } catch {
            return nil
        }
    }
}

// Drop-in view: shows favicon or fallback avatar
struct FaviconView: View {
    let urlString: String
    let fallbackText: String
    let fallbackColor: Color
    var size: CGFloat = 36

    @StateObject private var vm = FaviconViewModel()

    var body: some View {
        ZStack {
            if let img = vm.image {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                    .transition(.opacity.animation(.easeIn(duration: 0.2)))
            } else {
                // Fallback: letter avatar
                Circle()
                    .fill(fallbackColor.opacity(0.15))
                    .overlay(Circle().stroke(fallbackColor.opacity(0.35), lineWidth: 1))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(fallbackText)
                            .font(.system(size: size * 0.36, weight: .bold))
                            .foregroundColor(fallbackColor)
                    )
            }
        }
        .frame(width: size, height: size)
        .onAppear { vm.load(from: urlString) }
        .onChange(of: urlString) { vm.load(from: urlString) }
    }
}
