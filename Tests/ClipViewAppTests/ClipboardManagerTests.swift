import XCTest
@testable import ClipViewApp

final class ClipboardManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "clipboard_items")
        UserDefaults.standard.removeObject(forKey: "app_preferences_history_limit")
    }

    func testFilteringItemsBySearchText() {
        let manager = ClipboardManager()
        manager.addItem(ClipboardItem(text: "Alpha entry"))
        manager.addItem(ClipboardItem(text: "Beta entry"))
        manager.addItem(ClipboardItem(text: "Gamma"))

        let filtered = manager.filteredItems(searchText: "alpha", filter: .all)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.contentText, "Alpha entry")
    }

    func testFilteringItemsByType() {
        let manager = ClipboardManager()
        manager.addItem(ClipboardItem(text: "Text entry"))
        manager.addItem(ClipboardItem(imageData: Data([0x00, 0x01, 0x02, 0x03])))

        let filtered = manager.filteredItems(searchText: "", filter: .images)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.type, "image")
    }

    func testPinnedItemsAppearFirst() {
        let manager = ClipboardManager()
        let first = ClipboardItem(text: "First entry")
        let second = ClipboardItem(text: "Second entry")
        manager.addItem(first)
        manager.addItem(second)

        manager.togglePin(for: second)
        let filtered = manager.filteredItems(searchText: "", filter: .all)

        XCTAssertEqual(filtered.first?.id, second.id)
        XCTAssertTrue(filtered.first?.isPinned == true)
    }

    func testPreferencesDefaultHistoryLimit() {
        XCTAssertEqual(AppPreferences.shared.historyLimit, 20)
    }

    func testPreferencesPersistHistoryLimit() {
        let preferences = AppPreferences.shared
        preferences.historyLimit = 42
        XCTAssertEqual(preferences.historyLimit, 42)
    }

    func testPinnedItemsStayBeforeUnpinnedAfterNewEntry() {
        let manager = ClipboardManager()
        let pinned = ClipboardItem(text: "Pinned")
        let unpinned = ClipboardItem(text: "Recent")

        manager.addItem(pinned)
        manager.togglePin(for: pinned)
        manager.addItem(unpinned)

        let ordered = manager.items
        XCTAssertEqual(ordered.first?.id, pinned.id)
        XCTAssertEqual(ordered.last?.id, unpinned.id)
    }
}
