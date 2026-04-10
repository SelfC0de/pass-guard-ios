import SwiftUI

struct ToastView: View {
    let msg: ToastMessage

    var iconColor: Color {
        switch msg.type {
        case .success: return .pgGreen
        case .error:   return .pgRed
        case .info:    return .pgBlue
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: msg.icon)
                .foregroundColor(iconColor)
                .font(.system(size: 15, weight: .semibold))
            Text(msg.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.pgTextPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.pgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.pgBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 6)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }
}

struct ToastOverlay: ViewModifier {
    @ObservedObject var toast = ToastManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content
            if let msg = toast.current {
                VStack {
                    ToastView(msg: msg)
                        .padding(.top, 56)
                    Spacer()
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: toast.current?.id)
            }
        }
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlay())
    }
}
