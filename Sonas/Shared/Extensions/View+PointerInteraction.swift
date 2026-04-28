import CoreLocation
import SwiftUI
#if os(macOS)
    import AppKit
#endif

extension View {
    /// Applies a system-standard highlight hover effect.
    /// No-op on non-pointer devices.
    func panelHoverEffect() -> some View {
        #if !os(macOS)
            hoverEffect(.highlight)
        #else
            self
        #endif
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
                        #if os(macOS)
                            NSWorkspace.shared.open(url)
                        #else
                            UIApplication.shared.open(url)
                        #endif
                    }
                } label: {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle")
                }

                Button {
                    let urlString = "http://maps.apple.com/?q=\(coordinate.latitude),\(coordinate.longitude)"
                    if let url = URL(string: urlString) {
                        #if os(macOS)
                            NSWorkspace.shared.open(url)
                        #else
                            UIApplication.shared.open(url)
                        #endif
                    }
                } label: {
                    Label("Open in Maps", systemImage: "map")
                }

                Button {
                    let lat = String(format: "%.5f", coordinate.latitude)
                    let lon = String(format: "%.5f", coordinate.longitude)
                    #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("\(lat), \(lon)", forType: .string)
                    #elseif !os(tvOS)
                        UIPasteboard.general.string = "\(lat), \(lon)"
                    #endif
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
                #if os(macOS)
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(event.title, forType: .string)
                #elseif !os(tvOS)
                    UIPasteboard.general.string = event.title
                #endif
            } label: {
                Label("Copy Event Title", systemImage: "doc.on.doc")
            }

            Button {
                // Opens the Reminders app. In a full implementation, this might pre-fill a reminder.
                if let url = URL(string: "x-apple-reminder://") {
                    #if os(macOS)
                        NSWorkspace.shared.open(url)
                    #else
                        UIApplication.shared.open(url)
                    #endif
                }
            } label: {
                Label("Add Reminder", systemImage: "bell")
            }
        }
    }
}
