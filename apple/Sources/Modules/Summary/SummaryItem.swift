import Foundation

enum SummaryItem: Identifiable {
    case day(Int)
    
    var id: String {
        switch self {
        case .day(let n):
            return String(n)
        }
    }
}
