//
//  ForYouShelfProvider.swift
//  ContentHub
//

import Foundation

nonisolated struct ForYouShelfProvider: ShelfProvider {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let priority: LoadPriority
    let addon: Addon
    let requests: [CatalogRequest]
    let addonClient: any AddonClient
    let sharedDataStore: SharedDataStore
    let mapper: MediaMapper

    init(
        id: String = "home.for-you",
        title: String = "Para Você",
        priority: LoadPriority = .normal,
        addon: Addon,
        requests: [CatalogRequest],
        addonClient: any AddonClient,
        sharedDataStore: SharedDataStore,
        mapper: MediaMapper = MediaMapper()
    ) {
        self.id = id
        self.title = title
        self.layout = .poster
        self.kind = .forYou
        self.priority = priority
        self.addon = addon
        self.requests = requests
        self.addonClient = addonClient
        self.sharedDataStore = sharedDataStore
        self.mapper = mapper
    }

    nonisolated func load() async throws -> Shelf {
        var items: [MediaItem] = []

        for request in requests {
            let response = try await addonClient.fetchCatalog(for: addon, request: request)
            items.append(contentsOf: mapper.map(response.metas))
        }

        let stored = await sharedDataStore.insert(items)
        return Shelf(id: id, title: title, layout: layout, kind: kind, items: stored)
    }
}
