//
//  TrendingShelfProvider.swift
//  ContentHub
//

import Foundation

nonisolated struct TrendingShelfProvider: ShelfProvider {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let priority: LoadPriority
    let addon: Addon
    let request: CatalogRequest
    let addonClient: any AddonClient
    let sharedDataStore: SharedDataStore
    let mapper: MediaMapper

    init(
        id: String = "home.trending",
        title: String = "Em Alta",
        priority: LoadPriority = .high,
        addon: Addon,
        request: CatalogRequest = CatalogRequest(type: "movie", id: "tmdb.trending"),
        addonClient: any AddonClient,
        sharedDataStore: SharedDataStore,
        mapper: MediaMapper = MediaMapper()
    ) {
        self.id = id
        self.title = title
        self.layout = .poster
        self.kind = .trending
        self.priority = priority
        self.addon = addon
        self.request = request
        self.addonClient = addonClient
        self.sharedDataStore = sharedDataStore
        self.mapper = mapper
    }

    nonisolated func load() async throws -> Shelf {
        let response = try await addonClient.fetchCatalog(for: addon, request: request)
        let items = mapper.map(response.metas)
        let stored = await sharedDataStore.insert(items)
        return Shelf(id: id, title: title, layout: layout, kind: kind, items: stored)
    }
}
