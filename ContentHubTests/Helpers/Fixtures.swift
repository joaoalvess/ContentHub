//
//  Fixtures.swift
//  ContentHubTests
//
//  Loads JSON fixtures from the test bundle. If the file cannot be located
//  (e.g. because `PBXFileSystemSynchronizedRootGroup` did not include the
//  non-swift file as a resource), the loader will throw a `FixtureError`
//  with a descriptive message — so we get a clear failure instead of a
//  confusing decoding crash.
//

import Foundation
import Testing

enum FixtureError: Error, CustomStringConvertible {
    case notFound(String)

    var description: String {
        switch self {
        case .notFound(let name):
            return "Fixture '\(name)' not found in test bundle. " +
                   "If this is the first time you see this, the " +
                   "PBXFileSystemSynchronizedRootGroup likely does not " +
                   "include the Fixtures directory as a resource. " +
                   "Add a synchronized-group exception or embed the JSON " +
                   "as a string literal."
        }
    }
}

private final class FixtureLocator {}

enum Fixtures {
    /// Loads raw data for a fixture file. Looks in a few common locations.
    static func data(named name: String, fileExtension: String = "json") throws -> Data {
        let bundle = Bundle(for: FixtureLocator.self)

        let candidates: [URL?] = [
            bundle.url(forResource: name, withExtension: fileExtension, subdirectory: "Fixtures"),
            bundle.url(forResource: name, withExtension: fileExtension),
            bundle.resourceURL?
                .appendingPathComponent("Fixtures")
                .appendingPathComponent("\(name).\(fileExtension)"),
            bundle.bundleURL
                .appendingPathComponent("Fixtures")
                .appendingPathComponent("\(name).\(fileExtension)")
        ]

        for candidate in candidates {
            guard let url = candidate else { continue }
            if let data = try? Data(contentsOf: url) {
                return data
            }
        }

        throw FixtureError.notFound("\(name).\(fileExtension)")
    }
}
