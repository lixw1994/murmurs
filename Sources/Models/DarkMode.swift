import SwiftUI

enum DarkMode: String, CaseIterable {
    case auto
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
