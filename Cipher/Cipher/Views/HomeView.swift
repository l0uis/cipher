import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PatternScan.capturedAt, order: .reverse) private var scans: [PatternScan]
    @State private var viewModel = HomeViewModel()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if scans.isEmpty {
                    emptyStateView
                } else {
                    scanListView
                }
            }
            .navigationTitle("Cipher")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingCapture = true
                    } label: {
                        Label("Scan", systemImage: "camera.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCapture) {
                CaptureView()
            }
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let scan = scans.first(where: { $0.persistentModelID == id }) {
                    DetailView(scan: scan)
                }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Scans Yet", systemImage: "camera.viewfinder")
        } description: {
            Text("Photograph a carpet or textile pattern to discover its cultural history and meaning.")
        } actions: {
            Button("Start Scanning") {
                viewModel.showingCapture = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var scanListView: some View {
        List {
            ForEach(scans) { scan in
                NavigationLink(value: scan.persistentModelID) {
                    ScanCardView(scan: scan)
                }
            }
            .onDelete(perform: deleteScans)
        }
        .listStyle(.plain)
    }

    private func deleteScans(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteScan(scans[index], modelContext: modelContext)
        }
    }
}
