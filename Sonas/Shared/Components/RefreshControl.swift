import SwiftUI

/// Pull-to-refresh SwiftUI wrapper.
/// Wraps `ScrollView` with `.refreshable` so panels can trigger manual data refresh.
struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            content()
        }
        .refreshable {
            await onRefresh()
        }
    }
}
