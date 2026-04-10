import SwiftUI

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @AppStorage("pg_biometrics")     var biometricsEnabled: Bool = true
    @AppStorage("pg_autoCopy")       var autoCopyOnOpen: Bool = false
    @AppStorage("pg_maskPasswords")  var maskPasswords: Bool = true
    @AppStorage("pg_sortOrder")      var sortOrder: String = "date"
    @AppStorage("pg_appVersion")     var appVersion: String = "1.0.0"
}
