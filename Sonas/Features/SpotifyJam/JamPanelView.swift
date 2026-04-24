import CoreImage.CIFilterBuiltins
import SwiftUI

// MARK: - JamPanelView (T074)

struct JamPanelView: View {
    @State var viewModel: JamViewModel

    var body: some View {
        PanelView(title: "Spotify Jam", icon: Icon.jam) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isSpotifyInstalled {
            installSpotifyPrompt
        } else if !viewModel.isSpotifyConnected {
            connectSpotifyPrompt
        } else {
            switch viewModel.status {
            case .none, .ended:
                startJamButton
            case .active:
                activeJamView
            case .ending:
                LoadingStateView(rows: 1)
            }
        }

        if let error = viewModel.error {
            Text(error.message)
                .font(.caption)
                .foregroundStyle(Color.errorRed)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    // MARK: - Start button

    private var startJamButton: some View {
        Button {
            Task { await viewModel.startJam() }
        } label: {
            Label("Start Jam", systemImage: Icon.spotifyPlay)
                .font(.buttonLabel)
                .foregroundStyle(Color.accent)
                .frame(maxWidth: .infinity)
        }
        .disabled(viewModel.isLoading)
        .padding(.vertical, 16)
        .accessibilityInfo("Start Jam", hint: "Start a Spotify Group Session and show a QR code")
        .accessibilityIdentifier("StartJamButton")
    }

    // MARK: - Active Jam (QR code + end button)

    private var activeJamView: some View {
        VStack(spacing: 16) {
            if let session = viewModel.session, let qrImage = generateQR(from: session.joinURL) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .accessibilityLabel("Spotify Jam QR code — scan to join")
                    .accessibilityIdentifier("JamQRCode")

                Text("Scan to join the Jam")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryLabel)
            }

            Button {
                Task { await viewModel.endJam() }
            } label: {
                Label("End Jam", systemImage: Icon.spotifyStop)
                    .font(.buttonLabel)
                    .foregroundStyle(Color.errorRed)
            }
            .disabled(viewModel.isLoading)
            .accessibilityInfo("End Jam", hint: "Stop the Spotify Group Session and remove the QR code")
        }
        .padding(.vertical, 8)
    }

    // MARK: - Prompts

    private var connectSpotifyPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: Icon.connect)
                .font(.title2)
                .foregroundStyle(Color.secondaryLabel)
                .accessibilityHidden(true)
            Text("Connect Spotify")
                .font(.headline)
                .foregroundStyle(Color.panelForeground)
            Button("Connect") {
                Task { await viewModel.connectSpotify() }
            }
            .font(.buttonLabel)
            .foregroundStyle(Color.accent)
            .accessibilityInfo("Connect Spotify", hint: "Sign in with your Spotify account")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var installSpotifyPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: Icon.install)
                .font(.title2)
                .foregroundStyle(Color.secondaryLabel)
                .accessibilityHidden(true)
            Text("Install Spotify to use Jam")
                .font(.caption)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("Get Spotify") {
                if let url = URL(string: "https://apps.apple.com/app/spotify-music-and-podcasts/id324684580") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.buttonLabel)
            .foregroundStyle(Color.accent)
            .accessibilityInfo("Get Spotify", hint: "Open App Store to install Spotify")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - QR generation (CoreImage)

    private func generateQR(from url: URL) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        // Convert to CGImage in sRGB color space to ensure components stay in [0, 1]
        // range and avoid UIColor out-of-range warnings on modern displays.
        guard let cgImage = context.createCGImage(
            scaledImage,
            from: scaledImage.extent
        ) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
