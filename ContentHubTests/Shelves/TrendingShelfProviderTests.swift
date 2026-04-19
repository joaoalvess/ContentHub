//
//  TrendingShelfProviderTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("TrendingShelfProvider")
struct TrendingShelfProviderTests {
    @Test func mapsCatalogIntoPosterShelf() async throws {
        let response = CatalogResponse(
            metas: [
                Meta(id: "tt1", type: "movie", name: "One", tmdbID: "1"),
                Meta(id: "tt2", type: "movie", name: "Two", tmdbID: "2")
            ]
        )
        let request = CatalogRequest(type: "movie", id: "tmdb.trending")
        let client = StubAddonClient(catalogResults: [request: .success(response)])
        let store = SharedDataStore()
        let provider = TrendingShelfProvider(
            addon: .aioMetadata,
            request: request,
            addonClient: client,
            sharedDataStore: store
        )

        let shelf = try await provider.load()

        #expect(shelf.layout == .poster)
        #expect(shelf.items.count == 2)
        #expect(shelf.items.map(\.id) == ["tmdb:1", "tmdb:2"])
        #expect(await store.item(for: "tmdb:1") != nil)
    }
}
