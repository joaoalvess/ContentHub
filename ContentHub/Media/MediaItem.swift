//
//  MediaItem.swift
//  ContentHub
//
//  Canonical domain model consumed by shelves, pages, and UI.
//

import Foundation

nonisolated struct MediaItem: Sendable, Identifiable, Hashable {
    let id: String
    let kind: MediaKind
    let title: String
    let description: String?
    let posterURL: URL?
    let landscapeURL: URL?
    let logoURL: URL?
    let genres: [String]
    let year: Int?
    let runtime: String?
    let rating: Double?
    let releaseDate: Date?
    let rank: Int?
    let progress: Double?

    func with(rank: Int?) -> MediaItem {
        MediaItem(
            id: id,
            kind: kind,
            title: title,
            description: description,
            posterURL: posterURL,
            landscapeURL: landscapeURL,
            logoURL: logoURL,
            genres: genres,
            year: year,
            runtime: runtime,
            rating: rating,
            releaseDate: releaseDate,
            rank: rank,
            progress: progress
        )
    }

    func with(progress: Double?) -> MediaItem {
        MediaItem(
            id: id,
            kind: kind,
            title: title,
            description: description,
            posterURL: posterURL,
            landscapeURL: landscapeURL,
            logoURL: logoURL,
            genres: genres,
            year: year,
            runtime: runtime,
            rating: rating,
            releaseDate: releaseDate,
            rank: rank,
            progress: progress
        )
    }

    func merged(with newer: MediaItem) -> MediaItem {
        MediaItem(
            id: id,
            kind: newer.kind,
            title: newer.title.isEmpty ? title : newer.title,
            description: newer.description ?? description,
            posterURL: newer.posterURL ?? posterURL,
            landscapeURL: newer.landscapeURL ?? landscapeURL,
            logoURL: newer.logoURL ?? logoURL,
            genres: newer.genres.isEmpty ? genres : newer.genres,
            year: newer.year ?? year,
            runtime: newer.runtime ?? runtime,
            rating: newer.rating ?? rating,
            releaseDate: newer.releaseDate ?? releaseDate,
            rank: newer.rank ?? rank,
            progress: newer.progress ?? progress
        )
    }
}
