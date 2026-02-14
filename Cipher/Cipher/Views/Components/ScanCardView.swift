import SwiftUI

struct ScanCardView: View {
    let scan: PatternScan
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(scan.patternName ?? statusLabel)
                    .font(.headline)
                    .lineLimit(1)

                if let origin = scan.patternOrigin {
                    Text(origin)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(scan.capturedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            statusIcon
        }
        .padding(.vertical, 4)
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

    @ViewBuilder
    private var statusIcon: some View {
        switch scan.analysisStatus {
        case "analyzing":
            ProgressView()
        case "failed":
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        case "completed":
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        default:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        }
    }
}
