import Foundation

enum AppVersion {
    /// "Version 1.1.0 (2)", from the running bundle's Info.plist — which
    /// project.yml fills from MARKETING_VERSION / CURRENT_PROJECT_VERSION.
    static func display(info: [String: Any]? = Bundle.main.infoDictionary) -> String {
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        guard let build = info?["CFBundleVersion"] as? String, !build.isEmpty else {
            return "Version \(version)"
        }
        return "Version \(version) (\(build))"
    }
}
