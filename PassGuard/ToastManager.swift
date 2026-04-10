import SwiftUI
import Combine

struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
    var type: ToastType = .info

    enum ToastType { case info, success, error }
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var current: ToastMessage?

    private var cancel: AnyCancellable?

    func show(_ text: String, icon: String = "checkmark.circle.fill", type: ToastMessage.ToastType = .success) {
        cancel?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            current = ToastMessage(text: text, icon: icon, type: type)
        }
        cancel = Just(())
            .delay(for: 2.2, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    self?.current = nil
                }
            }
    }
}
