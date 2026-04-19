//
//  ForYouShelfProviderTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("ForYouShelfProvider")
struct ForYouShelfProviderTests {
    @Test func aggregatesAllConfiguredRequests() async throws {
        let movieRequest = CatalogRequest(type: "movie", id: "tmdb.popular")
        let seriesRequest = CatalogRequest(type: "series", id: "tmdb.top")
        let client = StubAddonClient(
            catalogResults: [
                movieRequest: .success(CatalogResponse(metas: [Meta(id: "tt1", type: "movie", name: "Movie", tmdbID: "1")])),
                seriesRequest: .success(CatalogResponse(metas: [Meta(id: "tt2", type: "series", name: "Series", tmdbID: "2")]))
            ]
        )
        let provider = ForYouShelfProvider(
            addon: .aioMetadata,
            requests: [movieRequest, seriesRequest],
            addonClient: client,
            sharedDataStore: SharedDataStore()
        )

        let shelf = try await provider.load()

        #expect(shelf.kind == .forYou)
        #expect(shelf.items.map(\.id) == ["tmdb:1", "tmdb:2"])
    }
}
