import SwiftUI

// MARK: - TVDashboardView (T079)
// Lean-back full-screen layout for Apple TV.
// Passive display only — no task completion or Jam initiation (spec assumption).
// Focus engine navigation via .focusable() on all panels.

struct TVDashboardView: View {

    @State private var viewModel = DashboardViewModel.makeDefault()
    @State private var weatherVM = WeatherViewModel.makeDefault()

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: .init(.flexible(), spacing: 20), count: 3),
            spacing: 20
        ) {
            ClockPanelView()
                .focusable()

            LocationPanelView(viewModel: viewModel.locationVM)
                .focusable()
                .accessibilityIdentifier("LocationPanel")

            EventsPanelView(viewModel: viewModel.eventsVM)
                .focusable()
                .accessibilityIdentifier("EventsPanel")

            WeatherPanelView(viewModel: weatherVM)
                .focusable()
                .accessibilityIdentifier("WeatherPanel")
        }
        .padding(40)
        .background(Color.dashboardBackground.ignoresSafeArea())
        .task {
            await viewModel.locationVM.start()
            await viewModel.eventsVM.load()
            await weatherVM.start()
        }
    }
}
