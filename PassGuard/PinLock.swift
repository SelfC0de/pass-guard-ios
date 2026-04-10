import SwiftUI
import LocalAuthentication

private let PIN_ENABLED_KEY = "pg_time_pin_enabled"

class PinStore: ObservableObject {
    static let shared = PinStore()

    var hasPin: Bool {
        get { UserDefaults.standard.bool(forKey: PIN_ENABLED_KEY) }
        set { UserDefaults.standard.set(newValue, forKey: PIN_ENABLED_KEY) }
    }

    // Current valid PIN = HHmm of current time
    var currentPin: String {
        let c = Calendar.current
        let h = c.component(.hour, from: Date())
        let m = c.component(.minute, from: Date())
        return String(format: "%02d%02d", h, m)
    }

    // Also accept previous minute (grace period if minute just flipped)
    var previousPin: String {
        let prev = Date().addingTimeInterval(-60)
        let c = Calendar.current
        let h = c.component(.hour, from: prev)
        let m = c.component(.minute, from: prev)
        return String(format: "%02d%02d", h, m)
    }

    func verify(_ input: String) -> Bool {
        input == currentPin || input == previousPin
    }
}

// MARK: - PIN Entry View

struct PinEntryView: View {
    enum Mode { case setup, verify }

    let mode: Mode
    var onSuccess: () -> Void
    var onCancel: (() -> Void)? = nil

    @StateObject private var pinStore = PinStore.shared
    @State private var entered: String = ""
    @State private var shake: Bool = false
    @State private var errorMsg: String = ""
    @State private var now: Date = Date()
    @State private var clockTimer: Timer? = nil
    @State private var secondsLeft: Int = 0

    private let digits = 4

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Lock icon
                ZStack {
                    Circle().fill(Color.pgBlue.opacity(0.12)).frame(width: 80, height: 80)
                    Circle().fill(Color.pgBlue.opacity(0.07)).frame(width: 100, height: 100)
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.pgBlue)
                }
                .padding(.bottom, 24)

                // Title
                VStack(spacing: 6) {
                    Text(mode == .verify ? "Введите PIN-код" : "Временной PIN включён")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.pgTextPrimary)

                    if mode == .verify {
                        Text("PIN = текущее время (ЧЧмм)")
                            .font(.system(size: 13))
                            .foregroundColor(.pgTextSecondary)
                    } else {
                        Text("PIN меняется каждую минуту")
                            .font(.system(size: 13))
                            .foregroundColor(.pgTextSecondary)
                    }

                    if !errorMsg.isEmpty {
                        Text(errorMsg)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.pgRed)
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 28)

                // Live clock hint (only on verify)
                if mode == .verify {
                    clockHint
                        .padding(.bottom, 20)
                }

                // Dots
                HStack(spacing: 20) {
                    ForEach(0..<digits, id: \.self) { i in
                        Circle()
                            .fill(i < entered.count ? Color.pgBlue : Color.pgBorder)
                            .frame(width: 14, height: 14)
                            .animation(.spring(response: 0.2), value: entered.count)
                    }
                }
                .offset(x: shake ? -10 : 0)
                .animation(shake ? .interpolatingSpring(stiffness: 600, damping: 10) : .default, value: shake)
                .padding(.bottom, 32)

                // Keypad
                keypad

                Spacer()

                if let cancel = onCancel {
                    Button("Отмена") { cancel() }
                        .font(.system(size: 16))
                        .foregroundColor(.pgTextSecondary)
                        .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            updateSeconds()
            clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                now = Date()
                updateSeconds()
                // Auto-clear entered if minute changed mid-entry
                if !entered.isEmpty {
                    entered = ""
                    errorMsg = ""
                }
            }
        }
        .onDisappear {
            clockTimer?.invalidate()
            clockTimer = nil
        }
    }

    // MARK: - Clock hint

    private var clockHint: some View {
        let h = Calendar.current.component(.hour, from: now)
        let m = Calendar.current.component(.minute, from: now)
        let pin = String(format: "%02d%02d", h, m)

        return VStack(spacing: 6) {
            // Clock face row
            HStack(spacing: 4) {
                Text(String(format: "%02d", h))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.pgBlue)
                    .frame(width: 48)
                    .background(Color.pgBlue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(":")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.pgBlue)
                    .opacity(now.timeIntervalSince1970.truncatingRemainder(dividingBy: 2) < 1 ? 1 : 0.2)
                    .animation(.easeInOut(duration: 0.5), value: secondsLeft)

                Text(String(format: "%02d", m))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.pgBlue)
                    .frame(width: 48)
                    .background(Color.pgBlue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // PIN hint
            HStack(spacing: 6) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.pgTextTertiary)
                Text("PIN: \(pin)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.pgTextTertiary)

                // Countdown arc
                Text("· сменится через \(secondsLeft)с")
                    .font(.system(size: 11))
                    .foregroundColor(.pgTextTertiary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.pgCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pgBorder, lineWidth: 1))
        )
        .padding(.horizontal, 40)
    }

    // MARK: - Keypad

    private var keypad: some View {
        VStack(spacing: 12) {
            ForEach([[1,2,3],[4,5,6],[7,8,9]], id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(row, id: \.self) { n in
                        PinButton(label: "\(n)") { tap(String(n)) }
                    }
                }
            }
            HStack(spacing: 20) {
                Color.clear.frame(width: 72, height: 72)
                PinButton(label: "0") { tap("0") }
                PinButton(label: "⌫", isDelete: true) { delete() }
            }
        }
    }

    // MARK: - Logic

    private func tap(_ d: String) {
        guard entered.count < digits else { return }
        entered += d
        if entered.count == digits { verify() }
    }

    private func delete() {
        if !entered.isEmpty { entered.removeLast() }
        errorMsg = ""
    }

    private func verify() {
        switch mode {
        case .verify:
            if pinStore.verify(entered) {
                onSuccess()
            } else {
                triggerError("Неверный PIN · время: \(pinStore.currentPin)")
                entered = ""
            }
        case .setup:
            pinStore.hasPin = true
            onSuccess()
        }
    }

    private func triggerError(_ msg: String) {
        errorMsg = msg
        shake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
    }

    private func updateSeconds() {
        let secs = Calendar.current.component(.second, from: Date())
        secondsLeft = 60 - secs
    }
}

// MARK: - Pin Button

struct PinButton: View {
    let label: String
    var isDelete: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.pgCard)
                    .overlay(Circle().stroke(Color.pgBorder, lineWidth: 1))
                    .frame(width: 72, height: 72)
                if isDelete {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20))
                        .foregroundColor(.pgTextSecondary)
                } else {
                    Text(label)
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .foregroundColor(.pgTextPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
