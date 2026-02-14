import SwiftUI

struct MetMuseumCardView: View {
    let item: MetMuseumItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageURL = item.primaryImageSmall, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text(item.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)

            if let artist = item.artistDisplayName, !artist.isEmpty {
                Text(artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if let date = item.objectDate, !date.isEmpty {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if let culture = item.culture, !culture.isEmpty {
                    Text(culture)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(width: 160)
        .padding(10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }
}

struct EuropeanaCardView: View {
    let item: EuropeanaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let preview = item.edmPreview?.first, let url = URL(string: preview) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text(item.title?.first ?? "Untitled")
                .font(.subheadline.weight(.medium))
                .lineLimit(2)

            if let creator = item.dcCreator?.first {
                Text(creator)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let year = item.year?.first {
                Text(year)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 160)
        .padding(10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }
}
