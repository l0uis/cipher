import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PatternScan.capturedAt, order: .reverse) private var scans: [PatternScan]
    @State private var viewModel = HomeViewModel()
    @State private var path = NavigationPath()
    @State private var showOverlay = false
    @State private var completedScanID: PersistentIdentifier?

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    private var analyzingScan: PatternScan? {
        scans.first { $0.analysisStatus == "analyzing" }
    }

    private var displayedScans: [PatternScan] {
        scans.filter { $0.analysisStatus != "analyzing" }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Group {
                    if displayedScans.isEmpty && analyzingScan == nil {
                        emptyStateView
                    } else {
                        scanGridView
                    }
                }

                // Mini-player overlay
                if let scan = analyzingScan {
                    AnalyzingOverlayView(scan: scan)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: analyzingScan?.persistentModelID)
            .background(CipherStyle.Colors.background.ignoresSafeArea())
            .navigationTitle("Collection")
            .toolbarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingCapture = true
                    } label: {
                        Label("Scan", systemImage: "camera.viewfinder")
                            .font(CipherStyle.Fonts.body(16))
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingCapture) {
                CameraView()
            }
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let scan = scans.first(where: { $0.persistentModelID == id }) {
                    DetailView(scan: scan)
                }
            }
            .onAppear {
                processSharedScans()
            }
            .onChange(of: scans.count) {
                processSharedScans()
            }
            .onChange(of: scans.map(\.analysisStatus)) {
                // Auto-navigate when a scan completes
                if let scan = scans.first(where: {
                    $0.analysisStatus == "completed" && $0.persistentModelID == completedScanID
                }) {
                    completedScanID = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        path.append(scan.persistentModelID)
                    }
                }
            }
            .onChange(of: analyzingScan?.persistentModelID) { _, newValue in
                if let id = newValue {
                    completedScanID = id
                }
            }
        }
    }

    private func processSharedScans() {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else { return }

        let pendingDir = container.appendingPathComponent("PendingScans")
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: pendingDir, includingPropertiesForKeys: nil
        ) else { return }

        for fileURL in files where fileURL.pathExtension == "json" {
            guard let data = try? Data(contentsOf: fileURL),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let fileName = json["imageFileName"] else { continue }

            let scan = PatternScan(imageFileName: fileName)
            scan.analysisStatus = "analyzing"
            modelContext.insert(scan)
            try? modelContext.save()

            try? FileManager.default.removeItem(at: fileURL)

            Task {
                guard let imageData = await ImageStorageService.shared.loadImageData(fileName: fileName) else {
                    scan.analysisStatus = "failed"
                    scan.errorMessage = "Could not load shared image"
                    try? modelContext.save()
                    return
                }
                await AnalysisOrchestrator.shared.performFullAnalysis(
                    imageData: imageData,
                    scan: scan,
                    modelContext: modelContext
                )
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

    private var scanGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(displayedScans) { scan in
                    NavigationLink(value: scan.persistentModelID) {
                        ScanCardView(scan: scan)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deleteScan(scan, modelContext: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, analyzingScan != nil ? 100 : 32)
        }
    }

    private func deleteScans(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteScan(scans[index], modelContext: modelContext)
        }
    }
}
