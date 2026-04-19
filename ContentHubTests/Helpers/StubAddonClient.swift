//
//  StubAddonClient.swift
//  ContentHubTests
//

import Foundation
@testable import ContentHub

enum StubAddonError: Error, Sendable, Equatable, CustomStringConvertible {
    case missingCatalog(CatalogRequest)
    case message(String)

    var description: String {
        switch self {
        case .missingCatalog(let request):
            return "Missing stub for \(request.type)/\(request.id)"
        case .message(let message):
            return message
        }
    }
}

nonisolated enum StubCatalogResult: Sendable {
    case success(CatalogResponse)
    case failure(StubAddonError)
}

actor CatalogRequestRecorder {
    private var requests: [CatalogRequest] = []

    func record(_ request: CatalogRequest) {
        requests.append(request)
    }

    func snapshot() -> [CatalogRequest] {
        requests
    }
}

struct StubAddonClient: AddonClient {
    let manifest: Manifest
    let catalogResults: [CatalogRequest: StubCatalogResult]
    let recorder: CatalogRequestRecorder?

    init(
        manifest: Manifest = Manifest(
            id: "stub",
            version: "1.0.0",
            name: "Stub Addon",
            description: nil,
            resources: ["catalog"],
            types: ["movie"],
            catalogs: [],
            background: nil,
            logo: nil
        ),
        catalogResults: [CatalogRequest: StubCatalogResult] = [:],
        recorder: CatalogRequestRecorder? = nil
    ) {
        self.manifest = manifest
        self.catalogResults = catalogResults
        self.recorder = recorder
    }

    nonisolated func fetchManifest(for addon: Addon) async throws -> Manifest {
        manifest
    }

    nonisolated func fetchCatalog(
        for addon: Addon,
        request: CatalogRequest
    ) async throws -> CatalogResponse {
        if let recorder {
            await recorder.record(request)
        }

        guard let result = catalogResults[request] else {
            throw StubAddonError.missingCatalog(request)
        }

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    nonisolated func catalogURL(for addon: Addon, request: CatalogRequest) throws -> URL {
        try HTTPAddonClient().catalogURL(for: addon, request: request)
    }
}
