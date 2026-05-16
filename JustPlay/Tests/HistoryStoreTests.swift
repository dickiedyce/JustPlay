import XCTest
@testable import JustPlay

final class HistoryStoreTests: XCTestCase {
    func testRecordMovesDuplicateToFront() {
        let a = URL(fileURLWithPath: "/tmp/a.mp3")
        let b = URL(fileURLWithPath: "/tmp/b.mp3")
        var store = HistoryStore(initial: [a, b], retentionLimit: 5)

        store.record(url: b)

        XCTAssertEqual(store.items, [b, a])
    }

    func testRecordRespectsRetentionLimit() {
        let a = URL(fileURLWithPath: "/tmp/a.mp3")
        let b = URL(fileURLWithPath: "/tmp/b.mp3")
        let c = URL(fileURLWithPath: "/tmp/c.mp3")
        var store = HistoryStore(initial: [a, b], retentionLimit: 2)

        store.record(url: c)

        XCTAssertEqual(store.items, [c, a])
    }

    func testClearRemovesAllItems() {
        let a = URL(fileURLWithPath: "/tmp/a.mp3")
        var store = HistoryStore(initial: [a], retentionLimit: 3)

        store.clear()

        XCTAssertTrue(store.items.isEmpty)
    }
}
