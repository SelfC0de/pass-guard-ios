import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @StateObject private var store = CredentialStore()
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var pinStore = PinStore.shared
    @State private var selectedTab: AppTab = .vault
    @State private var isLocked: Bool = true
    @State private var showPin: Bool = false

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()

            if isLocked {
                if showPin {
                    PinEntryView(
                        mode: .verify,
                        onSuccess: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isLocked = false
                            }
                        },
                        onCancel: pinStore.hasPin ? {
                            // Back to Face ID screen if biometrics available
                            showPin = false
                            authenticate()
                        } : nil
                    )
                } else {
                    LockScreen(onUnlock: { authenticate() },
                               onPinFallback: pinStore.hasPin ? { showPin = true } : nil)
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
        .onAppear { authenticate() }
    }

    func authenticate() {
        let ctx = LAContext()
        var error: NSError?

        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Биометрия недоступна — сразу PIN если есть, иначе открыть
            DispatchQueue.main.async {
                if pinStore.hasPin { showPin = true }
                else { isLocked = false }
            }
            return
        }

        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Разблокируйте PassGuard"
        ) { success, laError in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isLocked = false
                        showPin = false
                    }
                } else {
                    // Face ID не прошёл — автоматически на PIN если включён
                    if pinStore.hasPin {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showPin = true
                        }
                    }
                    // Если PIN не включён — остаёмся на LockScreen с кнопкой повтора
                }
            }
        }
    }
}

// MARK: - LockScreen

struct LockScreen: View {
    let onUnlock: () -> Void
    let onPinFallback: (() -> Void)?

    @State private var biometricIcon: String = "faceid"

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle().fill(Color.pgBlue.opacity(0.12)).frame(width: 100, height: 100)
                Circle().fill(Color.pgBlue.opacity(0.07)).frame(width: 130, height: 130)
                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.pgBlue)
            }
            .padding(.bottom, 28)

            VStack(spacing: 6) {
                Text("PassGuard")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.pgTextPrimary)
                Text("Требуется аутентификация")
                    .font(.system(size: 15))
                    .foregroundColor(.pgTextSecondary)
            }
            .padding(.bottom, 40)

            VStack(spacing: 14) {
                Button(action: onUnlock) {
                    HStack(spacing: 10) {
                        Image(systemName: biometricIcon)
                            .font(.system(size: 18))
                        Text("Разблокировать")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [.pgBlue, Color(hex: "#1e40af")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                    .shadow(color: Color.pgBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 40)

                if let pinAction = onPinFallback {
                    Button(action: pinAction) {
                        HStack(spacing: 6) {
                            Image(systemName: "number.circle")
                                .font(.system(size: 14))
                            Text("Войти по PIN-коду")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.pgTextSecondary)
                    }
                }
            }

            Spacer()
        }
        .onAppear { detectBiometricType() }
    }

    private func detectBiometricType() {
        let ctx = LAContext()
        var err: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            biometricIcon = ctx.biometryType == .touchID ? "touchid" : "faceid"
        }
    }
}
