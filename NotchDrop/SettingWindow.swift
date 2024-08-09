//
//  SettingWindow.swift
//  NotchIsland
//
//  Created by 曹丁杰 on 2024/8/10.
//

import SwiftUI

class SettingsWindow: NSWindow {
    init() {
        super.init(contentRect: NSRect(x: 100, y: 100, width: 300, height: 200),
                   styleMask: [.titled, .closable, .miniaturizable, .resizable],
                   backing: .buffered,
                   defer: false)
        
        self.center()
        self.setFrameAutosaveName("Settings Window")
        self.contentView = NSHostingView(rootView: SettingsView())
        self.makeKeyAndOrderFront(nil)
    }
}
