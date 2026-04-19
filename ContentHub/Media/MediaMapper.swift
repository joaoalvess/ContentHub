//
//  MediaMapper.swift
//  ContentHub
//
//  Converts addon DTOs into app-owned MediaItem values.
//

import Foundation

nonisolated struct MediaMapper: Sendable {
    func map(_ meta: Meta) -> MediaItem {
        MediaItem(
            id: Self.canonicalID(for: meta),
            kind: MediaKind(stremioType: meta.type),
            title: meta.name,
            description: meta.description,
            posterURL: meta.poster,
            landscapeURL: meta.landscapePoster ?? meta.background,
            logoURL: meta.logo,
            genres: meta.genres ?? [],
            year: Self.parseYear(meta.year),
            runtime: meta.runtime,
            rating: Self.parseRating(meta.imdbRating),
            releaseDate: meta.released,
            rank: nil,
            progress: nil
        )
    }

    func map(_ metas: [Meta]) -> [MediaItem] {
        metas.map(map)
    }

    static func canonicalID(for meta: Meta) -> String {
        if let tmdbID = meta.tmdbID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !tmdbID.isEmpty {
            return "tmdb:\(tmdbID)"
        }

        if let imdbID = meta.imdbID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !imdbID.isEmpty {
            return "imdb:\(imdbID)"
        }

        return "\(meta.type):\(meta.id)"
    }

    static func parseYear(_ raw: String?) -> Int? {
        guard let raw else { return nil }
        let digits = raw.prefix(4)
        return Int(digits)
    }

    static func parseRating(_ raw: String?) -> Double? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return Double(raw.replacingOccurrences(of: ",", with: "."))
    }
}
