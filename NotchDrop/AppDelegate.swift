//
//  AppDelegate.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import AppKit
import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate {
    var isFirstOpen = true
    var mainWindowController: NotchWindowController?

    var timer: Timer?
    
    
    func application(_ application: NSApplication, open urls: [URL]) {
            for url in urls {
                handleCustomURL(url)
            }
        }

        func handleCustomURL(_ url: URL) {
//            print("Received URL: \(url)")
            var count = 0
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                for queryItem in queryItems {
                    if queryItem.name == "token", let token = queryItem.value {
//                        print("Token: \(token)")
                        UserDefaults.standard.set(token, forKey: "userToken")
                        count += 1
                    }
                    if queryItem.name == "email", let email = queryItem.value {
                        print("Email: \(email)")
                        UserDefaults.standard.set(email, forKey: "userEmail")
                        count += 1
                    }
                    if queryItem.name == "sub", let sub = queryItem.value {
                        print("Subscription: \(sub)")
                        UserDefaults.standard.set(sub, forKey: "userSubscription")
                        count += 1
                    }
                }
            }
            if count == 3 {
                _ = launchAppFromBrowser(NSApplication.shared, hasVisibleWindows: false)
            }else{
                NSAlert.popError("Failed Log in. Invalid Launch URL. Please try again.")
            }
        }
    
    func applicationDidFinishLaunching(_: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rebuildApplicationWindows),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSApp.setActivationPolicy(.accessory)

        _ = EventMonitors.shared
        let timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            self?.determineIfProcessIdentifierMatches()
            self?.makeKeyAndVisibleIfNeeded()
        }
        self.timer = timer

        rebuildApplicationWindows()
    }

    func applicationWillTerminate(_: Notification) {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func findScreenFitsOurNeeds() -> NSScreen? {
        if let screen = NSScreen.buildin, screen.notchSize != .zero { return screen }
        return .main
    }

    @objc func rebuildApplicationWindows() {
        defer { isFirstOpen = false }
        if let mainWindowController {
            mainWindowController.destroy()
        }
        mainWindowController = nil
        guard let mainScreen = findScreenFitsOurNeeds() else { return }
        mainWindowController = .init(screen: mainScreen)
        if isFirstOpen { mainWindowController?.openAfterCreate = true }
    }

    func determineIfProcessIdentifierMatches() {
        let pid = String(NSRunningApplication.current.processIdentifier)
        let content = (try? String(contentsOf: pidFile)) ?? ""
        guard pid.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        else {
            NSApp.terminate(nil)
            return
        }
    }

    func makeKeyAndVisibleIfNeeded() {
        guard let controller = mainWindowController,
              let window = controller.window,
              let vm = controller.vm,
              vm.status == .opened
        else { return }
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        guard let controller = mainWindowController,
              let vm = controller.vm
        else { return true }
        
        vm.notchOpen(.click)
        return true
    }
    
    func launchAppFromBrowser(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        guard let controller = mainWindowController,
              let vm = controller.vm
        else { return true }
        
        vm.notchOpen(.click)
        vm.detectAccount()
        return true
    }
    


}
