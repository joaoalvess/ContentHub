//
//  MediaKind.swift
//  ContentHub
//
//  App-owned media taxonomy. Stremio types are mapped here so the rest of
//  the product does not depend on addon vocabulary.
//

import Foundation

nonisolated enum MediaKind: String, Sendable, Codable, CaseIterable, Hashable {
    case movie
    case series
    case anime
    case animeMovie

    init(stremioType: String) {
        switch stremioType.lowercased() {
        case "movie":
            self = .movie
        case "series":
            self = .series
        case "anime.movie":
            self = .animeMovie
        case "anime.series", "anime":
            self = .anime
        default:
            self = stremioType.contains("movie") ? .movie : .series
        }
    }

    var isAnime: Bool {
        self == .anime || self == .animeMovie
    }
}
