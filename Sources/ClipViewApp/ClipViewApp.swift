import SwiftUI
import AppKit
import Cocoa
import Carbon

@main
struct ClipViewCLIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {}
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var clipboardManager = ClipboardManager()
    var clipboardMonitor: ClipboardMonitor?
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var hotKeyRef: EventHotKeyRef?
    private var outsideClickMonitor: Any?

    private func makePopoverContentViewController() -> NSViewController {
        let hosting = NSHostingController(
            rootView: ClipboardHistoryView(manager: clipboardManager) {
                self.clipboardManager.clearAllItems()
            }
        )
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor
        return hosting
    }

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Control+Option+Space global shortcut
        let keyCode = UInt32(kVK_Space) // Space key
        let modifierFlags: UInt32 = UInt32(optionKey) // Option


        clipboardMonitor = ClipboardMonitor(manager: clipboardManager)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipView")
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.appearsDisabled = false
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 340, height: 520)
        popover?.behavior = .semitransient
        popover?.delegate = self
        popover?.contentViewController = makePopoverContentViewController()

        let hotKeyID = EventHotKeyID(signature: OSType(UInt32(truncatingIfNeeded: "swft".fourCharCodeValue)),
                                     id: 1)
        RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        // Install handler
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout.size(ofValue: hotKeyID), nil, &hotKeyID)

            if hotKeyID.signature == OSType(UInt32(truncatingIfNeeded: "swft".fourCharCodeValue)) {
                // Call your function here
                NSApp.delegate?.perform(#selector(AppDelegate.showMainWindow))
            }
            return noErr
        }, 1, [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))], nil, nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopOutsideClickMonitor()
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }

    func popoverDidClose(_ notification: Notification) {
        stopOutsideClickMonitor()
        popover?.contentViewController = makePopoverContentViewController()
    }

    @objc func showMainWindow() {
        if let button = statusItem?.button {
            NSApp.activate(ignoringOtherApps: true)
            if popover?.isShown == true {
                popover?.performClose(nil)
                stopOutsideClickMonitor()
                return
            }

            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startOutsideClickMonitor()
        }
    }

    @objc func statusItemClicked(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            if let button = statusItem?.button {
                if popover?.isShown == true {
                    popover?.performClose(sender)
                    stopOutsideClickMonitor()
                } else {
                    NSApp.activate(ignoringOtherApps: true)
                    popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    startOutsideClickMonitor()
                }
            }
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func startOutsideClickMonitor() {
        stopOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return }
            guard self.popover?.isShown == true else {
                self.stopOutsideClickMonitor()
                return
            }

            if self.shouldClosePopover(for: event) {
                self.popover?.performClose(nil)
                self.stopOutsideClickMonitor()
            }
        }
    }

    private func stopOutsideClickMonitor() {
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
        }
        outsideClickMonitor = nil
    }

    private func shouldClosePopover(for event: NSEvent) -> Bool {
        guard popover?.isShown == true else { return false }

        let popoverWindow = popover?.contentViewController?.view.window
        let buttonWindow = statusItem?.button?.window
        let eventWindow = event.window

        if let eventWindow, let popoverWindow, eventWindow === popoverWindow {
            return false
        }

        if let eventWindow, let buttonWindow, eventWindow === buttonWindow {
            return false
        }

        return true
    }
}

extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        if let data = self.data(using: .macOSRoman) {
            for i in 0..<min(4, data.count) {
                result = (result << 8) + FourCharCode(data[i])
            }
        }
        return result
    }
}