//
//  ShelfLayout.swift
//  ContentHub
//
//  UI-agnostic shelf layout intent. The view layer dispatches on this later.
//

import Foundation

nonisolated enum ShelfLayout: String, Sendable, Codable, Equatable {
    case poster
    case top10
    case continueWatching
    case landscape
}
