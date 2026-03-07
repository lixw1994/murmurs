import Foundation
import XLang

func L(_ key: MyLocalizedKey) -> String {
    return NSLocalizedString(key.rawValue, bundle: Bundle.current, comment: "")
}

func L(_ key: MyLocalizedKey, _ arguments: CVarArg...) -> String {
    return String(format: L(key), arguments)
}

extension Language {
    static var supported: [Language] {
        return [.en, .zh_hans]
    }
}
