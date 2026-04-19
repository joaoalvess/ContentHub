//
//  InMemoryModelContainer.swift
//  ContentHubTests
//

import SwiftData
@testable import ContentHub

enum InMemoryModelContainer {
    static func make() throws -> ModelContainer {
        let schema = Schema([WatchProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
