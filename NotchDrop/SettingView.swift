import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .general
    
    var body: some View {
        NavigationView {
            List(selection: $selectedSection) {
                ForEach(SettingsSection.allCases, id: \.self) { section in
                    NavigationLink(
                        destination: settingsContent(for: section),
                        label: {
                            Text(section.rawValue)
                        }
                    )
                    .tag(section)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(width: 150) // This will now adjust the sidebar width
            .background(Color(NSColor.windowBackgroundColor))
            
            settingsContent(for: selectedSection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 600, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    func settingsContent(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            GeneralSettingsView()
        case .layout:
            LayoutSettingsView()
        case .files:
            FileSettingsView()
        }
    }
}

enum SettingsSection: String, CaseIterable {
    case general = "General"
    case layout = "Layout"
    case files = "Files"
}

struct GeneralSettingsView: View {
    var body: some View {
        VStack {
            Text("General Settings")
                .font(.title)
            // Add your general settings controls here
        }
    }
}

struct LayoutSettingsView: View {
    var body: some View {
        VStack {
            Text("Layout Settings")
                .font(.title)
            // Add your layout settings controls here
        }
    }
}

struct FileSettingsView: View {
    var body: some View {
        VStack {
            Text("File Settings")
                .font(.title)
            // Add your file settings controls here
        }
    }
}

#Preview {
    SettingsView()
}
