// The `Client` and its types are generated from openapi.json by the
// OpenAPIGenerator build plugin; this file adds a convenience constructor and
// the bearer-token middleware.
@_exported import OpenAPIRuntime
import Foundation
import HTTPTypes
import OpenAPIURLSession

extension Client {
    /// A client for the Murmurs API at `serverURL` (for example
    /// `https://murmurs-staging.denkit.app`), using URLSession. Pass `token` to
    /// authenticate with `Authorization: Bearer <token>`.
    public static func murmurs(serverURL: URL, token: String? = nil) -> Client {
        let middlewares: [any ClientMiddleware] = token.map { [BearerTokenMiddleware(token: $0)] } ?? []
        return Client(serverURL: serverURL, transport: URLSessionTransport(), middlewares: middlewares)
    }
}

/// Adds `Authorization: Bearer <token>` to every request.
public struct BearerTokenMiddleware: ClientMiddleware {
    private let token: String

    public init(token: String) {
        self.token = token
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.authorization] = "Bearer \(token)"
        return try await next(request, body, baseURL)
    }
}
