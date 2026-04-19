//
//  RecentlyWatchedShelfProviderTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("RecentlyWatchedShelfProvider")
struct RecentlyWatchedShelfProviderTests {
    @Test func returnsMostRecentItemsInOrder() async throws {
        let container = try InMemoryModelContainer.make()
        let progressStore = WatchProgressStore(container: container)
        let sharedStore = SharedDataStore()

        try await progressStore.recordProgress(mediaID: "tmdb:1", progress: 0.2, updatedAt: Date(timeIntervalSince1970: 100))
        try await progressStore.recordProgress(mediaID: "tmdb:2", progress: 0.3, updatedAt: Date(timeIntervalSince1970: 300))
        _ = await sharedStore.insert([
            MediaItem(id: "tmdb:1", kind: .movie, title: "One", description: nil, posterURL: nil, landscapeURL: nil, logoURL: nil, genres: [], year: nil, runtime: nil, rating: nil, releaseDate: nil, rank: nil, progress: nil),
            MediaItem(id: "tmdb:2", kind: .movie, title: "Two", description: nil, posterURL: nil, landscapeURL: nil, logoURL: nil, genres: [], year: nil, runtime: nil, rating: nil, releaseDate: nil, rank: nil, progress: nil)
        ])

        let provider = RecentlyWatchedShelfProvider(
            watchProgressStore: progressStore,
            sharedDataStore: sharedStore
        )

        let shelf = try await provider.load()

        #expect(shelf.items.map(\.id) == ["tmdb:2", "tmdb:1"])
    }
}
