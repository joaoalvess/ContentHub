//
//  SharedDataStore.swift
//  ContentHub
//
//  Deduplicates MediaItems across providers and tabs.
//

import Foundation

actor SharedDataStore {
    private var itemsByID: [String: MediaItem] = [:]

    func insert(_ item: MediaItem) -> MediaItem {
        let merged = itemsByID[item.id]?.merged(with: item) ?? item
        itemsByID[item.id] = merged
        return merged
    }

    func insert(_ items: [MediaItem]) -> [MediaItem] {
        items.map { insert($0) }
    }

    func item(for id: String) -> MediaItem? {
        itemsByID[id]
    }

    func items(for ids: [String]) -> [MediaItem] {
        ids.compactMap { itemsByID[$0] }
    }

    func snapshot() -> [String: MediaItem] {
        itemsByID
    }
}
