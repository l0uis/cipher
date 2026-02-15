import SwiftUI

struct CategorySectionView<Content: View>: View {
    let title: String
    let icon: String
    let summary: String?
    @ViewBuilder let content: () -> Content
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(CipherStyle.Fonts.title3)
                            .foregroundStyle(.primary)

                        if !isExpanded, let summary {
                            Text(summary)
                                .font(CipherStyle.Fonts.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                content()
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }
}

// MARK: - Content Sub-views for Each Category

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(CipherStyle.Fonts.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(CipherStyle.Fonts.subheadline)
        }
        .padding(.vertical, 2)
    }
}

struct BulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\u{2022}")
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(CipherStyle.Fonts.subheadline)
                }
            }
        }
    }
}

struct ReferenceList: View {
    let title: String
    let references: [ReferenceEntry]

    var body: some View {
        if !references.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(CipherStyle.Fonts.body(13, weight: .semibold))

                ForEach(references) { ref in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ref.title)
                            .font(CipherStyle.Fonts.body(13, weight: .medium))
                        Text(ref.description)
                            .font(CipherStyle.Fonts.caption)
                            .foregroundStyle(.secondary)
                        if !ref.source.isEmpty {
                            Text(ref.source)
                                .font(CipherStyle.Fonts.body(10))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
