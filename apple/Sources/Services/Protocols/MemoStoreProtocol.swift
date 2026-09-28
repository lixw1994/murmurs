import Foundation
import SwiftData

protocol MemoStoreProtocol {
    var context: ModelContext { get }
    func recordUsage(charsSent: Int, charsReceived: Int, whisper: Int)
}
