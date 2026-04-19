//
//  PageBlueprintTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("PageBlueprints")
struct PageBlueprintTests {
    @Test func homeBlueprintHasExpectedOrder() throws {
        let container = try InMemoryModelContainer.make()
        let blueprint = HomePageBlueprint.build(
            addon: .aioMetadata,
            client: StubAddonClient(),
            sharedDataStore: SharedDataStore(),
            watchProgressStore: WatchProgressStore(container: container)
        )

        #expect(blueprint.title == "Início")
        #expect(blueprint.providers.map(\.id) == [
            "home.continue-watching",
            "home.trending",
            "home.top10",
            "home.releases",
            "home.streaming-services",
            "home.for-you",
            "home.popular",
            "home.genre-explorer",
            "home.recently-watched"
        ])
        #expect(blueprint.providers.first?.priority == .critical)
        #expect(blueprint.heroSource == .shelf(id: "home.trending"))
    }

    @Test func moviesBlueprintUsesMovieOnlySources() throws {
        let container = try InMemoryModelContainer.make()
        let blueprint = MoviesPageBlueprint.build(
            addon: .aioMetadata,
            client: StubAddonClient(),
            sharedDataStore: SharedDataStore(),
            watchProgressStore: WatchProgressStore(container: container)
        )

        let trending = try #require(blueprint.providers.first { $0.id == "movies.trending" } as? TrendingShelfProvider)
        let continueWatching = try #require(blueprint.providers.first { $0.id == "movies.continue-watching" } as? ContinueWatchingShelfProvider)

        #expect(trending.request.type == "movie")
        #expect(continueWatching.allowedKinds == [.movie, .animeMovie])
    }
}
