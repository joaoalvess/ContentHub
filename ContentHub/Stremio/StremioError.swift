//
//  StremioError.swift
//  ContentHub
//

import Foundation

nonisolated enum StremioError: Error, Sendable, Equatable, CustomStringConvertible {
    case invalidURL
    case httpStatus(Int)
    case decoding(String)
    case transport(String)

    var description: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpStatus(let code): return "HTTP status \(code)"
        case .decoding(let msg): return "Decoding error: \(msg)"
        case .transport(let msg): return "Transport error: \(msg)"
        }
    }
}
