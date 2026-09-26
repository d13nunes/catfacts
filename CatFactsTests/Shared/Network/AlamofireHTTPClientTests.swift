import Alamofire
import XCTest
@testable import CatFacts

final class AlamofireHTTPClientTests: XCTestCase {
    private struct Item: Decodable, Sendable, Equatable {
        let name: String
    }

    private let url = URL(string: "https://example.com/items")!
    private var client: AlamofireHTTPClient!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        client = AlamofireHTTPClient(session: Session(configuration: configuration))
    }

    override func tearDown() {
        StubURLProtocol.stub = nil
        client = nil
        super.tearDown()
    }

    func testDecodesSuccessfulJSONResponse() async throws {
        StubURLProtocol.stub = .response(status: 200, contentType: "application/json", body: #"[{"name":"Tom"}]"#)

        let items: [Item] = try await client.get(url, decoder: JSONDecoder())

        XCTAssertEqual(items, [Item(name: "Tom")])
    }

    @MainActor
    func testDecodesOffTheMainThreadWhenCalledFromTheMainActor() async throws {
        StubURLProtocol.stub = .response(status: 200, contentType: "application/json", body: "{}")

        let probe: ThreadProbe = try await client.get(url, decoder: JSONDecoder())

        XCTAssertFalse(probe.decodedOnMainThread)
    }

    func testErrorStatusMapsToBadStatus() async {
        StubURLProtocol.stub = .response(status: 503, contentType: "application/json", body: "{}")
        await assertGetThrows(.badStatus(503))
    }

    func testUnexpectedContentTypeMapsToInvalidResponse() async {
        StubURLProtocol.stub = .response(status: 200, contentType: "text/html", body: "<html></html>")
        await assertGetThrows(.invalidResponse)
    }

    func testMalformedBodyMapsToInvalidResponse() async {
        StubURLProtocol.stub = .response(status: 200, contentType: "application/json", body: "not json")
        await assertGetThrows(.invalidResponse)
    }

    func testOfflineMapsToConnection() async {
        StubURLProtocol.stub = .failure(URLError(.notConnectedToInternet))
        await assertGetThrows(.connection)
    }

    func testTimeoutMapsToConnection() async {
        StubURLProtocol.stub = .failure(URLError(.timedOut))
        await assertGetThrows(.connection)
    }

    private func assertGetThrows(
        _ expected: NetworkError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            let _: [Item] = try await client.get(url, decoder: JSONDecoder())
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? NetworkError, expected, file: file, line: line)
        }
    }
}

/// Records which thread decoding ran on.
private struct ThreadProbe: Decodable, Sendable {
    let decodedOnMainThread: Bool

    init(from decoder: Decoder) throws {
        decodedOnMainThread = pthread_main_np() != 0
    }
}

private final class StubURLProtocol: URLProtocol {
    enum Stub {
        case response(status: Int, contentType: String, body: String)
        case failure(URLError)
    }

    nonisolated(unsafe) static var stub: Stub?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        switch Self.stub {
        case let .response(status, contentType, body)?:
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: ["Content-Type": contentType]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error)?:
            client?.urlProtocol(self, didFailWithError: error)
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
        }
    }
}
