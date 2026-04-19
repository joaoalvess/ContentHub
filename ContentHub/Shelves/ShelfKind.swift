//
//  ShelfKind.swift
//  ContentHub
//

import Foundation

nonisolated enum ShelfKind: String, Sendable, Codable, Equatable {
    case continueWatching
    case trending
    case top10
    case releases
    case streamingServices
    case forYou
    case popular
    case genreExplorer
    case recentlyWatched
}
