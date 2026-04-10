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
    private let digits = 4

    var body: some View {
        ZStack {
            Color.pgBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle().fill(Color.pgBlue.opacity(0.12)).frame(width: 80, height: 80)
                    Circle().fill(Color.pgBlue.opacity(0.07)).frame(width: 100, height: 100)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.pgBlue)
                }
                .padding(.bottom, 24)

                VStack(spacing: 6) {
                    Text("Введите PIN-код")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.pgTextPrimary)
                    if !errorMsg.isEmpty {
                        Text(errorMsg)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.pgRed)
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 32)

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
