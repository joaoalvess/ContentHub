//
//  Shelf.swift
//  ContentHub
//

import Foundation

nonisolated struct Shelf: Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let items: [MediaItem]
    let isPartial: Bool

    init(
        id: String,
        title: String,
        layout: ShelfLayout,
        kind: ShelfKind,
        items: [MediaItem],
        isPartial: Bool = false
    ) {
        self.id = id
        self.title = title
        self.layout = layout
        self.kind = kind
        self.items = items
        self.isPartial = isPartial
    }
}
