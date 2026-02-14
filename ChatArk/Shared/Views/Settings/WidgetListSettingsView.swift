import SwiftUI

struct WidgetListSettingsView: View {
    @State private var workspaces: [Workspace] = []
    @State private var widgetsByWorkspace: [UUID: [WorkspaceWidget]] = [:]
    @State private var isLoading = true
    @State private var error: String?

    private let workspaceService = WorkspaceService()

    var body: some View {
        Form {
            if isLoading {
                Section {
                    ProgressView()
                }
            } else if workspaces.isEmpty {
                Section {
                    Text("No workspaces found")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(workspaces) { workspace in
                    Section(workspace.name) {
                        let widgets = widgetsByWorkspace[workspace.id] ?? []
                        if widgets.isEmpty {
                            Text("No widgets")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(widgets) { widget in
                                NavigationLink {
                                    WidgetDetailView(widget: widget, workspaceId: workspace.id)
                                } label: {
                                    HStack {
                                        Image(systemName: "widget.small")
                                            .foregroundStyle(NauticalTheme.ocean)
                                        VStack(alignment: .leading) {
                                            Text(widget.name)
                                                .font(.body)
                                            HStack(spacing: 6) {
                                                Text(widget.isActive == true ? "Active" : "Inactive")
                                                    .font(.caption)
                                                    .foregroundStyle(widget.isActive == true ? .green : .secondary)
                                                if let position = widget.position {
                                                    Text(position)
                                                        .font(.caption)
                                                        .foregroundStyle(.tertiary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if let error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Widgets")
        .task {
            await loadAllWidgets()
        }
    }

    private func loadAllWidgets() async {
        isLoading = true
        defer { isLoading = false }
        do {
            workspaces = try await workspaceService.fetchWorkspaces()
            for workspace in workspaces {
                let widgets = try await workspaceService.fetchWidgets(workspaceId: workspace.id)
                widgetsByWorkspace[workspace.id] = widgets
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WidgetListSettingsView()
    }
}
#endif
