import SwiftUI

struct AnalyzingOverlayView: View {
    let scan: PatternScan
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            Color.clear
                .frame(width: 56, height: 56)
                .overlay {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle().fill(.quaternary)
                    }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("Analyzing Pattern")
                    .font(CipherStyle.Fonts.body(15, weight: .semibold))
                    .foregroundStyle(CipherStyle.Colors.primaryText)

                Text(scan.analysisStage ?? "Preparing...")
                    .font(CipherStyle.Fonts.body(13))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: scan.analysisStage)
            }

            Spacer()

            // Spinner
            ProgressView()
                .tint(CipherStyle.Colors.primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .task {
            thumbnail = await ImageStorageService.shared.loadImage(fileName: scan.imageFileName)
        }
    }
}
