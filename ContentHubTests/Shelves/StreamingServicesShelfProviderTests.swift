//
//  StreamingServicesShelfProviderTests.swift
//  ContentHubTests
//

import Foundation
import Testing
@testable import ContentHub

@Suite("StreamingServicesShelfProvider")
struct StreamingServicesShelfProviderTests {
    @Test func keepsPartialSuccessWhenOneSourceFails() async throws {
        let nfx = CatalogRequest(type: "movie", id: "streaming.nfx")
        let hbm = CatalogRequest(type: "movie", id: "streaming.hbm")
        let client = StubAddonClient(
            catalogResults: [
                nfx: .success(CatalogResponse(metas: [Meta(id: "tt1", type: "movie", name: "One", tmdbID: "1")])),
                hbm: .failure(.message("offline"))
            ]
        )
        let provider = StreamingServicesShelfProvider(
            addon: .aioMetadata,
            requests: [nfx, hbm],
            addonClient: client,
            sharedDataStore: SharedDataStore()
        )

        let shelf = try await provider.load()

        #expect(shelf.items.count == 1)
        #expect(shelf.isPartial == true)
    }
}
