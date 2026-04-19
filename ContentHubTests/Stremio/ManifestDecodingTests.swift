//
//  ManifestDecodingTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("Stremio Manifest decoding")
struct ManifestDecodingTests {
    @Test func decodesRealAddonManifest() throws {
        let data = try Fixtures.data(named: "manifest")
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)

        #expect(manifest.id == "aio-metadata")
        #expect(manifest.name == "AIOMetadata")
        #expect(manifest.version == "1.35.2")
        #expect(manifest.resources.contains("catalog"))
        #expect(manifest.resources.contains("meta"))
        #expect(manifest.types.contains("movie"))
        #expect(manifest.types.contains("series"))
        #expect(manifest.catalogs.count == 53)
    }

    @Test func firstCatalogIsTrendingMovies() throws {
        let data = try Fixtures.data(named: "manifest")
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)

        let first = try #require(manifest.catalogs.first)
        #expect(first.id == "tmdb.trending")
        #expect(first.type == "movie")
        #expect(first.name == "Em Alta")
        #expect(first.showInHome == true)
    }

    @Test func catalogsWithShowInHomeAreIdentifiable() throws {
        let data = try Fixtures.data(named: "manifest")
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)

        let homeCatalogs = manifest.catalogs.filter { $0.showInHome == true }
        #expect(homeCatalogs.count > 0)
        // All streaming.* catalogs should be home-visible.
        let streamingHome = homeCatalogs.filter { $0.id.hasPrefix("streaming.") }
        #expect(streamingHome.count >= 2)
    }
}
