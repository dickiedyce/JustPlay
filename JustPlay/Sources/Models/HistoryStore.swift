import Foundation

struct HistoryStore {
    private(set) var items: [URL]
    private let retentionLimit: Int

    init(initial: [URL] = [], retentionLimit: Int) {
        self.items = initial
        self.retentionLimit = max(1, retentionLimit)
        self.items = trimmed(to: self.retentionLimit)
    }

    mutating func record(url: URL) {
        items.removeAll { $0 == url }
        items.insert(url, at: 0)
        items = trimmed(to: retentionLimit)
    }

    mutating func replace(with urls: [URL]) {
        items = urls
        items = trimmed(to: retentionLimit)
    }

    mutating func clear() {
        items.removeAll()
    }

    func trimmed(to limit: Int) -> [URL] {
        Array(items.prefix(max(1, limit)))
    }
}
