//
//  HomePageBlueprint.swift
//  ContentHub
//

import Foundation

enum HomePageBlueprint {
    static func build(
        addon: Addon,
        client: any AddonClient,
        sharedDataStore: SharedDataStore,
        watchProgressStore: WatchProgressStore
    ) -> PageBlueprint {
        PageBlueprint(
            id: "home",
            title: "Início",
            heroSource: .shelf(id: "home.trending"),
            providers: [
                ContinueWatchingShelfProvider(
                    watchProgressStore: watchProgressStore,
                    sharedDataStore: sharedDataStore
                ),
                TrendingShelfProvider(
                    addon: addon,
                    request: CatalogRequest(type: "movie", id: "tmdb.trending"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                Top10ShelfProvider(
                    addon: addon,
                    request: CatalogRequest(type: "movie", id: "tmdb.trending"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                ReleasesShelfProvider(
                    addon: addon,
                    request: CatalogRequest(type: "movie", id: "tmdb.trending"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                StreamingServicesShelfProvider(
                    addon: addon,
                    requests: [
                        CatalogRequest(type: "movie", id: "streaming.nfx"),
                        CatalogRequest(type: "movie", id: "streaming.hbm"),
                        CatalogRequest(type: "series", id: "streaming.dnp")
                    ],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                ForYouShelfProvider(
                    addon: addon,
                    requests: [
                        CatalogRequest(type: "movie", id: "tmdb.popular"),
                        CatalogRequest(type: "series", id: "tmdb.top")
                    ],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                TopShelfProvider(
                    addon: addon,
                    request: CatalogRequest(type: "movie", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                GenreExplorerShelfProvider(
                    addon: addon,
                    type: "movie",
                    genres: ["Action", "Comedy", "Drama"],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                RecentlyWatchedShelfProvider(
                    watchProgressStore: watchProgressStore,
                    sharedDataStore: sharedDataStore
                )
            ]
        )
    }
}
