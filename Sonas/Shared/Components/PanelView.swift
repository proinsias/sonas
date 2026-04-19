import SwiftUI

// MARK: - Panel state

/// The loading/data/error lifecycle state for a single dashboard panel.
enum PanelState<T> {
    case loading
    case loaded(T)
    case error(PanelError)
    case stale(T, lastUpdated: Date) // Cached data shown offline with timestamp badge
}

// MARK: - PanelView

/// Base chrome wrapper for all Sonas dashboard panels.
/// Provides: title bar, loading skeleton, error state, stale-data badge, and last-updated label.
/// Usage: Wrap a panel's content in `PanelView(title:icon:) { ... }`.
struct PanelView<Content: View>: View {
    let title: String
    let icon: String
    let lastUpdated: Date?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        icon: String,
        lastUpdated: Date? = nil,
        @ViewBuilder content: @escaping () -> Content,
    ) {
        self.title = title
        self.icon = icon
        self.lastUpdated = lastUpdated
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeader
            Divider().background(Color.divider)
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .accessibilityPanel(label: title)
    }

    private var panelHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(.body, design: .default).weight(.medium))
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)

            Text(title)
                .font(.panelTitle)
                .foregroundStyle(Color.panelForeground)

            Spacer()

            if let lastUpdated {
                Text(lastUpdated, format: .relative(presentation: .named))
                    .font(.timestamp)
                    .foregroundStyle(Color.secondaryLabel)
                    .accessibilityLabel("Last updated \(lastUpdated.formatted(.relative(presentation: .named)))")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - PanelError

/// Human-readable error type surfaced in panel error states.
struct PanelError: Error, Equatable {
    let title: String
    let message: String
    let isRetryable: Bool

    static let networkUnavailable = PanelError(
        title: "No Connection",
        message: "Check your network connection and try again.",
        isRetryable: true,
    )

    static let permissionDenied = PanelError(
        title: "Permission Required",
        message: "Enable access in Settings to use this feature.",
        isRetryable: false,
    )

    static let notConfigured = PanelError(
        title: "Not Configured",
        message: "Complete setup in Settings to enable this panel.",
        isRetryable: false,
    )
}

// MARK: - Stale badge overlay modifier

extension View {
    /// Overlays a "Last updated X ago" badge with a retry button when data is stale.
    func staleDataBadge(lastUpdated: Date, onRetry: @escaping () -> Void) -> some View {
        overlay(alignment: .bottomTrailing) {
            HStack(spacing: 6) {
                Image(systemName: Icon.offline)
                    .font(.caption)
                    .accessibilityHidden(true)
                Text("Last updated \(lastUpdated, format: .relative(presentation: .named))")
                    .font(.timestamp)
                Button(action: onRetry) {
                    Image(systemName: Icon.refresh)
                        .font(.caption)
                }
                .accessibilityInfo("Retry", hint: "Refresh this panel")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(8)
        }
    }
}
