import Foundation

/// Client-side mirror of the server's recovery code rules: 25 Crockford base32
/// characters, case-insensitive, spaces and hyphens ignored, O→0 and I/L→1.
enum RecoveryCodeFormat {
    private static let alphabet = Set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    /// The display form (`XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`), or nil if `input` is not a code.
    static func normalized(_ input: String) -> String? {
        let chars = input.uppercased()
            .filter { !$0.isWhitespace && $0 != "-" }
            .map { char -> Character in
                switch char {
                case "O": return "0"
                case "I", "L": return "1"
                default: return char
                }
            }
        guard chars.count == 25, chars.allSatisfy(alphabet.contains) else { return nil }
        return stride(from: 0, to: 25, by: 5)
            .map { String(chars[$0..<$0 + 5]) }
            .joined(separator: "-")
    }
}
