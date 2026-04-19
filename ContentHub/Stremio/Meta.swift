//
//  Meta.swift
//  ContentHub
//
//  DTO for the `Meta` objects returned by the Stremio catalog endpoint.
//  Only the fields we actually render are decoded — anything else is
//  silently ignored so that addon-side schema additions do not break us.
//

import Foundation

nonisolated struct Meta: Sendable, Codable, Equatable {
    let id: String
    let type: String
    let name: String
    let description: String?
    let poster: URL?
    let background: URL?
    let landscapePoster: URL?
    let logo: URL?
    let genres: [String]?
    let year: String?
    let releaseInfo: String?
    let runtime: String?
    let released: Date?
    let imdbRating: String?
    let imdbID: String?
    let tmdbID: String?
    let tvdbID: String?

    private enum CodingKeys: String, CodingKey {
        case id, type, name, description
        case poster, background, landscapePoster, logo
        case genres
        case year, releaseInfo, runtime, released
        case imdbRating
        case imdbID = "imdb_id"
        case tmdbID = "_tmdbId"
        case tvdbID = "_tvdbId"
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.type = try c.decode(String.self, forKey: .type)
        self.name = try c.decode(String.self, forKey: .name)
        self.description = try c.decodeIfPresent(String.self, forKey: .description)
        self.poster = Self.decodeURL(c, .poster)
        self.background = Self.decodeURL(c, .background)
        self.landscapePoster = Self.decodeURL(c, .landscapePoster)
        self.logo = Self.decodeURL(c, .logo)
        self.genres = try c.decodeIfPresent([String].self, forKey: .genres)
        self.year = try c.decodeIfPresent(String.self, forKey: .year)
        self.releaseInfo = try c.decodeIfPresent(String.self, forKey: .releaseInfo)
        self.runtime = try c.decodeIfPresent(String.self, forKey: .runtime)
        self.released = Self.decodeDate(c, .released)
        self.imdbRating = try c.decodeIfPresent(String.self, forKey: .imdbRating)
        self.imdbID = try c.decodeIfPresent(String.self, forKey: .imdbID)
        self.tmdbID = try c.decodeIfPresent(String.self, forKey: .tmdbID)
        self.tvdbID = try c.decodeIfPresent(String.self, forKey: .tvdbID)
    }

    /// Tolerant URL decoder: some metas include empty strings or missing hosts —
    /// we degrade to `nil` instead of failing the whole decode.
    private static func decodeURL(
        _ container: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> URL? {
        guard let raw = try? container.decodeIfPresent(String.self, forKey: key),
              !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    private static func decodeDate(
        _ container: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Date? {
        guard let raw = try? container.decodeIfPresent(String.self, forKey: key),
              !raw.isEmpty else { return nil }
        return iso8601WithFractionalSeconds.date(from: raw) ?? iso8601.date(from: raw)
    }

    // Memberwise init kept for tests and fixtures builders.
    nonisolated init(
        id: String,
        type: String,
        name: String,
        description: String? = nil,
        poster: URL? = nil,
        background: URL? = nil,
        landscapePoster: URL? = nil,
        logo: URL? = nil,
        genres: [String]? = nil,
        year: String? = nil,
        releaseInfo: String? = nil,
        runtime: String? = nil,
        released: Date? = nil,
        imdbRating: String? = nil,
        imdbID: String? = nil,
        tmdbID: String? = nil,
        tvdbID: String? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.poster = poster
        self.background = background
        self.landscapePoster = landscapePoster
        self.logo = logo
        self.genres = genres
        self.year = year
        self.releaseInfo = releaseInfo
        self.runtime = runtime
        self.released = released
        self.imdbRating = imdbRating
        self.imdbID = imdbID
        self.tmdbID = tmdbID
        self.tvdbID = tvdbID
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(poster, forKey: .poster)
        try c.encodeIfPresent(background, forKey: .background)
        try c.encodeIfPresent(landscapePoster, forKey: .landscapePoster)
        try c.encodeIfPresent(logo, forKey: .logo)
        try c.encodeIfPresent(genres, forKey: .genres)
        try c.encodeIfPresent(year, forKey: .year)
        try c.encodeIfPresent(releaseInfo, forKey: .releaseInfo)
        try c.encodeIfPresent(runtime, forKey: .runtime)
        if let released {
            try c.encode(Self.iso8601WithFractionalSeconds.string(from: released), forKey: .released)
        }
        try c.encodeIfPresent(imdbRating, forKey: .imdbRating)
        try c.encodeIfPresent(imdbID, forKey: .imdbID)
        try c.encodeIfPresent(tmdbID, forKey: .tmdbID)
        try c.encodeIfPresent(tvdbID, forKey: .tvdbID)
    }

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
