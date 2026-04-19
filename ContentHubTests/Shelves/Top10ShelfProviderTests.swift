//
//  Top10ShelfProviderTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("Top10ShelfProvider")
struct Top10ShelfProviderTests {
    @Test func limitsToTenAndAnnotatesRanks() async throws {
        let metas = (1...12).map { index in
            Meta(id: "tt\(index)", type: "movie", name: "Movie \(index)", tmdbID: "\(index)")
        }
        let request = CatalogRequest(type: "movie", id: "tmdb.trending")
        let client = StubAddonClient(catalogResults: [request: .success(CatalogResponse(metas: metas))])
        let store = SharedDataStore()
        let provider = Top10ShelfProvider(
            addon: .aioMetadata,
            request: request,
            addonClient: client,
            sharedDataStore: store
        )

        let shelf = try await provider.load()

        #expect(shelf.layout == .top10)
        #expect(shelf.items.count == 10)
        #expect(shelf.items.first?.rank == 1)
        #expect(shelf.items.last?.rank == 10)
    }
}
