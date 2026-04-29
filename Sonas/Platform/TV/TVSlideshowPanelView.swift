import Combine
import SwiftUI

// MARK: - TVSlideshowPanelView (T026)

struct TVSlideshowPanelView: View {
    @State private var selectedIndex = 0
    @State private var imageData: Data?
    @State private var startDate = Date()

    let vm: PhotoViewModel

    private var currentIndex: Int {
        guard !vm.photos.isEmpty else { return 0 }
        let elapsed = Date().timeIntervalSince(startDate)
        return Int((elapsed / 20).truncatingRemainder(dividingBy: Double(vm.photos.count)))
    }

    var body: some View {
        PanelView(title: "Photos", icon: "photo.fill") {
            photoContent
        }
        .onReceive(Timer.publish(every: 20, on: .main, in: .common).autoconnect()) { _ in
            selectedIndex = currentIndex
        }
        .task(id: selectedIndex) {
            await loadCurrentPhoto()
        }
        .onAppear {
            startDate = Date()
        }
    }

    @ViewBuilder
    private var photoContent: some View {
        if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: selectedIndex)
        } else if vm.isLoading {
            ProgressView()
        } else {
            Text("No photos available")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

extension TVSlideshowPanelView {
    private func loadCurrentPhoto() async {
        guard !vm.photos.isEmpty else {
            imageData = nil
            return
        }
        imageData = nil
        imageData = try? await vm.loadFullImage(for: vm.photos[selectedIndex])
    }
}
