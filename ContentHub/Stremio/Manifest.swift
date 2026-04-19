//
//  Manifest.swift
//  ContentHub
//
//  DTO for the Stremio addon manifest endpoint. Only decodes the fields
//  we use — unknown keys are ignored so that minor upstream changes do
//  not break the app.
//

import Foundation

nonisolated struct Manifest: Sendable, Codable, Equatable {
    let id: String
    let version: String
    let name: String
    let description: String?
    let resources: [String]
    let types: [String]
    let catalogs: [Catalog]
    let background: URL?
    let logo: URL?

    nonisolated struct Catalog: Sendable, Codable, Equatable {
        let id: String
        let type: String
        let name: String
        let pageSize: Int?
        let extra: [Extra]?
        let showInHome: Bool?

        nonisolated struct Extra: Sendable, Codable, Equatable {
            let name: String
            let options: [String]?
            let isRequired: Bool?
            let `default`: String?
        }
    }
}
