//
//  PageBlueprint.swift
//  ContentHub
//

import Foundation

nonisolated enum HeroSource: Sendable, Equatable {
    case shelf(id: String)
    case staticItems([MediaItem])
}

nonisolated struct PageBlueprint: Sendable {
    let id: String
    let title: String
    let heroSource: HeroSource
    let providers: [any ShelfProvider]
}
