//
//  GenreExplorerShelfProviderTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("GenreExplorerShelfProvider")
struct GenreExplorerShelfProviderTests {
    @Test func loadsOneItemPerGenreRequest() async throws {
        let action = CatalogRequest(type: "movie", id: "tmdb.top", genre: "Action")
        let comedy = CatalogRequest(type: "movie", id: "tmdb.top", genre: "Comedy")
        let client = StubAddonClient(
            catalogResults: [
                action: .success(CatalogResponse(metas: [Meta(id: "tt1", type: "movie", name: "Action", tmdbID: "1")])),
                comedy: .success(CatalogResponse(metas: [Meta(id: "tt2", type: "movie", name: "Comedy", tmdbID: "2")]))
            ]
        )
        let provider = GenreExplorerShelfProvider(
            addon: .aioMetadata,
            type: "movie",
            genres: ["Action", "Comedy"],
            addonClient: client,
            sharedDataStore: SharedDataStore()
        )

        let shelf = try await provider.load()

        #expect(shelf.items.count == 2)
        #expect(shelf.items.map(\.id) == ["tmdb:1", "tmdb:2"])
    }
}
