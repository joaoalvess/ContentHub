//
//  ContinueWatchingShelfProviderTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("ContinueWatchingShelfProvider")
struct ContinueWatchingShelfProviderTests {
    @Test func joinsProgressWithSharedMediaItems() async throws {
        let container = try InMemoryModelContainer.make()
        let progressStore = WatchProgressStore(container: container)
        let sharedStore = SharedDataStore()

        try await progressStore.recordProgress(mediaID: "tmdb:1", progress: 0.5, updatedAt: Date(timeIntervalSince1970: 100))
        try await progressStore.recordProgress(mediaID: "tmdb:2", progress: 1.0, updatedAt: Date(timeIntervalSince1970: 200))
        _ = await sharedStore.insert(
            MediaItem(
                id: "tmdb:1",
                kind: .movie,
                title: "One",
                description: nil,
                posterURL: nil,
                landscapeURL: nil,
                logoURL: nil,
                genres: [],
                year: nil,
                runtime: nil,
                rating: nil,
                releaseDate: nil,
                rank: nil,
                progress: nil
            )
        )

        let provider = ContinueWatchingShelfProvider(
            watchProgressStore: progressStore,
            sharedDataStore: sharedStore
        )

        let shelf = try await provider.load()

        #expect(shelf.items.map(\.id) == ["tmdb:1"])
        #expect(shelf.items.first?.progress == 0.5)
    }
}
