//
//  ShelfProvider.swift
//  ContentHub
//

import Foundation

nonisolated enum LoadPriority: Int, Sendable, Codable, CaseIterable, Comparable {
    case critical = 0
    case high = 1
    case normal = 2
    case low = 3

    static func < (lhs: LoadPriority, rhs: LoadPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

protocol ShelfProvider: Sendable {
    nonisolated var id: String { get }
    nonisolated var title: String { get }
    nonisolated var layout: ShelfLayout { get }
    nonisolated var kind: ShelfKind { get }
    nonisolated var priority: LoadPriority { get }
    nonisolated func load() async throws -> Shelf
}
