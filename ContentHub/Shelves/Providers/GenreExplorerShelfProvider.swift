//
//  GenreExplorerShelfProvider.swift
//  ContentHub
//

import Foundation

nonisolated struct GenreExplorerShelfProvider: ShelfProvider {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let priority: LoadPriority
    let addon: Addon
    let type: String
    let catalogID: String
    let genres: [String]
    let limitPerGenre: Int
    let addonClient: any AddonClient
    let sharedDataStore: SharedDataStore
    let mapper: MediaMapper

    init(
        id: String = "home.genre-explorer",
        title: String = "Explore por Gênero",
        priority: LoadPriority = .low,
        addon: Addon,
        type: String,
        catalogID: String = "tmdb.top",
        genres: [String],
        limitPerGenre: Int = 1,
        addonClient: any AddonClient,
        sharedDataStore: SharedDataStore,
        mapper: MediaMapper = MediaMapper()
    ) {
        self.id = id
        self.title = title
        self.layout = .poster
        self.kind = .genreExplorer
        self.priority = priority
        self.addon = addon
        self.type = type
        self.catalogID = catalogID
        self.genres = genres
        self.limitPerGenre = limitPerGenre
        self.addonClient = addonClient
        self.sharedDataStore = sharedDataStore
        self.mapper = mapper
    }

    nonisolated func load() async throws -> Shelf {
        var items: [MediaItem] = []
        var firstError: Error?

        for genre in genres {
            do {
                let response = try await addonClient.fetchCatalog(
                    for: addon,
                    request: CatalogRequest(type: type, id: catalogID, genre: genre)
                )
                items.append(contentsOf: mapper.map(response.metas).prefix(limitPerGenre))
            } catch {
                firstError = firstError ?? error
            }
        }

        if items.isEmpty, let firstError {
            throw firstError
        }

        let stored = await sharedDataStore.insert(items)
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
