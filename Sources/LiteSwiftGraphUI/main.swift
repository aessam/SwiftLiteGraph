import SwiftUI
import LiteSwiftGraph
import LiteSwiftGraphDebug

@main
struct LiteSwiftGraphUIApp: App {
    @StateObject private var viewModel = GraphViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.mainWindow {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}