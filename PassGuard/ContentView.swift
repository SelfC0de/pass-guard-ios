import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @StateObject private var store = CredentialStore()
    @StateObject private var settings = SettingsStore.shared
    @State private var selectedTab: AppTab = .vault
    @State private var isLocked: Bool = true
    @State private var authFailed: Bool = false

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            if isLocked && settings.biometricsEnabled {
                LockScreen(authFailed: authFailed) {
                    authenticate()
                }
            } else {
                ZStack(alignment: .bottom) {
                    ZStack {
                        VaultView()
                            .opacity(selectedTab == .vault ? 1 : 0)
                            .allowsHitTesting(selectedTab == .vault)

                        AddEditView(credential: nil, onSave: { _ in selectedTab = .vault })
                            .opacity(selectedTab == .add ? 1 : 0)
                            .allowsHitTesting(selectedTab == .add)

                        SettingsView()
                            .opacity(selectedTab == .settings ? 1 : 0)
                            .allowsHitTesting(selectedTab == .settings)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    CustomTabBar(selected: $selectedTab)
                }
            }
        }
        .environmentObject(store)
        .environmentObject(settings)
        .toastOverlay()
        .preferredColorScheme(.dark)
        .onAppear {
            if settings.biometricsEnabled {
                authenticate()
            } else {
                isLocked = false
            }
        }
    }

    private func authenticate() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isLocked = false
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Разблокируйте PassGuard"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isLocked = false
                        authFailed = false
                    }
                } else {
                    authFailed = true
                }
            }
        }
    }
}

struct LockScreen: View {
    let authFailed: Bool
    let onUnlock: () -> Void
    @State private var shake = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.pgBlue.opacity(0.12))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color.pgBlue.opacity(0.07))
                    .frame(width: 130, height: 130)
                Image(systemName: authFailed ? "lock.slash.fill" : "lock.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(authFailed ? .pgRed : .pgBlue)
            }
            .offset(x: shake ? -8 : 0)
            .animation(
                shake ? .interpolatingSpring(stiffness: 600, damping: 10) : .default,
                value: shake
            )
            .onChange(of: authFailed) { failed in
                if failed {
                    shake = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
                }
            }

            VStack(spacing: 8) {
                Text("PassGuard")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.pgTextPrimary)
                Text(authFailed ? "Аутентификация не удалась" : "Требуется аутентификация")
                    .font(.system(size: 15))
                    .foregroundColor(authFailed ? .pgRed : .pgTextSecondary)
            }

            Button(action: onUnlock) {
                HStack(spacing: 10) {
                    Image(systemName: "faceid")
                        .font(.system(size: 18))
                    Text("Разблокировать")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.pgBlue, Color(hex: "#1e40af")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.pgBlue.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}
