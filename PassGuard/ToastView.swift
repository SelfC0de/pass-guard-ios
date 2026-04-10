import SwiftUI

struct ToastView: View {
    let msg: ToastMessage
    @State private var appear = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(msg.type.color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: msg.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(msg.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(msg.text)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                if let sub = msg.subtext {
                    Text(sub)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(msg.type.bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(msg.type.borderColor, lineWidth: 1)
                )
        )
        .shadow(color: msg.type.color.opacity(0.25), radius: 20, x: 0, y: 8)
        .scaleEffect(appear ? 1 : 0.88)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                appear = true
            }
        }
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
                        .padding(.horizontal, 20)
                        .padding(.top, 56)
                        .id(msg.id)
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: toast.current?.id)
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlay())
    }
}
