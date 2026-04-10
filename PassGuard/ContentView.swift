import SwiftUI

struct ContentView: View {
    @StateObject private var store = CredentialStore()
    @StateObject private var settings = SettingsStore.shared
    @State private var selectedTab: AppTab = .vault

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.pgBackground.ignoresSafeArea()

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
        .environmentObject(store)
        .environmentObject(settings)
        .toastOverlay()
        .preferredColorScheme(.dark)
    }
}
