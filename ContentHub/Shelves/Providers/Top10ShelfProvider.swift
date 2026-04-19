//
//  Top10ShelfProvider.swift
//  ContentHub
//

import Foundation

nonisolated struct Top10ShelfProvider: ShelfProvider {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let priority: LoadPriority
    let limit: Int
    let addon: Addon
    let request: CatalogRequest
    let addonClient: any AddonClient
    let sharedDataStore: SharedDataStore
    let mapper: MediaMapper

    init(
        id: String = "home.top10",
        title: String = "Top 10",
        priority: LoadPriority = .high,
        limit: Int = 10,
        addon: Addon,
        request: CatalogRequest = CatalogRequest(type: "movie", id: "tmdb.trending"),
        addonClient: any AddonClient,
        sharedDataStore: SharedDataStore,
        mapper: MediaMapper = MediaMapper()
    ) {
        self.id = id
        self.title = title
        self.layout = .top10
        self.kind = .top10
        self.priority = priority
        self.limit = limit
        self.addon = addon
        self.request = request
        self.addonClient = addonClient
        self.sharedDataStore = sharedDataStore
        self.mapper = mapper
    }

    nonisolated func load() async throws -> Shelf {
        let response = try await addonClient.fetchCatalog(for: addon, request: request)
        let rankedItems = mapper.map(response.metas)
            .prefix(limit)
            .enumerated()
            .map { offset, item in
                item.with(rank: offset + 1)
            }

        let stored = await sharedDataStore.insert(Array(rankedItems))
        return Shelf(id: id, title: title, layout: layout, kind: kind, items: stored)
    }
}
