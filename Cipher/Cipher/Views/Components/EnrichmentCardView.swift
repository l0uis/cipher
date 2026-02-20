import SwiftUI

struct MetMuseumCardView: View {
    let item: MetMuseumItem
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let urlString = item.objectURL, let url = URL(string: urlString) {
                openURL(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                if let imageURL = item.primaryImageSmall, let url = URL(string: imageURL) {
                    Color.clear
                        .aspectRatio(4.0/3.0, contentMode: .fit)
                        .overlay {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(.white.opacity(0.04))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Text(item.title)
                    .font(CipherStyle.Fonts.body(13, weight: .semibold))
                    .foregroundStyle(CipherStyle.Colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                VStack(alignment: .leading, spacing: 2) {
                    if let date = item.objectDate, !date.isEmpty {
                        Text(date)
                            .font(CipherStyle.Fonts.body(11))
                            .foregroundStyle(.secondary)
                    }
                    if let culture = item.culture, !culture.isEmpty {
                        Text(culture)
                            .font(CipherStyle.Fonts.body(11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 180)
        }
        .buttonStyle(.plain)
    }
}

struct EuropeanaCardView: View {
    let item: EuropeanaItem
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let urlString = item.guid, let url = URL(string: urlString) {
                openURL(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                if let preview = item.edmPreview?.first, let url = URL(string: preview) {
                    Color.clear
                        .aspectRatio(4.0/3.0, contentMode: .fit)
                        .overlay {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(.white.opacity(0.04))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Text(item.title?.first ?? "Untitled")
                    .font(CipherStyle.Fonts.body(13, weight: .semibold))
                    .foregroundStyle(CipherStyle.Colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                VStack(alignment: .leading, spacing: 2) {
                    if let year = item.year?.first {
                        Text(year)
                            .font(CipherStyle.Fonts.body(11))
                            .foregroundStyle(.secondary)
                    }
                    if let provider = item.dataProvider?.first {
                        Text(provider)
                            .font(CipherStyle.Fonts.body(11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 180)
        }
        .buttonStyle(.plain)
    }
}
