@testable import Sonas
import SwiftUI
import Testing

@Suite("AppSection Unit Tests")
struct AppSectionTests {
    @Test
    func `all AppSection cases have valid metadata`() {
        for section in AppSection.allCases {
            #expect(!section.id.isEmpty)
            #expect(!section.title.isEmpty)
            #expect(!section.systemImage.isEmpty)
            #expect(section.keyboardShortcut != nil)
        }
    }

    @Test
    func `appSection default is dashboard`() {
        #expect(AppSection.dashboard.id == "dashboard")
    }

    @Test
    func `appSection shortcut mapping is correct`() {
        #expect(AppSection.dashboard.keyboardShortcut?.key == "1")
        #expect(AppSection.location.keyboardShortcut?.key == "2")
        #expect(AppSection.calendar.keyboardShortcut?.key == "3")
        #expect(AppSection.weather.keyboardShortcut?.key == "4")
        #expect(AppSection.tasks.keyboardShortcut?.key == "5")
        #expect(AppSection.photos.keyboardShortcut?.key == "6")
        #expect(AppSection.jam.keyboardShortcut?.key == "7")
        #expect(AppSection.settings.keyboardShortcut?.key == ",")
    }

    @Test
    func `appSection titles are unique`() {
        let titles = AppSection.allCases.map(\.title)
        #expect(Set(titles).count == titles.count)
    }
}
