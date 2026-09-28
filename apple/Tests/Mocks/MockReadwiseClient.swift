@testable import Murmurs

class MockReadwiseClient: ReadwiseClientProtocol {
    var saveResult: Result<String, Error> = .success("mock-document-id")
    var saveCalled = false
    var saveCallCount = 0
    var lastSavedMemo: MemoEntity?

    @discardableResult
    func save(memo: MemoEntity) async throws -> String {
        saveCalled = true
        saveCallCount += 1
        lastSavedMemo = memo
        return try saveResult.get()
    }

    var saveSummaryResult: Result<String, Error> = .success("mock-summary-id")
    var saveSummaryCalled = false
    var lastSavedSummary: SummaryEntity?

    @discardableResult
    func save(summary: SummaryEntity) async throws -> String {
        saveSummaryCalled = true
        lastSavedSummary = summary
        return try saveSummaryResult.get()
    }

    var deleteCalled = false
    var lastDeletedDocumentId: String?

    func delete(documentId: String) async throws {
        deleteCalled = true
        lastDeletedDocumentId = documentId
    }

    var verifyResult: Result<Void, Error> = .success(())
    var verifyCalled = false

    func verify(token: String) async throws {
        verifyCalled = true
        try verifyResult.get()
    }
}
