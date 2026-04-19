//
//  WatchProgressStoreTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("WatchProgressStore")
struct WatchProgressStoreTests {
    @Test func recordProgressUpdatesExistingRows() async throws {
        let container = try InMemoryModelContainer.make()
        let store = WatchProgressStore(container: container)
        let firstDate = Date(timeIntervalSince1970: 100)
        let secondDate = Date(timeIntervalSince1970: 200)

        try await store.recordProgress(mediaID: "tmdb:1", progress: 0.2, updatedAt: firstDate)
        try await store.recordProgress(mediaID: "tmdb:1", progress: 0.8, updatedAt: secondDate)

        let recent = try await store.recent(limit: 10)
        #expect(recent.count == 1)
        #expect(recent.first?.progress == 0.8)
        #expect(recent.first?.updatedAt == secondDate)
    }

    @Test func recentOrdersByUpdatedAtDescending() async throws {
        let container = try InMemoryModelContainer.make()
        let store = WatchProgressStore(container: container)

        try await store.recordProgress(mediaID: "tmdb:1", progress: 0.2, updatedAt: Date(timeIntervalSince1970: 100))
        try await store.recordProgress(mediaID: "tmdb:2", progress: 0.5, updatedAt: Date(timeIntervalSince1970: 300))
        try await store.recordProgress(mediaID: "tmdb:3", progress: 1.0, updatedAt: Date(timeIntervalSince1970: 200))

        let recent = try await store.recent(limit: 10)
        #expect(recent.map(\.mediaID) == ["tmdb:2", "tmdb:3", "tmdb:1"])
    }

    @Test func inProgressFiltersFinishedAndZeroEntries() async throws {
        let container = try InMemoryModelContainer.make()
        let store = WatchProgressStore(container: container)

        try await store.recordProgress(mediaID: "tmdb:1", progress: 0.0)
        try await store.recordProgress(mediaID: "tmdb:2", progress: 0.4)
        try await store.recordProgress(mediaID: "tmdb:3", progress: 1.0)

        let entries = try await store.inProgress(limit: 10)
        #expect(entries.map(\.mediaID) == ["tmdb:2"])
    }
}
