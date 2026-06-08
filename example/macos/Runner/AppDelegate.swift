import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Run as a menu-bar-only app — no Dock icon, no App Switcher entry.
    NSApp.setActivationPolicy(.accessory)
    super.applicationDidFinishLaunching(notification)
  }

  // Keep the app alive when the popover window is hidden.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
