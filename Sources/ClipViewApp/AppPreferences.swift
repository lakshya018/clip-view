import Foundation

final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    private let defaults: UserDefaults
    private let historyLimitKey = "app_preferences_history_limit"

    @Published var historyLimit: Int {
        didSet { defaults.set(historyLimit, forKey: historyLimitKey) }
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.historyLimit = defaults.object(forKey: historyLimitKey) as? Int ?? 20
    }
}
