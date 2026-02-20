import SwiftUI
import AVFoundation
import Photos
import PhotosUI
import SwiftData

// MARK: - Camera Manager

@Observable
class CameraManager: NSObject {
    var isRunning = false
    var capturedImage: UIImage?
    var currentZoom: CGFloat = 1.0
    var lastGalleryImage: UIImage?

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var device: AVCaptureDevice?

    func configure() {
        guard !isRunning else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }

        device = camera

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }

        session.commitConfiguration()

        Task.detached(priority: .userInitiated) { [weak self] in
            self?.session.startRunning()
            await MainActor.run { self?.isRunning = true }
        }

        loadLastGalleryImage()
    }

    func stop() {
        guard isRunning else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            self?.session.stopRunning()
            await MainActor.run { self?.isRunning = false }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func toggleZoom() {
        guard let device else { return }
        let newZoom: CGFloat = currentZoom == 1.0 ? 2.0 : 1.0
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = min(newZoom, device.activeFormat.videoMaxZoomFactor)
            device.unlockForConfiguration()
            currentZoom = newZoom
        } catch {}
    }

    private func loadLastGalleryImage() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1

        let result = PHAsset.fetchAssets(with: .image, options: options)
        guard let asset = result.firstObject else { return }

        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 100, height: 100)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .fastFormat

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.lastGalleryImage = image
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

// MARK: - Camera Preview

private class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Haptic Button Style

struct HapticScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

// MARK: - Camera View

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var camera = CameraManager()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.capturedImage != nil {
                capturedImageView
            } else {
                cameraLiveView
            }
        }
        .statusBarHidden()
        .onChange(of: selectedPhotoItem) {
            Task { await processSelectedPhoto() }
        }
        .onAppear { camera.configure() }
        .onDisappear { camera.stop() }
    }

    // MARK: - Live Camera

    private var cameraLiveView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.15), in: Circle())
                }
                .buttonStyle(HapticScaleButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)

            Spacer()

            // Camera preview
            CameraPreviewView(session: camera.session)
                .aspectRatio(CipherStyle.Layout.cardAspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

            Spacer()

            // Bottom controls
            HStack(alignment: .center) {
                // Gallery button
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Group {
                        if let img = camera.lastGalleryImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 1.5)
                    )
                }
                .buttonStyle(HapticScaleButtonStyle())

                Spacer()

                // Capture button
                Button { camera.capturePhoto() } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 3)
                                .frame(width: 82, height: 82)
                        )
                }
                .buttonStyle(HapticScaleButtonStyle())

                Spacer()

                // Zoom toggle
                Button { camera.toggleZoom() } label: {
                    Text(camera.currentZoom == 1.0 ? "x1" : "x2")
                        .font(CipherStyle.Fonts.body(13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.15), in: Circle())
                }
                .buttonStyle(HapticScaleButtonStyle())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Captured Image

    private var capturedImageView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    camera.capturedImage = nil
                } label: {
                    Text("Retake")
                        .font(CipherStyle.Fonts.body(15, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.15), in: Capsule())
                }
                .buttonStyle(HapticScaleButtonStyle())

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.15), in: Circle())
                }
                .buttonStyle(HapticScaleButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)

            Spacer()

            // Captured image
            if let image = camera.capturedImage {
                Color.clear
                    .aspectRatio(CipherStyle.Layout.cardAspectRatio, contentMode: .fit)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)
            }

            Spacer()

            // Analyze button
            Button {
                Task { await analyzeImage() }
            } label: {
                Label("Analyze Pattern", systemImage: "sparkles")
                    .font(CipherStyle.Fonts.headline)
                    .foregroundStyle(CipherStyle.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CipherStyle.Colors.primaryText, in: Capsule())
            }
            .buttonStyle(HapticScaleButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .disabled(isProcessing)

            if let error = errorMessage {
                Text(error)
                    .font(CipherStyle.Fonts.caption)
                    .foregroundStyle(.red)
                    .padding(.bottom, 8)
            }
        }
        .overlay {
            if isProcessing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }
            }
        }
    }

    // MARK: - Actions

    private func processSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            guard let image = UIImage(data: data) else { return }
            camera.capturedImage = image
            camera.stop()
        } catch {
            errorMessage = "Failed to load photo"
        }
    }

    private func analyzeImage() async {
        guard let image = camera.capturedImage else { return }
        isProcessing = true
        defer { isProcessing = false }

        do {
            let fileName = try await ImageStorageService.shared.saveImage(image)
            let scan = PatternScan(imageFileName: fileName)
            scan.analysisStatus = "analyzing"
            modelContext.insert(scan)
            try modelContext.save()

            guard let imageData = await ImageStorageService.shared.loadImageData(fileName: fileName) else {
                throw ImageStorageError.compressionFailed
            }

            Task.detached {
                await AnalysisOrchestrator.shared.performFullAnalysis(
                    imageData: imageData,
                    scan: scan,
                    modelContext: modelContext
                )
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
