import SwiftUI

enum AppTab: Int, CaseIterable {
    case vault = 0
    case add   = 1
    case settings = 2

    var icon: String {
        switch self {
        case .vault:    return "rectangle.stack.fill"
        case .add:      return "plus.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .vault:    return "Vault"
        case .add:      return "Add"
        case .settings: return "Settings"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: tab == .add ? 26 : 20))
                            .foregroundColor(selected == tab ? .pgBlue : .pgTextTertiary)
                            .scaleEffect(selected == tab ? 1.12 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)

                        Text(tab.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selected == tab ? .pgBlue : .pgTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(
            Rectangle()
                .fill(Color.pgSecondary)
                .overlay(
                    Rectangle()
                        .fill(Color.pgBorder)
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
        .ignoresSafeArea(edges: .bottom)
    }
}
