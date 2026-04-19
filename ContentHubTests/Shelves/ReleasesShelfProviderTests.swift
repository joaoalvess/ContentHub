//
//  ReleasesShelfProviderTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("ReleasesShelfProvider")
struct ReleasesShelfProviderTests {
    @Test func filtersOnlyRecentReleases() async throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let recent = ISO8601DateFormatter().date(from: "2026-01-10T00:00:00Z")
        let old = ISO8601DateFormatter().date(from: "2024-01-10T00:00:00Z")
        let request = CatalogRequest(type: "movie", id: "tmdb.trending")
        let client = StubAddonClient(
            catalogResults: [
                request: .success(
                    CatalogResponse(
                        metas: [
                            Meta(id: "tt1", type: "movie", name: "Recent", released: recent, tmdbID: "1"),
                            Meta(id: "tt2", type: "movie", name: "Old", released: old, tmdbID: "2")
                        ]
                    )
                )
            ]
        )
        let provider = ReleasesShelfProvider(
            monthsBack: 24,
            now: { now },
            addon: .aioMetadata,
            request: request,
            addonClient: client,
            sharedDataStore: SharedDataStore()
        )

        let shelf = try await provider.load()

        #expect(shelf.layout == .landscape)
        #expect(shelf.items.map(\.id) == ["tmdb:1"])
    }
}
