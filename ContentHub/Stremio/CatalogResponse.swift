//
//  CatalogResponse.swift
//  ContentHub
//
//  Wrapper type for the JSON returned by `/catalog/{type}/{id}.json`.
//

import Foundation

nonisolated struct CatalogResponse: Sendable, Codable, Equatable {
    let metas: [Meta]
}
