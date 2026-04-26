import SwiftUI

/// The root navigation shell for iPad regular width layout.
/// Uses NavigationSplitView with a sidebar for section navigation.
struct IPadShell: View {
    @SceneStorage("selectedSection") private var selectedSection: AppSection?

    // Shared ViewModels for all panels to ensure consistency across detail views
    @State private var dashboardVM = DashboardViewModel.makeDefault()
    @State private var weatherVM = WeatherViewModel.makeDefault()
    @State private var tasksVM = TasksViewModel.makeDefault()
    @State private var photoVM = PhotoViewModel.makeDefault()
    @State private var jamVM = JamViewModel.makeDefault()

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selectedSection,
                tasksVM: tasksVM,
                eventsVM: dashboardVM.eventsVM,
                jamVM: jamVM,
                photoVM: photoVM
            )
        } detail: {
            NavigationStack {
                detailView(for: selectedSection ?? .dashboard)
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

    private func panelDetail(title: String, @ViewBuilder content: () -> some View) -> some View {
        ScrollView {
            content()
                .padding()
        }
        .navigationTitle(title)
        .background(Color.dashboardBackground.ignoresSafeArea())
    }
}
