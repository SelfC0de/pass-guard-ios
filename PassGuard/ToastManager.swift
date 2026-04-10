import SwiftUI
import Combine

enum ToastType {
    case success, error, info, copy

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        case .copy:    return "doc.on.doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .pgGreen
        case .error:   return .pgRed
        case .info:    return .pgBlue
        case .copy:    return Color(hex: "#a855f7")
        }
    }

    var bgColor: Color {
        switch self {
        case .success: return Color(hex: "#052e16")
        case .error:   return Color(hex: "#450a0a")
        case .info:    return Color(hex: "#0c1a2e")
        case .copy:    return Color(hex: "#1a0533")
        }
    }

    var borderColor: Color {
        switch self {
        case .success: return Color(hex: "#166534").opacity(0.8)
        case .error:   return Color(hex: "#7f1d1d").opacity(0.8)
        case .info:    return Color(hex: "#1e3a5f").opacity(0.8)
        case .copy:    return Color(hex: "#6b21a8").opacity(0.8)
        }
    }
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
    let subtext: String?
    let type: ToastType

    init(_ text: String, subtext: String? = nil, type: ToastType = .success) {
        self.text = text
        self.subtext = subtext
        self.type = type
    }
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var current: ToastMessage?
    private var cancel: AnyCancellable?

    func show(_ text: String, subtext: String? = nil, type: ToastType = .success) {
        cancel?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            current = ToastMessage(text, subtext: subtext, type: type)
        }
        cancel = Just(())
            .delay(for: 2.4, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self?.current = nil
                }
            }
    }

    func copied(_ label: String, value: String) {
        UIPasteboard.general.string = value
        let preview = value.count > 20 ? String(value.prefix(20)) + "…" : value
        show("\(label) скопирован", subtext: preview, type: .copy)
    }
}
