//
//  SettingWindow.swift
//  NotchIsland
//
//  Created by 曹丁杰 on 2024/8/10.
//


import SwiftUI

class SettingsWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 80, y: 80, width: 300, height: 200),
                   styleMask: [.titled, .closable, .miniaturizable, .resizable],
                   backing: .buffered,
                   defer: false)
        
        self.title = "Settings"
        
        self.contentView = NSHostingView(rootView: SettingsView())
        self.center()
        self.setFrameAutosaveName("Settings Window")
        
        // Remove the makeKeyAndOrderFront call from here
    }
}

//class SettingsWindow: NSWindow {
//    init() {
//        
//        
//        self.center()
//        self.setFrameAutosaveName("Settings Window")
//        self.contentView = NSHostingView(rootView: SettingsView())
//        self.makeKeyAndOrderFront(nil)
//    }
//}




