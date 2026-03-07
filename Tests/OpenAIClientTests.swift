import XCTest
@testable import Murmurs

final class OpenAIClientTests: XCTestCase {
    let client = OpenAIClient.shared

    // MARK: - parseChunk()

    func testParseChunk_WithValidData_ReturnsContent() {
        let line = #"data: {"choices":[{"delta":{"content":"Hello"}}]}"#
        XCTAssertEqual(client.parseChunk(line), "Hello")
    }

    func testParseChunk_WithDone_ReturnsNewline() {
        XCTAssertEqual(client.parseChunk("data: [DONE]"), "\n")
    }

    func testParseChunk_WithNonDataPrefix_ReturnsNil() {
        XCTAssertNil(client.parseChunk("event: message"))
    }

    func testParseChunk_WithEmptyLine_ReturnsNil() {
        XCTAssertNil(client.parseChunk(""))
    }

    func testParseChunk_WithMalformedJSON_ReturnsNil() {
        XCTAssertNil(client.parseChunk("data: {invalid json}"))
    }

    func testParseChunk_WithEmptyDelta_ReturnsNil() {
        let line = #"data: {"choices":[{"delta":{}}]}"#
        XCTAssertNil(client.parseChunk(line))
    }

    func testParseChunk_WithRoleDelta_ReturnsNil() {
        let line = #"data: {"choices":[{"delta":{"role":"assistant"}}]}"#
        XCTAssertNil(client.parseChunk(line))
    }

    // MARK: - decodeResponse()

    func testDecodeResponse_With200_DecodesSuccessfully() throws {
        let json = #"{"text":"Hello world"}"#
        let data = json.data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!

        let result: OpenAIResponse.Transcription = try client.decodeResponse(
            data: data, response: response, type: OpenAIResponse.Transcription.self)
        XCTAssertEqual(result.text, "Hello world")
    }

    func testDecodeResponse_WithNon200AndAPIError_ThrowsAPIError() {
        let json = #"{"error":{"message":"Invalid API key","code":"invalid_api_key"}}"#
        let data = json.data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com")!,
                                       statusCode: 401, httpVersion: nil, headerFields: nil)!

        XCTAssertThrowsError(
            try client.decodeResponse(data: data, response: response,
                                      type: OpenAIResponse.Transcription.self)
        ) { error in
            guard case OpenAIError.apiError(let code, let res) = error else {
                XCTFail("Expected apiError, got \(error)")
                return
            }
            XCTAssertEqual(code, 401)
            XCTAssertEqual(res.error.message, "Invalid API key")
        }
    }

    func testDecodeResponse_WithNon200AndBadBody_ThrowsBadResponse() {
        let data = "not json".data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com")!,
                                       statusCode: 500, httpVersion: nil, headerFields: nil)!

        XCTAssertThrowsError(
            try client.decodeResponse(data: data, response: response,
                                      type: OpenAIResponse.Transcription.self)
        ) { error in
            guard case OpenAIError.badResponse = error else {
                XCTFail("Expected badResponse, got \(error)")
                return
            }
        }
    }

    func testDecodeResponse_With200AndBadJSON_ThrowsDecodingError() {
        let data = "not json".data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://api.example.com")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!

        XCTAssertThrowsError(
            try client.decodeResponse(data: data, response: response,
                                      type: OpenAIResponse.Transcription.self)
        ) { error in
            guard case OpenAIError.decoding = error else {
                XCTFail("Expected decoding error, got \(error)")
                return
            }
        }
    }

    func testDecodeResponse_WithNonHTTPResponse_ThrowsBadResponse() {
        let data = Data()
        let response = URLResponse(url: URL(string: "https://api.example.com")!,
                                   mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

        XCTAssertThrowsError(
            try client.decodeResponse(data: data, response: response,
                                      type: OpenAIResponse.Transcription.self)
        ) { error in
            guard case OpenAIError.badResponse = error else {
                XCTFail("Expected badResponse, got \(error)")
                return
            }
        }
    }
}
