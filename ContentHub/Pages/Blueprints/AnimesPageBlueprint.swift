//
//  AnimesPageBlueprint.swift
//  ContentHub
//

import Foundation

enum AnimesPageBlueprint {
    static func build(
        addon: Addon,
        client: any AddonClient,
        sharedDataStore: SharedDataStore,
        watchProgressStore: WatchProgressStore
    ) -> PageBlueprint {
        PageBlueprint(
            id: "animes",
            title: "Animes",
            heroSource: .shelf(id: "animes.trending"),
            providers: [
                ContinueWatchingShelfProvider(
                    id: "animes.continue-watching",
                    allowedKinds: [.anime, .animeMovie],
                    watchProgressStore: watchProgressStore,
                    sharedDataStore: sharedDataStore
                ),
                TrendingShelfProvider(
                    id: "animes.trending",
                    addon: addon,
                    request: CatalogRequest(type: "anime", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                Top10ShelfProvider(
                    id: "animes.top10",
                    addon: addon,
                    request: CatalogRequest(type: "anime", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                ReleasesShelfProvider(
                    id: "animes.releases",
                    addon: addon,
                    request: CatalogRequest(type: "anime", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                StreamingServicesShelfProvider(
                    id: "animes.streaming-services",
                    addon: addon,
                    requests: [
                        CatalogRequest(type: "anime", id: "streaming.nfx"),
                        CatalogRequest(type: "anime", id: "streaming.crn")
                    ],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                ForYouShelfProvider(
                    id: "animes.for-you",
                    addon: addon,
                    requests: [CatalogRequest(type: "anime", id: "tmdb.top")],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                TopShelfProvider(
                    id: "animes.popular",
                    addon: addon,
                    request: CatalogRequest(type: "anime", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                GenreExplorerShelfProvider(
                    id: "animes.genre-explorer",
                    addon: addon,
                    type: "anime",
                    genres: ["Shounen", "Isekai", "Drama"],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                RecentlyWatchedShelfProvider(
                    id: "animes.recently-watched",
                    allowedKinds: [.anime, .animeMovie],
                    watchProgressStore: watchProgressStore,
                    sharedDataStore: sharedDataStore
                )
            ]
        )
    }
}
