import Foundation
import XLog

enum ReadwiseError: LocalizedError {
    case noToken
    case badResponse(String)
    case apiError(Int, String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noToken: return "Readwise token not configured"
        case .badResponse(let msg): return "Bad Response: \(msg)"
        case .apiError(let code, let msg): return "\(code): \(msg)"
        case .unknown(let err): return err.localizedDescription
        }
    }
}

protocol ReadwiseClientProtocol {
    func save(memo: MemoEntity) async throws -> String
    func save(summary: SummaryEntity) async throws -> String
    func delete(documentId: String) async throws
    func verify(token: String) async throws
}

class ReadwiseClient: ReadwiseClientProtocol {
    static let shared = ReadwiseClient()

    private let TAG = "Readwise"
    private let baseURL = URL(string: "https://readwise.io/api/v3")!

    private var token: String? {
        let t = Config.shared.readwiseToken
        return t.isEmpty ? nil : t
    }

    @discardableResult
    func save(memo: MemoEntity) async throws -> String {
        if let oldId = memo.readwiseId {
            try? await delete(documentId: oldId)
        }

        let documentId = try await postSave(params: [
            "url": "https://murmurs.flybullet.net/memos/\(memo.entityId)",
            "html": memo.displayContent,
            "title": "Murmurs \(memo.viewCreatedAt)",
            "category": "note",
            "location": "new",
            "tags": ["voice-memo"],
            "published_date": ISO8601DateFormatter().string(from: memo.createdAt ?? Date())
        ])

        XLog.info("Synced memo \(memo.entityId) → \(documentId)", source: TAG)
        return documentId
    }

    @discardableResult
    func save(summary: SummaryEntity) async throws -> String {
        guard let entityId = summary.entityId else { throw ReadwiseError.badResponse("No entity ID") }

        if let oldId = summary.readwiseId {
            try? await delete(documentId: oldId)
        }

        let documentId = try await postSave(params: [
            "url": "https://murmurs.flybullet.net/summaries/\(entityId)",
            "html": summary.viewContent,
            "title": summary.viewTitle,
            "category": "note",
            "location": "new",
            "tags": ["voice-memo", "summary"],
            "published_date": ISO8601DateFormatter().string(from: summary.createdAt ?? Date())
        ])

        XLog.info("Synced summary \(entityId) → \(documentId)", source: TAG)
        return documentId
    }

    func delete(documentId: String) async throws {
        guard let token else { throw ReadwiseError.noToken }

        let url = baseURL.appending(path: "delete/\(documentId)/")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")

        XLog.debug("DELETE \(url)", source: TAG)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReadwiseError.badResponse("")
        }

        if httpResponse.statusCode != 204 && httpResponse.statusCode != 404 {
            throw ReadwiseError.apiError(httpResponse.statusCode, "Delete failed")
        }
    }

    func verify(token: String) async throws {
        let url = URL(string: "https://readwise.io/api/v2/auth/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReadwiseError.badResponse("")
        }

        if httpResponse.statusCode == 401 {
            throw ReadwiseError.apiError(401, "Invalid token")
        }

        if httpResponse.statusCode != 204 {
            throw ReadwiseError.badResponse("Status: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Private

    private func postSave(params: [String: Any]) async throws -> String {
        guard let token else { throw ReadwiseError.noToken }

        let url = baseURL.appending(path: "save/")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.user_agent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: params)

        XLog.debug("POST \(url)", source: TAG)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReadwiseError.badResponse("")
        }

        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            let body = String(data: data, encoding: .utf8) ?? ""
            XLog.error("Readwise API error: \(httpResponse.statusCode) \(body)", source: TAG)
            throw ReadwiseError.apiError(httpResponse.statusCode, body)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let id = json["id"] as? String {
                return id
            }
            if let id = json["id"] as? Int {
                return String(id)
            }
        }

        let body = String(data: data, encoding: .utf8) ?? ""
        XLog.error("Missing document ID in response: \(body)", source: TAG)
        throw ReadwiseError.badResponse("Missing document ID in response")
    }
}
