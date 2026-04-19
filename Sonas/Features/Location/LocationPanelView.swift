import SwiftUI

// MARK: - LocationPanelView (T037)

struct LocationPanelView: View {
    @State var viewModel: LocationViewModel

    var body: some View {
        PanelView(title: "Family", icon: Icon.location) {
            content
        }
        .task { await viewModel.start() }
        .onDisappear { Swift.Task { await viewModel.stop() } }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingStateView(rows: 3)
        } else if let error = viewModel.error {
            ErrorStateView(error: error) {
                Swift.Task { await viewModel.refresh() }
            }
        } else if viewModel.members.isEmpty {
            permissionPrompt
        } else {
            memberList
        }
    }

    // MARK: - Member list

    private var memberList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.members) { member in
                    MemberRow(member: member)
                }
            }
        }
    }

    // MARK: - Permission prompt (no members available)

    private var permissionPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: Icon.locationUnavailable)
                .font(.title2)
                .foregroundStyle(Color.secondaryLabel)
                .accessibilityHidden(true)
            Text("Enable location in Settings")
                .font(.caption)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - MemberRow

private struct MemberRow: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(member.isStale ? Color.secondaryLabel : Color.successGreen)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.body)
                    .foregroundStyle(Color.panelForeground)

                Text(member.location?.ageLabel ?? "Location unavailable")
                    .font(.caption)
                    .foregroundStyle(member.isStale ? Color.secondaryLabel : Color.panelForeground)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.displayName): \(member.location?.ageLabel ?? "Location unavailable")")
    }
}
