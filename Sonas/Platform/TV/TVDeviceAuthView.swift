import SwiftUI

// MARK: - TVDeviceAuthView (T013)

struct TVDeviceAuthView: View {
    let userCode: String
    let verificationURL: String
    var isPolling: Bool = false

    var body: some View {
        VStack(spacing: 48) {
            Text("Connect Google Calendar")
                .font(.title)
                .foregroundStyle(.primary)

            VStack(spacing: 16) {
                Text("On your phone or computer, go to:")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(verificationURL)
                    .font(.headline)
                    .foregroundStyle(.blue)

                Text("Then enter this code:")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(userCode)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            }

            if isPolling {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Waiting for authorisation…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: 700)
        .padding(64)
    }
}
