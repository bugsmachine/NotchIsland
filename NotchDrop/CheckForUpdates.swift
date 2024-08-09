//
//  CheckForUpdates.swift
//  NotchIsland
//
//  Created by 曹丁杰 on 2024/8/9.
//

import SwiftUI
import Sparkle

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}


