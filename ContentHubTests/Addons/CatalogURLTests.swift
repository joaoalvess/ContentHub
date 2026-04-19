//
//  CatalogURLTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("Catalog URL builder")
struct CatalogURLTests {
    @Test func buildsBaseCatalogURL() throws {
        let addon = Addon(
            id: "stub",
            name: "Stub",
            manifestURL: try #require(URL(string: "https://example.com/stremio/manifest.json"))
        )

        let url = try HTTPAddonClient().catalogURL(
            for: addon,
            request: CatalogRequest(type: "movie", id: "tmdb.trending")
        )

        #expect(url.absoluteString == "https://example.com/stremio/catalog/movie/tmdb.trending.json")
    }

    @Test func appendsGenreAndSkipSegments() throws {
        let addon = Addon(
            id: "stub",
            name: "Stub",
            manifestURL: try #require(URL(string: "https://example.com/stremio/manifest.json"))
        )

        let url = try HTTPAddonClient().catalogURL(
            for: addon,
            request: CatalogRequest(type: "movie", id: "tmdb.top", genre: "Action", skip: 40)
        )

        #expect(url.absoluteString == "https://example.com/stremio/catalog/movie/tmdb.top/genre=Action/skip=40.json")
    }
}
