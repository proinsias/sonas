import CoreLocation
import SwiftUI

extension View {
    /// Applies a system-standard highlight hover effect.
    /// No-op on non-pointer devices.
    func panelHoverEffect() -> some View {
        hoverEffect(.highlight)
    }

    /// Adds a location card context menu: Get Directions, Copy Location, Open in Maps.
    func locationCardContextMenu(
        memberName _: String,
        coordinate: CLLocationCoordinate2D?
    ) -> some View {
        contextMenu {
            if let coordinate {
                Button {
                    let urlString = "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)"
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle")
                }

                Button {
                    let urlString = "http://maps.apple.com/?q=\(coordinate.latitude),\(coordinate.longitude)"
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open in Maps", systemImage: "map")
                }

                Button {
                    let lat = String(format: "%.5f", coordinate.latitude)
                    let lon = String(format: "%.5f", coordinate.longitude)
                    UIPasteboard.general.string = "\(lat), \(lon)"
                } label: {
                    Label("Copy Location", systemImage: "doc.on.doc")
                }
            }
        }
    }

    /// Adds an event row context menu: Copy Event Title, Add Reminder.
    func eventRowContextMenu(event: CalendarEvent) -> some View {
        contextMenu {
            Button {
                UIPasteboard.general.string = event.title
            } label: {
                Label("Copy Event Title", systemImage: "doc.on.doc")
            }

            Button {
                // Opens the Reminders app. In a full implementation, this might pre-fill a reminder.
                if let url = URL(string: "x-apple-reminder://") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Add Reminder", systemImage: "bell")
            }
        }
    }
}
