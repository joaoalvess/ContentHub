//
//  AppEnvironment.swift
//  ContentHub
//
//  Lightweight DI container. Holds references to the shared app-level
//  services (addon client, data store, watch-progress store) so that
//  SwiftUI views can resolve them without global singletons.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class AppEnvironment {
    let modelContainer: ModelContainer
    let addonRegistry: AddonRegistry
    let addonClient: any AddonClient
    let sharedDataStore: SharedDataStore
    let watchProgressStore: WatchProgressStore

    init(
        modelContainer: ModelContainer,
        addonRegistry: AddonRegistry,
        addonClient: any AddonClient,
        sharedDataStore: SharedDataStore,
        watchProgressStore: WatchProgressStore
    ) {
        self.modelContainer = modelContainer
        self.addonRegistry = addonRegistry
        self.addonClient = addonClient
        self.sharedDataStore = sharedDataStore
        self.watchProgressStore = watchProgressStore
    }

    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([WatchProgress.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }
        // On-disk persistence failed — fall back to an in-memory store so the
        // app still boots. If even the in-memory container fails to build
        // we return a throwing-style error via fatalError because the app
        // cannot function without a container.
        let inMem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [inMem])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }

    static func live(container: ModelContainer) -> AppEnvironment {
        let registry = AddonRegistry(
            addons: [.aioMetadata],
            selectedAddonID: Addon.aioMetadata.id
        )

        return AppEnvironment(
            modelContainer: container,
            addonRegistry: registry,
            addonClient: HTTPAddonClient(),
            sharedDataStore: SharedDataStore(),
            watchProgressStore: WatchProgressStore(container: container)
        )
    }

    #if DEBUG
    /// Seeds a handful of `WatchProgress` rows on first launch so that
    /// the "Continuar Assistindo" shelf renders visually before there is
    /// a real playback engine.
    static func seedDebugProgressIfNeeded(in container: ModelContainer) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<WatchProgress>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        // IDs chosen to match entries that appear in the trending catalogue
        // of the default addon so the Continue-Watching cards resolve to
        // real posters after the first fetch.
        let seeds: [(String, Double)] = [
            ("tmdb:1613798", 0.42),
            ("tmdb:1035259", 0.75),
            ("tmdb:755898", 0.18),
            ("tmdb:1078605", 0.9)
        ]
        for (id, progress) in seeds {
            let row = WatchProgress(mediaID: id, progress: progress, updatedAt: .now)
            context.insert(row)
        }
        try? context.save()
    }
    #endif
}
