//
//  AddonClient.swift
//  ContentHub
//
//  Networking contract for addon access. Providers depend on the protocol;
//  the concrete HTTP client is the only place that knows about URLSession.
//

import Foundation

nonisolated struct CatalogRequest: Sendable, Hashable {
    let type: String
    let id: String
    let genre: String?
    let skip: Int?

    init(type: String, id: String, genre: String? = nil, skip: Int? = nil) {
        self.type = type
        self.id = id
        self.genre = genre
        self.skip = skip
    }
}

protocol AddonClient: Sendable {
    nonisolated func fetchManifest(for addon: Addon) async throws -> Manifest
    nonisolated func fetchCatalog(for addon: Addon, request: CatalogRequest) async throws -> CatalogResponse
    nonisolated func catalogURL(for addon: Addon, request: CatalogRequest) throws -> URL
}

extension AddonClient {
    nonisolated func fetchCatalog(
        for addon: Addon,
        type: String,
        id: String,
        genre: String? = nil,
        skip: Int? = nil
    ) async throws -> CatalogResponse {
        try await fetchCatalog(
            for: addon,
            request: CatalogRequest(type: type, id: id, genre: genre, skip: skip)
        )
    }

    nonisolated func catalogURL(
        for addon: Addon,
        type: String,
        id: String,
        genre: String? = nil,
        skip: Int? = nil
    ) throws -> URL {
        try catalogURL(
            for: addon,
            request: CatalogRequest(type: type, id: id, genre: genre, skip: skip)
        )
    }
}

nonisolated struct HTTPAddonClient: AddonClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    nonisolated func fetchManifest(for addon: Addon) async throws -> Manifest {
        try await execute(url: addon.manifestURL, as: Manifest.self)
    }

    nonisolated func fetchCatalog(
        for addon: Addon,
        request: CatalogRequest
    ) async throws -> CatalogResponse {
        try await execute(
            url: try catalogURL(for: addon, request: request),
            as: CatalogResponse.self
        )
    }

    nonisolated func catalogURL(for addon: Addon, request: CatalogRequest) throws -> URL {
        guard !request.type.isEmpty, !request.id.isEmpty else {
            throw StremioError.invalidURL
        }

        var segments = [
            "catalog",
            request.type,
            request.id
        ]

        if let genre = request.genre, !genre.isEmpty {
            segments.append("genre=\(genre)")
        }

        if let skip = request.skip {
            segments.append("skip=\(skip)")
        }

        guard var components = URLComponents(
            url: addon.baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw StremioError.invalidURL
        }

        let encodedSegments = segments.map { segment in
            segment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? segment
        }

        let basePath = components.percentEncodedPath.hasSuffix("/")
            ? String(components.percentEncodedPath.dropLast())
            : components.percentEncodedPath

        components.percentEncodedPath = basePath + "/" + encodedSegments.joined(separator: "/") + ".json"

        guard let url = components.url else {
            throw StremioError.invalidURL
        }

        return url
    }

    private nonisolated func execute<T: Decodable>(url: URL, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)

            guard let http = response as? HTTPURLResponse else {
                throw StremioError.transport("Non-HTTP response")
            }

            guard (200..<300).contains(http.statusCode) else {
                throw StremioError.httpStatus(http.statusCode)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw StremioError.decoding(String(describing: error))
            }
        } catch let error as StremioError {
            throw error
        } catch {
            throw StremioError.transport(String(describing: error))
        }
    }
}
