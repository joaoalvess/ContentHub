//
//  WatchProgressStore.swift
//  ContentHub
//
//  Actor wrapper around SwiftData access for persisted watch state.
//

import Foundation
import SwiftData

nonisolated struct WatchProgressEntry: Sendable, Equatable {
    let mediaID: String
    let progress: Double
    let updatedAt: Date
}

actor WatchProgressStore {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func recordProgress(
        mediaID: String,
        progress: Double,
        updatedAt: Date = .now
    ) throws {
        let context = ModelContext(container)
        let clampedProgress = min(max(progress, 0), 1)

        let targetID = mediaID
        var descriptor = FetchDescriptor<WatchProgress>(
            predicate: #Predicate { item in
                item.mediaID == targetID
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.progress = clampedProgress
            existing.updatedAt = updatedAt
        } else {
            context.insert(
                WatchProgress(
                    mediaID: mediaID,
                    progress: clampedProgress,
                    updatedAt: updatedAt
                )
            )
        }

        try context.save()
    }

    func recent(limit: Int) throws -> [WatchProgressEntry] {
        try fetchEntries(limit: limit)
    }

    func inProgress(limit: Int? = nil) throws -> [WatchProgressEntry] {
        let entries = try fetchEntries(limit: limit)
        return entries.filter { (0.01..<0.95).contains($0.progress) }
    }

    private func fetchEntries(limit: Int?) throws -> [WatchProgressEntry] {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<WatchProgress>(
            sortBy: [SortDescriptor(\WatchProgress.updatedAt, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }

        return try context.fetch(descriptor).map {
            WatchProgressEntry(
                mediaID: $0.mediaID,
                progress: $0.progress,
                updatedAt: $0.updatedAt
            )
        }
    }
}
