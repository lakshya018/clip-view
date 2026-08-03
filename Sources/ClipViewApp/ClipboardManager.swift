import AppKit
import SwiftUI

enum ClipboardFilter: String, CaseIterable {
    case all = "All"
    case text = "Text"
    case images = "Images"
}

class ClipboardManager: ObservableObject {
    private let maxPinnedItems = 5
    private let storageKey = "clipboard_items"
    private let saveQueue = DispatchQueue(label: "ClipViewApp.ClipboardSaveQueue", qos: .utility)
    private var pendingSaveWorkItem: DispatchWorkItem?

    func removeItem(_ item: ClipboardItem) {
        items.removeAll{ $0.id == item.id }
        scheduleSaveItems()
    }

    @Published var items: [ClipboardItem] = []

    init() {
        loadItems()
    }

    func addItem(_ item: ClipboardItem) {
        if items.contains(item) { return }
        let newItem = item
        items.insert(newItem, at: 0)
        sortItems()
        applyHistoryLimit()
        scheduleSaveItems()
    }

    func clearAllItems() {
        items.removeAll()
        scheduleSaveItems()
    }

    @discardableResult
    func togglePin(for item: ClipboardItem) -> Bool {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let wasPinned = items[index].isPinned
            if wasPinned {
                items[index].isPinned.toggle()
            } else {
                let pinnedCount = items.filter(\.isPinned).count
                if pinnedCount >= maxPinnedItems {
                    return false
                }
                items[index].isPinned.toggle()
            }
            sortItems()
            scheduleSaveItems()
            return true
        }
        return false
    }

    func filteredItems(searchText: String, filter: ClipboardFilter) -> [ClipboardItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return items.filter { item in
            let matchesText: Bool
            if query.isEmpty {
                matchesText = true
            } else if item.type == "text" {
                matchesText = (item.normalizedText ?? "").contains(query)
            } else {
                matchesText = false
            }

            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .text:
                matchesFilter = item.type == "text"
            case .images:
                matchesFilter = item.type == "image"
            }

            return matchesText && matchesFilter
        }
    }

    private func sortItems() {
        items.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.timestamp > rhs.timestamp
        }
    }

    private func applyHistoryLimit() {
        let limit = AppPreferences.shared.historyLimit
        if items.count > limit {
            items = Array(items.prefix(limit))
        }
    }

    private func scheduleSaveItems() {
        let snapshot = items
        pendingSaveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [storageKey] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            UserDefaults.standard.set(data, forKey: storageKey)
        }

        pendingSaveWorkItem = workItem
        saveQueue.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        items = saved
        sortItems()
    }
}