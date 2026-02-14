import SwiftUI
import PhotosUI

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if let image = viewModel.capturedImage {
                    capturedImageView(image)
                } else {
                    captureOptionsView
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Capture Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if viewModel.capturedImage != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Retake") {
                            viewModel.reset()
                        }
                    }
                }
            }
            .onChange(of: viewModel.selectedPhotoItem) {
                Task { await viewModel.processSelectedPhoto() }
            }
            .fullScreenCover(isPresented: $viewModel.showCamera) {
                CameraView(image: $viewModel.capturedImage)
            }
            .disabled(viewModel.isProcessing)
            .overlay {
                if viewModel.isProcessing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Processing...")
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                }
            }
        }
    }

    private func capturedImageView(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)

            Button {
                Task {
                    if await viewModel.startAnalysis(
                        image: image, modelContext: modelContext
                    ) != nil {
                        dismiss()
                    }
                }
            } label: {
                Label("Analyze Pattern", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var captureOptionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            Text("Capture a textile pattern")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images
                ) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    viewModel.showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
        }
    }
}
