//
//  MoviesPageBlueprint.swift
//  ContentHub
//

import Foundation

enum MoviesPageBlueprint {
    static func build(
        addon: Addon,
        client: any AddonClient,
        sharedDataStore: SharedDataStore,
        watchProgressStore: WatchProgressStore
    ) -> PageBlueprint {
        PageBlueprint(
            id: "movies",
            title: "Filmes",
            heroSource: .shelf(id: "movies.trending"),
            providers: [
                ContinueWatchingShelfProvider(
                    id: "movies.continue-watching",
                    allowedKinds: [.movie, .animeMovie],
                    watchProgressStore: watchProgressStore,
                    sharedDataStore: sharedDataStore
                ),
                TrendingShelfProvider(
                    id: "movies.trending",
                    addon: addon,
                    request: CatalogRequest(type: "movie", id: "tmdb.trending"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                Top10ShelfProvider(
                    id: "movies.top10",
                    addon: addon,
                    request: CatalogRequest(type: "movie", id: "tmdb.trending"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                ReleasesShelfProvider(
                    id: "movies.releases",
                    addon: addon,
                    request: CatalogRequest(type: "movie", id: "tmdb.trending"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                StreamingServicesShelfProvider(
                    id: "movies.streaming-services",
                    addon: addon,
                    requests: [
                        CatalogRequest(type: "movie", id: "streaming.nfx"),
                        CatalogRequest(type: "movie", id: "streaming.hbm")
                    ],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                ForYouShelfProvider(
                    id: "movies.for-you",
                    addon: addon,
                    requests: [CatalogRequest(type: "movie", id: "tmdb.popular")],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                TopShelfProvider(
                    id: "movies.popular",
                    addon: addon,
                    request: CatalogRequest(type: "movie", id: "tmdb.top"),
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                GenreExplorerShelfProvider(
                    id: "movies.genre-explorer",
                    addon: addon,
                    type: "movie",
                    genres: ["Action", "Sci-Fi", "Thriller"],
                    addonClient: client,
                    sharedDataStore: sharedDataStore
                ),
                RecentlyWatchedShelfProvider(
                    id: "movies.recently-watched",
                    allowedKinds: [.movie, .animeMovie],
                    watchProgressStore: watchProgressStore,
                    sharedDataStore: sharedDataStore
                )
            ]
        )
    }
}
