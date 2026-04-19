//
//  PageViewModel.swift
//  ContentHub
//

import Foundation
import Observation

nonisolated struct ShelfFailure: Error, Sendable, Equatable {
    let message: String

    init(_ error: Error) {
        self.message = String(describing: error)
    }
}

nonisolated enum ShelfState: Sendable, Equatable {
    case loading
    case loaded(Shelf)
    case empty
    case failed(ShelfFailure)
}

@Observable
@MainActor
final class PageViewModel {
    let blueprint: PageBlueprint

    private(set) var shelfStates: [String: ShelfState]
    private(set) var shelfOrder: [String]
    private(set) var heroItems: [MediaItem]

    init(blueprint: PageBlueprint) {
        self.blueprint = blueprint
        self.shelfOrder = blueprint.providers.map(\.id)
        self.shelfStates = Dictionary(
            uniqueKeysWithValues: blueprint.providers.map { ($0.id, .loading) }
        )

        switch blueprint.heroSource {
        case .shelf:
            self.heroItems = []
        case .staticItems(let items):
            self.heroItems = items
        }
    }

    func start() async {
        for provider in blueprint.providers {
            shelfStates[provider.id] = .loading
        }

        for priority in LoadPriority.allCases.sorted() {
            let tierProviders = blueprint.providers.filter { $0.priority == priority }
            let results = await withTaskGroup(of: ProviderLoadResult.self) { group in
                for provider in tierProviders {
                    group.addTask {
                        await Self.load(provider: provider)
                    }
                }

                var results: [ProviderLoadResult] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            for result in results {
                apply(result)
            }
        }
    }

    func retry(shelfID: String) async {
        guard let provider = blueprint.providers.first(where: { $0.id == shelfID }) else {
            return
        }

        shelfStates[shelfID] = .loading
        let result = await Self.load(provider: provider)
        apply(result)
    }

    private func apply(_ result: ProviderLoadResult) {
        switch result.outcome {
        case .success(let shelf):
            shelfStates[result.id] = shelf.items.isEmpty ? .empty : .loaded(shelf)
            if case .shelf(let heroShelfID) = blueprint.heroSource, heroShelfID == result.id {
                heroItems = shelf.items
            }
        case .failure(let failure):
            shelfStates[result.id] = .failed(failure)
            if case .shelf(let heroShelfID) = blueprint.heroSource, heroShelfID == result.id {
                heroItems = []
            }
        }
    }

    private static func load(provider: any ShelfProvider) async -> ProviderLoadResult {
        do {
            let shelf = try await provider.load()
            return ProviderLoadResult(id: provider.id, outcome: .success(shelf))
        } catch {
            return ProviderLoadResult(id: provider.id, outcome: .failure(ShelfFailure(error)))
        }
    }
}

private nonisolated struct ProviderLoadResult: Sendable {
    nonisolated enum Outcome: Sendable {
        case success(Shelf)
        case failure(ShelfFailure)
    }

    let id: String
    let outcome: Outcome
}
