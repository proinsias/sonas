import SwiftUI

// MARK: - DashboardView (T041 + T093 toolbar button)

// US1: single-column iPhone layout hosting ClockPanelView, LocationPanelView, EventsPanelView.
// Additional panels (Weather T052, Tasks T060, Photos T068, Jam T076) are integrated in their
// respective tasks. DashboardView changes MUST be serialised to avoid merge conflicts
// (see tasks.md Notes — T041, T052, T060, T068, T076, T077, T093).

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var weatherVM: WeatherViewModel
    @State private var tasksVM: TasksViewModel
    @State private var photoVM: PhotoViewModel
    @State private var jamVM: JamViewModel

    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass

    init(
        viewModel: DashboardViewModel = DashboardViewModel.makeDefault(),
        weatherVM: WeatherViewModel = WeatherViewModel.makeDefault(),
        tasksVM: TasksViewModel = TasksViewModel.makeDefault(),
        photoVM: PhotoViewModel = PhotoViewModel.makeDefault(),
        jamVM: JamViewModel = JamViewModel.makeDefault()
    ) {
        _viewModel = State(initialValue: viewModel)
        _weatherVM = State(initialValue: weatherVM)
        _tasksVM = State(initialValue: tasksVM)
        _photoVM = State(initialValue: photoVM)
        _jamVM = State(initialValue: jamVM)
    }

    var body: some View {
        if hSizeClass == .regular {
            // iPad Regular Width: Content is hosted in NavigationSplitView detail column
            dashboardContent
                .navigationTitle("Sonas")
                .onReceive(NotificationCenter.default.publisher(for: .sonasRefreshRequested)) { _ in
                    Task { await viewModel.refreshAll() }
                }
        } else {
            // iPhone / iPad Compact Width: Use standard NavigationStack and TabBar
            NavigationStack {
                dashboardContent
                    .navigationTitle("Sonas")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                viewModel.showSettings()
                            } label: {
                                Image(systemName: Icon.settings)
                            }
                            .accessibilityInfo("Settings", hint: "Open app settings")
                        }
                    }
                    .sheet(isPresented: Binding(
                        get: { viewModel.isShowingSettings },
                        set: { if !$0 { viewModel.hideSettings() } },
                    )) {
                        SettingsView(tasksVM: tasksVM, eventsVM: viewModel.eventsVM, jamVM: jamVM, photoVM: photoVM)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .sonasRefreshRequested)) { _ in
                        Task { await viewModel.refreshAll() }
                    }
            }
            .background(Color.dashboardBackground.ignoresSafeArea())
        }
    }

    // MARK: - Adaptive layout (T077)

    @ViewBuilder
    private var dashboardContent: some View {
        switch (hSizeClass, vSizeClass) {
        case (.regular, .regular):
            // iPad / Mac — 3-column grid (research.md §Decision 8)
            threeColumnLayout
        case (.regular, .compact):
            // iPhone landscape — 2-column
            twoColumnLayout
        default:
            // iPhone portrait — single column
            singleColumnLayout
        }
    }

    // MARK: - Three-column grid (iPad / Mac)

    private var threeColumnLayout: some View {
        ScrollView {
            LazyVGrid(
                columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())],
                spacing: 24,
            ) {
                ClockPanelView()
                LocationPanelView(viewModel: viewModel.locationVM).accessibilityIdentifier("LocationPanel")
                EventsPanelView(viewModel: viewModel.eventsVM).accessibilityIdentifier("EventsPanel")
                WeatherPanelView(viewModel: weatherVM).accessibilityIdentifier("WeatherPanel")
                PhotoGalleryView(viewModel: photoVM).accessibilityIdentifier("PhotosPanel")
                TasksPanelView(viewModel: tasksVM).accessibilityIdentifier("TasksPanel")
                JamPanelView(viewModel: jamVM).gridCellColumns(2).accessibilityIdentifier("JamPanel")
            }
            .padding(16)
        }
    }

    // MARK: - Two-column (iPhone landscape)

    private var twoColumnLayout: some View {
        ScrollView {
            LazyVGrid(
                columns: [.init(.flexible()), .init(.flexible())],
                spacing: 24,
            ) {
                ClockPanelView()
                LocationPanelView(viewModel: viewModel.locationVM)
                EventsPanelView(viewModel: viewModel.eventsVM)
                WeatherPanelView(viewModel: weatherVM)
                PhotoGalleryView(viewModel: photoVM)
                TasksPanelView(viewModel: tasksVM)
                JamPanelView(viewModel: jamVM).gridCellColumns(2)
            }
            .padding(16)
        }
    }

    // MARK: - Single-column (iPhone portrait — US1)

    private var singleColumnLayout: some View {
        RefreshableScrollView {
            await viewModel.refreshAll()
        } content: {
            VStack(spacing: 16) {
                ClockPanelView()

                LocationPanelView(viewModel: viewModel.locationVM)
                    .accessibilityIdentifier("LocationPanel")

                EventsPanelView(viewModel: viewModel.eventsVM)
                    .accessibilityIdentifier("EventsPanel")

                WeatherPanelView(viewModel: weatherVM)
                    .accessibilityIdentifier("WeatherPanel")

                TasksPanelView(viewModel: tasksVM)
                    .accessibilityIdentifier("TasksPanel")

                PhotoGalleryView(viewModel: photoVM)
                    .accessibilityIdentifier("PhotosPanel")

                JamPanelView(viewModel: jamVM)
                    .accessibilityIdentifier("JamPanel")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
