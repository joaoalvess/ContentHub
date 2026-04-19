//
//  MetaDecodingTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("Stremio Meta decoding")
struct MetaDecodingTests {
    @Test func decodesTrendingMovieCatalog() throws {
        let data = try Fixtures.data(named: "catalog_trending_movie")
        let response = try JSONDecoder().decode(CatalogResponse.self, from: data)

        #expect(response.metas.count == 20)
        let first = try #require(response.metas.first)
        #expect(first.id == "tt37989803")
        #expect(first.type == "movie")
        #expect(first.name == "Vingança Brutal")
        #expect(first.year == "2026")
        #expect(first.imdbRating == "6")
        #expect(first.imdbID == "tt37989803")
        #expect(first.tmdbID == "1613798")
        #expect(first.poster?.absoluteString.contains("image.tmdb.org") == true)
    }

    @Test func decodesTrendingSeriesCatalog() throws {
        let data = try Fixtures.data(named: "catalog_top_series")
        let response = try JSONDecoder().decode(CatalogResponse.self, from: data)

        #expect(response.metas.count > 0)
        let series = try #require(response.metas.first { $0.type == "series" })
        #expect(!series.name.isEmpty)
    }

    @Test func toleratesMissingOptionalFields() throws {
        // Minimal JSON: only id, type, name.
        let json = #"{ "metas": [ { "id": "tt1", "type": "movie", "name": "Bare" } ] }"#
        let data = Data(json.utf8)
        let response = try JSONDecoder().decode(CatalogResponse.self, from: data)
        let meta = try #require(response.metas.first)
        #expect(meta.description == nil)
        #expect(meta.poster == nil)
        #expect(meta.logo == nil)
        #expect(meta.imdbRating == nil)
        #expect(meta.genres == nil || meta.genres?.isEmpty == true)
    }
}
