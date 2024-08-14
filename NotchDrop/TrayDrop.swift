import Cocoa
import Combine
import Foundation
import OrderedCollections

class TrayDrop: ObservableObject {
    static let shared = TrayDrop()

    static var keepInterval: TimeInterval {
        get {
            return UserDefaults.standard.double(forKey: "keepInterval")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "keepInterval")
        }
    }

    private init() {
        cleanExpiredFiles()
    }

    var isEmpty: Bool { items.isEmpty }

    @PublishedPersist(key: "TrayDropItems", defaultValue: .init())
    var items: OrderedSet<DropItem>

    @Published var isLoading: Int = 0
    

    func load(_ providers: [NSItemProvider]) {
        assert(!Thread.isMainThread)
        DispatchQueue.main.asyncAndWait { isLoading += 1 }
        guard let urls = providers.interfaceConvert() else {
            DispatchQueue.main.asyncAndWait { isLoading -= 1 }
            return
        }
        do {
            let items = try urls.map { try DropItem(url: $0) }
            DispatchQueue.main.async {
                items.forEach { self.items.updateOrInsert($0, at: 0) }
                self.isLoading -= 1
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading -= 1
                NSAlert.popError(error)
            }
        }
    }

    func cleanExpiredFiles() {
        var inEdit = items
        let shouldCleanItems = items.filter(\.shouldClean)
        for item in shouldCleanItems {
            inEdit.remove(item)
        }
        items = inEdit
    }

    func delete(_ item: DropItem.ID) {
        guard let item = items.first(where: { $0.id == item }) else { return }
        delete(item: item)
    }

    private func delete(item: DropItem) {
        var inEdit = items

        var url = item.storageURL
        try? FileManager.default.removeItem(at: url)

        do {
            // loops up to the main directory
            url = url.deletingLastPathComponent()
            while url.lastPathComponent != DropItem.mainDir, url != documentsDirectory {
                let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
                guard contents.isEmpty else { break }
                try FileManager.default.removeItem(at: url)
                url = url.deletingLastPathComponent()
            }
        } catch {}

        inEdit.remove(item)
        items = inEdit
    }

    func removeAll() {
        items.forEach { delete(item: $0) }
    }
}
