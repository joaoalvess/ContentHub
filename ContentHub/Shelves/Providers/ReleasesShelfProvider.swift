//
//  ReleasesShelfProvider.swift
//  ContentHub
//

import Foundation

nonisolated struct ReleasesShelfProvider: ShelfProvider {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let priority: LoadPriority
    let monthsBack: Int
    let now: @Sendable () -> Date
    let addon: Addon
    let request: CatalogRequest
    let addonClient: any AddonClient
    let sharedDataStore: SharedDataStore
    let mapper: MediaMapper

    init(
        id: String = "home.releases",
        title: String = "Lançamentos",
        priority: LoadPriority = .normal,
        monthsBack: Int = 6,
        now: @escaping @Sendable () -> Date = { .now },
        addon: Addon,
        request: CatalogRequest,
        addonClient: any AddonClient,
        sharedDataStore: SharedDataStore,
        mapper: MediaMapper = MediaMapper()
    ) {
        self.id = id
        self.title = title
        self.layout = .landscape
        self.kind = .releases
        self.priority = priority
        self.monthsBack = monthsBack
        self.now = now
        self.addon = addon
        self.request = request
        self.addonClient = addonClient
        self.sharedDataStore = sharedDataStore
        self.mapper = mapper
    }

    nonisolated func load() async throws -> Shelf {
        let response = try await addonClient.fetchCatalog(for: addon, request: request)
        let cutoff = Calendar.current.date(byAdding: .month, value: -monthsBack, to: now()) ?? .distantPast

        let filtered = mapper.map(response.metas)
            .filter { item in
                guard let releaseDate = item.releaseDate else { return false }
                return releaseDate >= cutoff
            }
            .sorted { lhs, rhs in
                (lhs.releaseDate ?? .distantPast) > (rhs.releaseDate ?? .distantPast)
            }

        let stored = await sharedDataStore.insert(filtered)
        return Shelf(id: id, title: title, layout: layout, kind: kind, items: stored)
    }
}
