import SwiftUI

/// Human-readable error display used inside panels when data cannot be loaded.
/// All error messages MUST route through this view to guarantee consistent copy (Constitution §III).
struct ErrorStateView: View {
    let error: PanelError
    let onRetry: (() -> Void)?

    init(error: PanelError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: Icon.error)
                .font(.title2)
                .foregroundStyle(Color.errorRed)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(error.title)
                    .font(.headline)
                    .foregroundStyle(Color.panelForeground)
                    .multilineTextAlignment(.center)

                Text(error.message)
                    .font(.caption)
                    .foregroundStyle(Color.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            if error.isRetryable, let onRetry {
                Button(action: onRetry) {
                    Label("Try Again", systemImage: Icon.retry)
                        .font(.buttonLabel)
                        .foregroundStyle(Color.accent)
                }
                .accessibilityInfo("Try Again", hint: "Attempt to reload this panel")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .accessibilityError("Panel", message: "\(error.title): \(error.message)")
    }
}
