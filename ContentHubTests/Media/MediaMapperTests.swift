//
//  MediaMapperTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("MediaMapper")
struct MediaMapperTests {
    private let mapper = MediaMapper()

    @Test func mapsTMDBIDsYearAndRating() {
        let meta = Meta(
            id: "tt123",
            type: "movie",
            name: "Test Movie",
            description: "Desc",
            poster: URL(string: "https://example.com/poster.jpg"),
            background: URL(string: "https://example.com/background.jpg"),
            landscapePoster: nil,
            logo: URL(string: "https://example.com/logo.png"),
            genres: ["Action"],
            year: "2026",
            releaseInfo: nil,
            runtime: "120 min",
            released: Date(timeIntervalSince1970: 1_700_000_000),
            imdbRating: "6",
            imdbID: "tt123",
            tmdbID: "1613798",
            tvdbID: nil
        )

        let item = mapper.map(meta)

        #expect(item.id == "tmdb:1613798")
        #expect(item.kind == .movie)
        #expect(item.year == 2026)
        #expect(item.rating == 6.0)
        #expect(item.landscapeURL == URL(string: "https://example.com/background.jpg"))
    }

    @Test func fallsBackToIMDbWhenTMDBIsMissing() {
        let meta = Meta(
            id: "tt999",
            type: "series",
            name: "Fallback",
            imdbID: "tt999"
        )

        let item = mapper.map(meta)

        #expect(item.id == "imdb:tt999")
        #expect(item.kind == .series)
    }
}
