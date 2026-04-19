//
//  ContinueWatchingShelfProvider.swift
//  ContentHub
//

import Foundation

nonisolated struct ContinueWatchingShelfProvider: ShelfProvider {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let priority: LoadPriority
    let limit: Int
    let allowedKinds: Set<MediaKind>?
    let watchProgressStore: WatchProgressStore
    let sharedDataStore: SharedDataStore

    init(
        id: String = "home.continue-watching",
        title: String = "Continuar Assistindo",
        priority: LoadPriority = .critical,
        limit: Int = 20,
        allowedKinds: Set<MediaKind>? = nil,
        watchProgressStore: WatchProgressStore,
        sharedDataStore: SharedDataStore
    ) {
        self.id = id
        self.title = title
        self.layout = .continueWatching
        self.kind = .continueWatching
        self.priority = priority
        self.limit = limit
        self.allowedKinds = allowedKinds
        self.watchProgressStore = watchProgressStore
        self.sharedDataStore = sharedDataStore
    }

    nonisolated func load() async throws -> Shelf {
        let entries = try await watchProgressStore.inProgress(limit: limit)
        let itemsByID = Dictionary(
            uniqueKeysWithValues: await sharedDataStore
                .items(for: entries.map(\.mediaID))
                .map { ($0.id, $0) }
        )

        let resolved = entries.compactMap { entry -> MediaItem? in
            guard let baseItem = itemsByID[entry.mediaID] else { return nil }
            let progressedItem = baseItem.with(progress: entry.progress)

            if let allowedKinds, !allowedKinds.contains(progressedItem.kind) {
                return nil
            }

            return progressedItem
        }

        let stored = await sharedDataStore.insert(resolved)
        return Shelf(id: id, title: title, layout: layout, kind: kind, items: stored)
    }
}
