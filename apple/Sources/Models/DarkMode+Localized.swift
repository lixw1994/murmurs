import Foundation

extension DarkMode {
    var displayName: String {
        switch self {
        case .auto: return L(.dark_mode_auto)
        case .light: return L(.dark_mode_light)
        case .dark: return L(.dark_mode_dark)
        }
    }
}
