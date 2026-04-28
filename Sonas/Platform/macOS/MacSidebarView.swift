import SwiftUI

struct MacSidebarView: View {
    @Binding var selection: AppSection?
    @State private var showingSettings = false

    // Dependencies for SettingsView
    let tasksVM: TasksViewModel
    let eventsVM: EventsViewModel
    let jamVM: JamViewModel
    let photoVM: PhotoViewModel

    var body: some View {
        List(selection: $selection) {
            ForEach(AppSection.allCases.filter { $0 != .settings }) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.systemImage)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Sonas")
        .safeAreaInset(edge: .bottom) {
            Button {
                showingSettings = true
            } label: {
                Label(AppSection.settings.title, systemImage: AppSection.settings.systemImage)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(tasksVM: tasksVM, eventsVM: eventsVM, jamVM: jamVM, photoVM: photoVM)
        }
    }
}
