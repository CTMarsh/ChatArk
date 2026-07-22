import SwiftUI

struct WidgetManagementView: View {
    @Bindable var viewModel: WorkspaceViewModel
    @State private var showCreateWidget = false
    @State private var newWidgetName = ""
    @State private var showDeleteConfirm: WorkspaceWidget?
    @State private var showRegenerateConfirm: WorkspaceWidget?
    @State private var copiedTokenId: UUID?

    var body: some View {
        Form {
            widgetListSection
        }
        .navigationTitle("Widgets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newWidgetName = ""
                    showCreateWidget = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Create Widget", isPresented: $showCreateWidget) {
            TextField("Widget Name", text: $newWidgetName)
            Button("Create") {
                Task { await viewModel.createWidget(name: newWidgetName) }
            }
            .disabled(newWidgetName.trimmingCharacters(in: .whitespaces).isEmpty)
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete Widget",
            isPresented: Binding(
                get: { showDeleteConfirm != nil },
                set: { if !$0 { showDeleteConfirm = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let widget = showDeleteConfirm {
                    Task { await viewModel.deleteWidget(widget) }
                }
            }
        } message: {
            Text("This will permanently delete the widget and invalidate its embed token.")
        }
        .confirmationDialog(
            "Regenerate Token",
            isPresented: Binding(
                get: { showRegenerateConfirm != nil },
                set: { if !$0 { showRegenerateConfirm = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Regenerate", role: .destructive) {
                if let widget = showRegenerateConfirm {
                    Task { _ = await viewModel.regenerateWidgetToken(widget) }
                }
            }
        } message: {
            Text("This will invalidate the current embed token. Any existing widget embeds will stop working until updated.")
        }
    }

    // MARK: - Widget List

    private var widgetListSection: some View {
        Section {
            if viewModel.widgets.isEmpty {
                Text("No widgets configured")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.widgets) { widget in
                    widgetRow(widget)
                }
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private func widgetRow(_ widget: WorkspaceWidget) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "widget.small")
                    .foregroundStyle(ConstellationTheme.primary)
                Text(widget.name)
                    .fontWeight(.medium)
                Spacer()
                if widget.isActive == true {
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let token = widget.embedToken {
                HStack {
                    Text(String(token.prefix(16)) + "...")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        #if os(iOS) || os(visionOS)
                        UIPasteboard.general.string = token
                        #elseif os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(token, forType: .string)
                        #endif
                        copiedTokenId = widget.id
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            if copiedTokenId == widget.id {
                                copiedTokenId = nil
                            }
                        }
                    } label: {
                        Text(copiedTokenId == widget.id ? "Copied" : "Copy")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            HStack(spacing: 16) {
                Button("Regenerate Token") {
                    showRegenerateConfirm = widget
                }
                .font(.caption)

                Spacer()

                Button(role: .destructive) {
                    showDeleteConfirm = widget
                } label: {
                    Text("Delete")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WidgetManagementView(viewModel: WorkspaceViewModel())
    }
}
#endif
