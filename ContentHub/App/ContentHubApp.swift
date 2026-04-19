//
//  ContentHubApp.swift
//  ContentHub
//

import SwiftUI
import SwiftData

@main
struct ContentHubApp: App {
    private let environment: AppEnvironment
    private let sharedContainer: ModelContainer

    init() {
        let container = AppEnvironment.makeModelContainer()
        self.sharedContainer = container
        self.environment = AppEnvironment.live(container: container)

        #if DEBUG
        AppEnvironment.seedDebugProgressIfNeeded(in: container)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
        .modelContainer(sharedContainer)
    }
}
