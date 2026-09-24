import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: Store

    var body: some View {
        Form {
            Picker("Screen edge", selection: $store.edge) {
                ForEach(NotchEdge.allCases) { edge in
                    Text(edge.title).tag(edge)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Open at login", isOn: Binding(get: { store.opensAtLogin }, set: { _ in store.toggleOpenAtLogin() }))

            LabeledContent("Last scan") {
                HStack {
                    Text(lastScan)
                        .foregroundStyle(.secondary)
                    Button("Rescan") { store.rescan() }
                        .disabled(store.isScanning)
                }
            }

            HStack {
                Spacer()
                Button("Quit Disko") { NSApp.terminate(nil) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
    }

    private var lastScan: String {
        if store.isScanning { return "Scanning…" }
        guard let census = store.census else { return "Never" }
        return "\(Bytes.long(census.total)) · \(census.takenAt.formatted(.relative(presentation: .named)))"
    }
}
