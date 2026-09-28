import Foundation
import SwiftData
import XLog
import CSV
import Observation

enum ExportCategory: CaseIterable {
    case note
    case summary

    static var enabledCases: [ExportCategory] {
        if Config.shared.sumEnabled {
            return [.note, .summary]
        } else {
            return [.note]
        }
    }

    var displayName: String {
        switch self {
        case .note: return L(.export_category_note)
        case .summary: return L(.export_category_summary)
        }
    }

    var fileName: String {
        switch self {
        case .note: return "Notes"
        case .summary: return "Summaries"
        }
    }
}

enum ExportFormat: CaseIterable {
    case csv
    case markdown

    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .markdown: return "Markdown"
        }
    }

    var fileExtension: String {
        switch self {
        case .csv: return ".csv"
        case .markdown: return ".md"
        }
    }
}

@MainActor @Observable final class ExportViewModel {
    private let context: ModelContext

    var category = ExportCategory.note
    var format = ExportFormat.csv

    var fileToShare: URL? {
        didSet {
            if fileToShare != nil {
                showShareSheet = true
            }
        }
    }
    var showShareSheet = false

    var lastErrorMessage = "" {
        didSet {
            showError = true
        }
    }
    var showError = false

    init(context: ModelContext) {
        self.context = context
    }

    func export() {
        do {
            if format == .csv {
                try exportAsCSV()
            } else {
                try exportAsMarkdown()
            }
        } catch {
            XLog.error(error, source: "Export")
            lastErrorMessage = ErrorHelper.desc(error)
        }
    }

    private func getExportFilePath() throws -> URL {
        let exportDirectory = URL.documentsDirectory.appending(path: "exports")
        let fs = FileManager.default
        if !fs.fileExists(atPath: exportDirectory.path()) {
            try fs.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        }
        let name = "\(category.fileName)-" + DateHelper.format(Date(), dateFormat: "yyyy-MM-dd-HH-mm-ss") + format.fileExtension
        let ret = exportDirectory.appending(path: name)
        return ret
    }

    // MARK: - CSV

    private func exportAsCSV() throws {
        let csvURL = try getExportFilePath()
        let rows = try genRows()
        let stream = OutputStream(toFileAtPath: csvURL.path(), append: false)!
        let csv = try CSVWriter(stream: stream)
        for row in rows {
            try csv.write(row: row)
        }
        csv.stream.close()
        fileToShare = csvURL
    }

    func genRows() throws -> [[String]] {
        var rows = [[String]]()
        if category == .note {
            rows.append(["time", "content"])
            let items = try fetchNotes()
            for item in items {
                rows.append([item.viewCreatedAt, item.viewContent])
            }
        } else if category == .summary {
            rows.append(["time", "title", "content"])
            let items = try fetchSummaries()
            for item in items {
                rows.append([item.viewCreatedAt, item.viewTitle, item.viewContent])
            }
        }
        return rows
    }

    // MARK: - Markdown

    private func exportAsMarkdown() throws {
        let url = try getExportFilePath()
        let content = try genMarkdownContent()
        try content.write(to: url, atomically: true, encoding: .utf8)
        fileToShare = url
    }

    func genMarkdownContent() throws -> String {
        var ret = ""
        if category == .note {
            let items = try fetchNotes()
            for item in items {
                ret.append("### \(item.viewCreatedAt)\n\n")
                ret.append("\(item.viewContent)\n\n\n")
            }
        } else if category == .summary {
            let items = try fetchSummaries()
            for item in items {
                ret.append("## Murmurs \(item.viewTitle) Summary\n\n")
                ret.append("\(item.viewContent)\n\n\n")
            }
        }
        return ret
    }

    // MARK: - Fetch

    private func fetchNotes() throws -> [MemoEntity] {
        let descriptor = FetchDescriptor<MemoEntity>(
            sortBy: [SortDescriptor(\MemoEntity.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    private func fetchSummaries() throws -> [SummaryEntity] {
        let descriptor = FetchDescriptor<SummaryEntity>(
            sortBy: [SortDescriptor(\SummaryEntity.createdAt)]
        )
        return try context.fetch(descriptor)
    }
}
