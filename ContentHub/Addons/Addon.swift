//
//  Addon.swift
//  ContentHub
//
//  Immutable description of a remote addon source. The rest of the app
//  depends on this small surface instead of hard-coding manifest URLs.
//

import Foundation

nonisolated struct Addon: Sendable, Identifiable, Equatable {
    let id: String
    let name: String
    let manifestURL: URL
    let baseURL: URL
    let manifest: Manifest?

    init(
        id: String? = nil,
        name: String? = nil,
        manifestURL: URL,
        manifest: Manifest? = nil
    ) {
        self.id = id ?? manifest?.id ?? manifestURL.deletingPathExtension().lastPathComponent
        self.name = name ?? manifest?.name ?? manifestURL.deletingPathExtension().lastPathComponent
        self.manifestURL = manifestURL
        self.baseURL = manifestURL.deletingLastPathComponent()
        self.manifest = manifest
    }
}

extension Addon {
    static let aioMetadata = Addon(
        id: "aio-metadata",
        name: "AIOMetadata",
        manifestURL: URL(string: "https://aiometadata.viren070.me/stremio/8c777fa0-4d2e-4b2b-a8ca-54473a2daf42/manifest.json")!
    )
}
