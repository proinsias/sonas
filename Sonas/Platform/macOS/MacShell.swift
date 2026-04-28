import SwiftUI

struct MacShell: View {
    @Environment(MenuBarState.self) private var menuBarState
    // US5: @SceneStorage is independent per window, allowing multiple windows
    // to each have their own selected section without state bleeding.
    @SceneStorage("mac.selectedSection") private var selectedSection: AppSection?

    // Shared ViewModels for all panels
    @State private var dashboardVM = DashboardViewModel.makeDefault()
    @State private var weatherVM = WeatherViewModel.makeDefault()
    @State private var tasksVM = TasksViewModel.makeDefault()
    @State private var photoVM = PhotoViewModel.makeDefault()
    @State private var jamVM = JamViewModel.makeDefault()

    var body: some View {
        NavigationSplitView {
            MacSidebarView(
                selection: $selectedSection,
                tasksVM: tasksVM,
                eventsVM: dashboardVM.eventsVM,
                jamVM: jamVM,
                photoVM: photoVM
            )
        } detail: {
            NavigationStack {
                detailView(for: selectedSection ?? .dashboard)
                    .navigationTitle(selectedSection?.title ?? "Sonas")
                    .safeAreaInset(edge: .top) {
                        if menuBarState.isOffline {
                            offlineBanner
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                NotificationCenter.default.post(name: .sonasRefreshRequested, object: nil)
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            .help("Refresh all dashboard data")
                        }
                    }
            }
        }
        .onAppear {
            if selectedSection == nil {
                selectedSection = .dashboard
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sonasNavigationRequested)) { notification in
            if let section = notification.object as? AppSection {
                selectedSection = section
            }
        }
    }

    private var offlineBanner: some View {
        HStack {
            Spacer()
            Image(systemName: "wifi.slash")
            let since = menuBarState.lastUpdated?.formatted(.relative(presentation: .named)) ?? "unknown"
            Text("Offline — last updated \(since)")
            Spacer()
        }
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.8))
        .foregroundStyle(.black)
    }

    @ViewBuilder
    private func detailView(for section: AppSection) -> some View {
        switch section {
        case .dashboard:
            DashboardView(
                viewModel: dashboardVM,
                weatherVM: weatherVM,
                tasksVM: tasksVM,
                photoVM: photoVM,
                jamVM: jamVM
            )
        case .location:
            panelDetail(title: "Location") { LocationPanelView(viewModel: dashboardVM.locationVM) }
        case .calendar:
            panelDetail(title: "Calendar") { EventsPanelView(viewModel: dashboardVM.eventsVM) }
        case .weather:
            panelDetail(title: "Weather") { WeatherPanelView(viewModel: weatherVM) }
        case .tasks:
            panelDetail(title: "Tasks") { TasksPanelView(viewModel: tasksVM) }
        case .photos:
            panelDetail(title: "Photos") { PhotoGalleryView(viewModel: photoVM) }
        case .jam:
            panelDetail(title: "Jam") { JamPanelView(viewModel: jamVM) }
        case .settings:
            Color.dashboardBackground.ignoresSafeArea()
        }
    }

    private func panelDetail(title _: String, @ViewBuilder content: () -> some View) -> some View {
        ScrollView {
            content()
                .padding()
        }
        .background(Color.dashboardBackground.ignoresSafeArea())
    }
}
