import MapKit
import SwiftUI

// MARK: - Location Detail (T023)

struct TVLocationDetailView: View {
    let vm: LocationViewModel
    @State private var position: MapCameraPosition = .automatic

    private var membersWithLocation: [FamilyMember] {
        vm.members.filter { $0.location != nil }
    }

    var body: some View {
        HStack(spacing: 0) {
            Map(position: $position) {
                ForEach(membersWithLocation) { member in
                    if let loc = member.location {
                        Marker(member.displayName, coordinate: loc.coordinate)
                    }
                }
            }
            .mapStyle(.standard)
            .frame(maxWidth: .infinity)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.members) { member in
                        TVMemberRow(member: member)
                    }
                }
                .padding(32)
            }
            .frame(width: 460)
            .background(Color.panelBackground)
        }
        .ignoresSafeArea(edges: .all)
    }
}

struct TVMemberRow: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: member.isStale ? "location.slash.fill" : "location.fill")
                .font(.title2)
                .foregroundStyle(member.isStale ? .secondary : Color.accent)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.headline)
                if let loc = member.location {
                    Text(loc.ageLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text("Location unavailable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.panelBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Photo Detail (T024)

struct TVPhotoDetailView: View {
    let vm: PhotoViewModel
    @State private var selectedIndex = 0
    @State private var imageData: Data?
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: selectedIndex)
            } else {
                ProgressView()
                    .tint(.white)
            }

            if vm.photos.count > 1 {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(0 ..< min(vm.photos.count, 20), id: \.self) { idx in
                            Circle()
                                .fill(idx == selectedIndex ? Color.white : Color.white.opacity(0.35))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .focusable()
        .focused($isFocused)
        #if os(tvOS)
            .onMoveCommand { direction in
                switch direction {
                case .left: moveToPrevious()
                case .right: moveToNext()
                default: break
                }
            }
        #endif
            .task(id: selectedIndex) { await loadCurrentPhoto() }
            .onAppear { isFocused = true }
    }

    private func moveToPrevious() {
        guard selectedIndex > 0 else { return }
        selectedIndex -= 1
    }

    private func moveToNext() {
        guard selectedIndex < vm.photos.count - 1 else { return }
        selectedIndex += 1
    }

    private func loadCurrentPhoto() async {
        guard !vm.photos.isEmpty else { return }
        imageData = nil
        imageData = try? await vm.loadFullImage(for: vm.photos[selectedIndex])
    }
}

// MARK: - Jam Detail

struct TVJamDetailView: View {
    let track: TVCurrentTrack?

    var body: some View {
        VStack(spacing: 32) {
            if let track {
                Image(systemName: "music.note.list")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accent)
                Text(track.title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
                Text(track.artistName)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "music.note.slash")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                Text("Nothing Playing")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
