import SwiftUI

struct ScanCardView: View {
    let scan: PatternScan
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            Color.clear
                .aspectRatio(CipherStyle.Layout.cardAspectRatio, contentMode: .fit)
                .overlay {
                    Group {
                        if let thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(.quaternary)
                                .overlay {
                                    if scan.analysisStatus == "analyzing" {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "photo")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                        }
                    }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Title
            Text(scan.patternName ?? statusLabel)
                .font(CipherStyle.Fonts.headline)
                .foregroundStyle(CipherStyle.Colors.primaryText)
                .lineLimit(2)

            // Subline
            if let origin = scan.patternOrigin {
                Text(origin)
                    .font(CipherStyle.Fonts.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .task {
            thumbnail = await ImageStorageService.shared.loadImage(fileName: scan.imageFileName)
        }
    }

    private var statusLabel: String {
        switch scan.analysisStatus {
        case "analyzing": return "Analyzing..."
        case "failed": return "Analysis Failed"
        default: return "Pending..."
        }
    }
}
