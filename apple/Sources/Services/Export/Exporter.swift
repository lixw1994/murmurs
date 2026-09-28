import Foundation
import SwiftData
import XLog

class Exporter {

    enum Format {
        case markdown
    }

    static func exportMemos(_ dayId: Int, context: ModelContext, format: Format = .markdown) -> String {
        let dayId32 = Int32(dayId)
        let descriptor = FetchDescriptor<MemoEntity>(
            predicate: #Predicate { $0.day == dayId32 },
            sortBy: [SortDescriptor(\MemoEntity.createdAt)]
        )

        var ret = "# \(DateHelper.formatIdentifier(dayId))\n\n"
        do {
            let memos = try context.fetch(descriptor).filter { !$0.displayContent.isEmpty }
            for memo in memos {
                ret.append("## \(memo.viewTime)\n\n")
                ret.append(memo.displayContent)
                ret.append("\n\n")
            }
        } catch {
            XLog.error(error, source: "Export")
        }
        return ret
    }
}
