//
//  StreamingServicesShelfProvider.swift
//  ContentHub
//

import Foundation

nonisolated struct StreamingServicesShelfProvider: ShelfProvider {
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
        id: String = "home.streaming-services",
        title: String = "Serviços de Streaming",
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
        self.kind = .streamingServices
        self.priority = priority
        self.addon = addon
        self.requests = requests
        self.addonClient = addonClient
        self.sharedDataStore = sharedDataStore
        self.mapper = mapper
    }

    nonisolated func load() async throws -> Shelf {
        var aggregated: [MediaItem] = []
        var firstError: Error?

        for request in requests {
            do {
                let response = try await addonClient.fetchCatalog(for: addon, request: request)
                aggregated.append(contentsOf: mapper.map(response.metas))
            } catch {
                firstError = firstError ?? error
            }
        }

        if aggregated.isEmpty, let firstError {
            throw firstError
        }

        let stored = await sharedDataStore.insert(aggregated)
        return Shelf(
            id: id,
            title: title,
            layout: layout,
            kind: kind,
            items: stored,
            isPartial: firstError != nil
        )
    }
}
