//
//  SeriesPageBlueprint.swift
//  ContentHub
//

import Foundation

enum SeriesPageBlueprint {
    static func build(
        addon: Addon,
        client: any AddonClient,
        sharedDataStore: SharedDataStore,
        watchProgressStore: WatchProgressStore
    ) -> PageBlueprint {
        PageBlueprint(
            id: "series",
            title: "Séries",
            heroSource: .shelf(id: "series.trending"),
            providers: [
                ContinueWatchingShelfProvider(
                    id: "series.continue-watching",
                    allowedKinds: [.series],
                    watchProgressStore: watchProgressStore,
                    sharedDataStore: sharedDataStore
                ),
                TrendingShelfProvider(
                    id: "series.trending",
                    addon: addon,
                    request: CatalogRequest(type: "series", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                Top10ShelfProvider(
                    id: "series.top10",
                    addon: addon,
                    request: CatalogRequest(type: "series", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                ReleasesShelfProvider(
                    id: "series.releases",
                    addon: addon,
                    request: CatalogRequest(type: "series", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                StreamingServicesShelfProvider(
                    id: "series.streaming-services",
                    addon: addon,
                    requests: [
                        CatalogRequest(type: "series", id: "streaming.nfx"),
                        CatalogRequest(type: "series", id: "streaming.hbm")
                    ],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                ForYouShelfProvider(
                    id: "series.for-you",
                    addon: addon,
                    requests: [CatalogRequest(type: "series", id: "tmdb.top")],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                TopShelfProvider(
                    id: "series.popular",
                    addon: addon,
                    request: CatalogRequest(type: "series", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                GenreExplorerShelfProvider(
                    id: "series.genre-explorer",
                    addon: addon,
                    type: "series",
                    genres: ["Drama", "Crime", "Mystery"],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                RecentlyWatchedShelfProvider(
                    id: "series.recently-watched",
                    allowedKinds: [.series],
                    watchProgressStore: watchProgressStore,
                    sharedDataStore: sharedDataStore
                )
            ]
        )
    }
}
