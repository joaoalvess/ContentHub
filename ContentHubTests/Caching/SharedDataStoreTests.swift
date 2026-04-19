//
//  SharedDataStoreTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("SharedDataStore")
struct SharedDataStoreTests {
    @Test func insertDeduplicatesByID() async {
        let store = SharedDataStore()
        let item = MediaItem(
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

        _ = await store.insert(item)
        _ = await store.insert(item)

        let snapshot = await store.snapshot()
        #expect(snapshot.count == 1)
    }

    @Test func mergePreservesNewestRankAndProgress() async {
        let store = SharedDataStore()
        let base = MediaItem(
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
            rank: 1,
            progress: nil
        )
        let newer = MediaItem(
            id: "tmdb:1",
            kind: .movie,
            title: "One Updated",
            description: nil,
            posterURL: nil,
            landscapeURL: nil,
            logoURL: nil,
            genres: [],
            year: nil,
            runtime: nil,
            rating: nil,
            releaseDate: nil,
            rank: 2,
            progress: 0.6
        )

        _ = await store.insert(base)
        let merged = await store.insert(newer)

        #expect(merged.title == "One Updated")
        #expect(merged.rank == 2)
        #expect(merged.progress == 0.6)
    }
}
