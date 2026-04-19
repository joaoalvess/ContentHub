//
//  PageViewModelTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@MainActor
@Suite("PageViewModel")
struct PageViewModelTests {
    @Test func startLoadsShelvesIncrementallyAndKeepsFailuresIsolated() async {
        let blueprint = PageBlueprint(
            id: "test",
            title: "Test",
            heroSource: .shelf(id: "critical"),
            providers: [
                TestShelfProvider(id: "critical", priority: .critical, result: .success(Self.makeShelf(id: "critical"))),
                TestShelfProvider(id: "failing", priority: .normal, result: .failure(.message("boom"))),
                TestShelfProvider(id: "normal", priority: .normal, result: .success(Self.makeShelf(id: "normal")))
            ]
        )

        let model = PageViewModel(blueprint: blueprint)
        await model.start()

        if case .loaded(let shelf)? = model.shelfStates["critical"] {
            #expect(shelf.id == "critical")
        } else {
            Issue.record("critical shelf should be loaded")
        }

        if case .failed(let failure)? = model.shelfStates["failing"] {
            #expect(failure.message.contains("boom"))
        } else {
            Issue.record("failing shelf should be failed")
        }

        if case .loaded(let shelf)? = model.shelfStates["normal"] {
            #expect(shelf.id == "normal")
        } else {
            Issue.record("normal shelf should be loaded")
        }

        #expect(model.heroItems.map(\.id) == ["tmdb:critical"])
    }

    @Test func startRespectsPriorityTiers() async {
        let recorder = LoadOrderRecorder()
        let blueprint = PageBlueprint(
            id: "priority",
            title: "Priority",
            heroSource: .staticItems([]),
            providers: [
                TestShelfProvider(
                    id: "critical",
                    priority: .critical,
                    delayNanoseconds: 50_000_000,
                    result: .success(Self.makeShelf(id: "critical")),
                    recorder: recorder
                ),
                TestShelfProvider(
                    id: "normal",
                    priority: .normal,
                    delayNanoseconds: 1_000_000,
                    result: .success(Self.makeShelf(id: "normal")),
                    recorder: recorder
                )
            ]
        )

        let model = PageViewModel(blueprint: blueprint)
        await model.start()

        let order = await recorder.snapshot()
        #expect(order == ["critical", "normal"])
    }

    @Test func retryReloadsOnlyTargetShelf() async {
        let flakey = FlakeyShelfSource(
            first: .failure(.message("offline")),
            second: .success(Self.makeShelf(id: "retry"))
        )

        let blueprint = PageBlueprint(
            id: "retry",
            title: "Retry",
            heroSource: .staticItems([]),
            providers: [
                FlakeyShelfProvider(id: "retry", source: flakey),
                TestShelfProvider(id: "stable", priority: .normal, result: .success(Self.makeShelf(id: "stable")))
            ]
        )

        let model = PageViewModel(blueprint: blueprint)
        await model.start()
        let stableBefore = model.shelfStates["stable"]

        if case .failed? = model.shelfStates["retry"] {
            // expected
        } else {
            Issue.record("retry shelf should fail on first load")
        }

        await model.retry(shelfID: "retry")

        if case .loaded(let shelf)? = model.shelfStates["retry"] {
            #expect(shelf.id == "retry")
        } else {
            Issue.record("retry shelf should load after retry")
        }

        #expect(model.shelfStates["stable"] == stableBefore)
    }

    private static func makeShelf(id: String) -> Shelf {
        Shelf(
            id: id,
            title: id,
            layout: .poster,
            kind: .trending,
            items: [
                MediaItem(
                    id: "tmdb:\(id)",
                    kind: .movie,
                    title: id,
                    description: nil,
                    posterURL: nil,
                    landscapeURL: nil,
                    logoURL: nil,
                    genres: [],
                    year: nil,
                    runtime: nil,
                    rating: nil,
                    releaseDate: nil,
                    rank: nil,
                    progress: nil
                )
            ]
        )
    }
}

private struct TestShelfProvider: ShelfProvider {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let priority: LoadPriority
    let delayNanoseconds: UInt64
    let result: TestShelfResult
    let recorder: LoadOrderRecorder?

    init(
        id: String,
        priority: LoadPriority,
        delayNanoseconds: UInt64 = 0,
        result: TestShelfResult,
        recorder: LoadOrderRecorder? = nil
    ) {
        self.id = id
        self.title = id
        self.layout = .poster
        self.kind = .trending
        self.priority = priority
        self.delayNanoseconds = delayNanoseconds
        self.result = result
        self.recorder = recorder
    }

    nonisolated func load() async throws -> Shelf {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        if let recorder {
            await recorder.record(id)
        }
        switch result {
        case .success(let shelf):
            return shelf
        case .failure(let error):
            throw error
        }
    }
}

private actor LoadOrderRecorder {
    private var values: [String] = []

    func record(_ value: String) {
        values.append(value)
    }

    func snapshot() -> [String] {
        values
    }
}

private actor FlakeyShelfSource {
    private var results: [TestShelfResult]

    init(first: TestShelfResult, second: TestShelfResult) {
        self.results = [first, second]
    }

    func next() -> TestShelfResult {
        if results.isEmpty {
            return .success(
                Shelf(
                    id: "fallback",
                    title: "fallback",
                    layout: .poster,
                    kind: .trending,
                    items: []
                )
            )
        }

        return results.removeFirst()
    }
}

private struct FlakeyShelfProvider: ShelfProvider {
    let id: String
    let title: String
    let layout: ShelfLayout
    let kind: ShelfKind
    let priority: LoadPriority
    let source: FlakeyShelfSource

    init(id: String, source: FlakeyShelfSource) {
        self.id = id
        self.title = id
        self.layout = .poster
        self.kind = .trending
        self.priority = .normal
        self.source = source
    }

    nonisolated func load() async throws -> Shelf {
        switch await source.next() {
        case .success(let shelf):
            return shelf
        case .failure(let error):
            throw error
        }
    }
}

private nonisolated enum TestShelfResult: Sendable {
    case success(Shelf)
    case failure(StubAddonError)
}
