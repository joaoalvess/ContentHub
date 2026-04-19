//
//  HTTPAddonClientTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("HTTPAddonClient")
struct HTTPAddonClientTests {
    @Test func fetchManifestDecodesJSON() async throws {
        let session = StubURLProtocol.makeSession { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = try Fixtures.data(named: "manifest")
            return (response, data)
        }

        let client = HTTPAddonClient(session: session)
        let manifest = try await client.fetchManifest(for: .aioMetadata)

        #expect(manifest.id == "aio-metadata")
        #expect(manifest.catalogs.count == 53)
    }

    @Test func fetchCatalogDecodesResponse() async throws {
        let session = StubURLProtocol.makeSession { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = try Fixtures.data(named: "catalog_trending_movie")
            return (response, data)
        }

        let client = HTTPAddonClient(session: session)
        let response = try await client.fetchCatalog(
            for: .aioMetadata,
            request: CatalogRequest(type: "movie", id: "tmdb.trending")
        )

        #expect(response.metas.count == 20)
        #expect(response.metas.first?.name == "Vingança Brutal")
    }

    @Test func fetchCatalogMapsHTTPStatusErrors() async {
        let session = StubURLProtocol.makeSession { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let client = HTTPAddonClient(session: session)

        await #expect(throws: StremioError.httpStatus(503)) {
            try await client.fetchCatalog(
                for: .aioMetadata,
                request: CatalogRequest(type: "movie", id: "tmdb.trending")
            )
        }
    }
}
