//
//  AddonRegistry.swift
//  ContentHub
//
//  Observable list of configured addons. The app starts with one addon,
//  but the registry keeps expansion to multiple sources straightforward.
//

import Observation

@Observable
@MainActor
final class AddonRegistry {
    var addons: [Addon]
    var selectedAddonID: String

    init(addons: [Addon], selectedAddonID: String? = nil) {
        self.addons = addons
        self.selectedAddonID = selectedAddonID ?? addons.first?.id ?? ""
    }

    var selectedAddon: Addon? {
        addons.first { $0.id == selectedAddonID }
    }
}
