import AppKit
import Foundation

class ClipboardMonitor {
    private static var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount;
    private let manager: ClipboardManager

    init(manager: ClipboardManager) {
        self.manager = manager
        startMonitoring()
    }

    private func startMonitoring() {
        Self.timer = Timer(timeInterval: 1.0, repeats: true) {[weak self] _ in
            self?.checkClipboard()
        }
        if let timer = Self.timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let types = pasteboard.types, types.contains(.string),
           let text = pasteboard.string(forType: .string)
        {
            let item = ClipboardItem(text: text)
            DispatchQueue.main.async {
                self.manager.addItem(item)
            }
        } else if let types = pasteboard.types, types.contains(.tiff),
           let data = pasteboard.data(forType: .tiff)
        {
            let item = ClipboardItem(imageData: data)
            DispatchQueue.main.async {
                self.manager.addItem(item)
            }
        }
    }

}