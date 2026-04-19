//
//  WatchProgress.swift
//  ContentHub
//
//  SwiftData-persisted watch state. Drives the "Continuar Assistindo"
//  and "Assistidos Recentemente" shelves. Real schema details are
//  validated by Layer 6 TDD.
//

import Foundation
import SwiftData

@Model
final class WatchProgress {
    @Attribute(.unique) var mediaID: String
    var progress: Double
    var updatedAt: Date

    init(mediaID: String, progress: Double, updatedAt: Date = .now) {
        self.mediaID = mediaID
        self.progress = progress
        self.updatedAt = updatedAt
    }
}
