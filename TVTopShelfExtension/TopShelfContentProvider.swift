import Foundation
import TVServices

// MARK: - TopShelfContentProvider (T032)

final class TopShelfContentProvider: TVTopShelfContentProvider {
    private nonisolated(unsafe) static let userDefaults = UserDefaults(suiteName: "group.com.sonas.topshelf")

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        guard let snapshot = Self.readSnapshot(), !snapshot.isStale else {
            completionHandler(nil)
            return
        }

        let photoItem = createPhotoContentItem(from: snapshot)
        let eventItem = createEventContentItem(from: snapshot)

        let collection = TVTopShelfItemCollection(items: [photoItem, eventItem])
        collection.title = "Family Dashboard"

        let content = TVTopShelfSectionedContent(sections: [collection])
        completionHandler(content)
    }

    private static func readSnapshot() -> TVTopShelfSnapshot? {
        guard let data = userDefaults?.data(forKey: "TopShelfSnapshot") else { return nil }
        return try? JSONDecoder().decode(TVTopShelfSnapshot.self, from: data)
    }
}

extension TVTopShelfSnapshot {
    var isStale: Bool {
        Calendar.current.dateComponents([.hour], from: updatedAt, to: Date()).hour ?? 0 > 6
    }
}

private extension TopShelfContentProvider {
    private func createPhotoContentItem(from snapshot: TVTopShelfSnapshot) -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: "photo")
        item.title = "Recent Photo"
        if let photoURL = snapshot.photoFileURL {
            item.setImageURL(photoURL, for: .screenScale1x)
            item.setImageURL(photoURL, for: .screenScale2x)
        }
        item.imageShape = .hdtv
        return item
    }

    private func createEventContentItem(from snapshot: TVTopShelfSnapshot) -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: "event")
        if let title = snapshot.nextEventTitle, let start = snapshot.nextEventStart {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            item.title = "\(title) (\(formatter.string(from: start)))"
        } else {
            item.title = snapshot.nextEventTitle ?? "No upcoming events"
        }
        item.imageShape = .square
        return item
    }
}
