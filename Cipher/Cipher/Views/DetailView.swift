import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let scan: PatternScan
    @State private var viewModel: DetailViewModel
    @State private var scrollOffset: CGFloat = 0

    init(scan: PatternScan) {
        self.scan = scan
        self._viewModel = State(initialValue: DetailViewModel(scan: scan))
    }

    /// Nav bar thumbnail fades in as the image scrolls off screen
    private var navThumbnailOpacity: CGFloat {
        min(max((scrollOffset - 120) / 80, 0), 1)
    }

    var body: some View {
        GeometryReader { rootGeo in
            let safeTop = rootGeo.safeAreaInsets.top

            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection(topInset: safeTop)
                            .id("top")

                        if scan.analysisStatus == "analyzing" {
                            LoadingAnalysisView()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        } else if scan.analysisStatus == "failed" {
                            errorSection
                        } else if scan.analysisStatus == "completed" {
                            analysisSections
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea()
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y
                } action: { _, newOffset in
                    scrollOffset = newOffset
                }
                .overlay(alignment: .bottom) {
                    if scrollOffset > 50 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CipherStyle.Colors.primaryText)
                                .frame(width: 44, height: 44)
                                .background(
                                    .ultraThinMaterial,
                                    in: Circle()
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        }
                        .padding(.bottom, 24)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: scrollOffset > 50)
            }
        }
        .background(CipherStyle.Colors.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let image = viewModel.scanImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .opacity(navThumbnailOpacity)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        deleteScan()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                }
            }
        }
        .task {
            await viewModel.loadImage()
            await viewModel.loadMaterialImage()
            await viewModel.loadMomentImages()
        }
        .onChange(of: scan.analysisStatus) {
            viewModel.refreshIfNeeded()
        }
    }

    private func deleteScan() {
        Task {
            await ImageStorageService.shared.deleteImage(fileName: scan.imageFileName)
        }
        modelContext.delete(scan)
        dismiss()
    }

    // MARK: - Header

    private func headerSection(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Inline image — 4:3 landscape
            Color.clear
                .aspectRatio(4.0/3.0, contentMode: .fit)
                .overlay {
                    if let image = viewModel.scanImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle().fill(.quaternary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 24)
                .padding(.top, topInset + 8)

            VStack(alignment: .leading, spacing: 14) {
                // Pattern name
                if let name = scan.patternName {
                    Text(name)
                        .font(CipherStyle.Fonts.title1)
                }

                // Infobox
                VStack(alignment: .leading, spacing: 6) {
                    if let origin = scan.patternOrigin {
                        Label(origin, systemImage: "globe.americas")
                            .font(CipherStyle.Fonts.body(14))
                            .foregroundStyle(.secondary)
                    }
                    if let medium = viewModel.materialTech?.textileType {
                        Label(medium, systemImage: "hand.draw")
                            .font(CipherStyle.Fonts.body(14))
                            .foregroundStyle(.secondary)
                    }
                    if let era = viewModel.historyOrigins?.originPeriod {
                        Label(era, systemImage: "clock")
                            .font(CipherStyle.Fonts.body(14))
                            .foregroundStyle(.secondary)
                    }
                }

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)

                // Short origin paragraph
                if let summary = viewModel.historyOrigins?.summary {
                    Text(summary)
                        .font(CipherStyle.Fonts.body(15))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                        .lineSpacing(4)
                }

                // Closing editorial hook
                if let hook = viewModel.contemporary?.whyItResonatesNow {
                    Text(hook)
                        .font(CipherStyle.Fonts.titleItalic(18))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                        .lineSpacing(3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Error

    private var errorSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Analysis Failed")
                .font(CipherStyle.Fonts.headline)
            if let error = scan.errorMessage {
                Text(error)
                    .font(CipherStyle.Fonts.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Analysis Sections

    private var sectionDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 24)
    }

    private var analysisSections: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card 2 — Symbolic Meaning + Color Language
            if viewModel.symbolsMotifs != nil || viewModel.colorIntel != nil {
                sectionDivider
                symbolicMeaningSection
            }

            // Card 3 — Cultural Shifts + Pattern Profile
            if viewModel.culturalShifts != nil || viewModel.contemporary != nil || !viewModel.patternProfile.isEmpty || viewModel.historyOrigins != nil {
                sectionDivider
                culturalShiftsSection
            }

            // Card 4 — Material & Production
            if viewModel.materialTech != nil {
                sectionDivider
                materialProductionSection
            }

            // Card 5 — Contemporary Relevance
            if viewModel.contemporary != nil {
                sectionDivider
                contemporaryRelevanceSection
            }

            Spacer().frame(height: 48)
        }
    }

    // MARK: - Symbolic Meaning (Card 2)

    private var symbolicMeaningSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Symbolic Meaning")
                    .font(CipherStyle.Fonts.title2)
                    .padding(.top, 12)

                // Summary paragraphs
                if let symbols = viewModel.symbolsMotifs {
                    Text(symbols.summary)
                        .font(CipherStyle.Fonts.body(15))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                        .lineSpacing(4)
                }

                // Divider before color section
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)

                // Color Language
                if let colors = viewModel.colorIntel {
                    Text("Color language")
                        .font(CipherStyle.Fonts.title3)

                    ForEach(Array(colors.dominantColors.prefix(3))) { entry in
                        colorSwatchRow(entry)
                    }

                    // Closing synthesis
                    Text(colors.meaningEvolution)
                        .font(CipherStyle.Fonts.titleItalic(17))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                        .lineSpacing(3)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Cultural Shifts (Card 3)

    private var culturalShiftsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cultural Shifts")
                    .font(CipherStyle.Fonts.title2)
                    .padding(.top, 12)

                // Divider below title
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)

                // Summary — prefer culturalShifts, fallback chain
                let shiftsSummary = viewModel.culturalShifts?.summary
                    ?? viewModel.contemporary?.summary
                    ?? viewModel.historyOrigins?.summary
                if let shiftsSummary {
                    Text(shiftsSummary)
                        .font(CipherStyle.Fonts.body(15))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                        .lineSpacing(4)
                }

                // Revival cycles — prefer culturalShifts, fallback to historyOrigins.revivalMoments
                let cycles = viewModel.culturalShifts?.revivalCycles
                    ?? viewModel.historyOrigins?.revivalMoments
                    ?? []
                if !cycles.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(cycles, id: \.self) { cycle in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\u{2022}")
                                    .foregroundStyle(.secondary)
                                Text(cycle)
                                    .font(CipherStyle.Fonts.body(14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Pattern Profile — dot meter
                if !viewModel.patternProfile.isEmpty {
                    Text("Pattern profile")
                        .font(CipherStyle.Fonts.title3)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.patternProfile) { attr in
                            HStack(spacing: 0) {
                                Text(attr.name)
                                    .font(CipherStyle.Fonts.body(13))
                                    .frame(width: 110, alignment: .leading)

                                dotMeter(score: attr.score)
                            }
                        }
                    }
                }

                // Closing synthesis — prefer culturalShifts, fallback to contemporary
                let synthesis = viewModel.culturalShifts?.synthesis
                    ?? viewModel.contemporary?.whyItResonatesNow
                if let synthesis, !synthesis.isEmpty {
                    Text(synthesis)
                        .font(CipherStyle.Fonts.titleItalic(17))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                        .lineSpacing(3)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func dotMeter(score: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= score
                        ? CipherStyle.Colors.primaryText
                        : CipherStyle.Colors.primaryText.opacity(0.15))
                    .frame(width: 12, height: 12)
            }
        }
    }

    // MARK: - Material & Production (Card 4)

    private var materialProductionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Material & Production")
                    .font(CipherStyle.Fonts.title2)
                    .padding(.top, 12)

                // Material reference image from Wikimedia Commons
                if let url = viewModel.materialImageURL {
                    Color.clear
                        .aspectRatio(16.0/9.0, contentMode: .fit)
                        .overlay {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    EmptyView()
                                default:
                                    Rectangle().fill(.quaternary)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if let mat = viewModel.materialTech {
                    // Info rows
                    materialInfoRow(label: "Originally:", value: mat.textileType)
                    materialInfoRow(label: "Dyes:", value: viewModel.colorIntel?.dyeHistory ?? "")
                    materialInfoRow(label: "Construction:", value: mat.weavingTechnique)
                    materialInfoRow(label: "Industrial Shift:", value: mat.laborAndSocialHistory)

                    // Did you know? box
                    if let fact = mat.didYouKnow {
                        let accentColor = factBoxColor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Did you know?")
                                .font(CipherStyle.Fonts.body(14, weight: .bold))
                                .foregroundStyle(.white)
                            Text(fact)
                                .font(CipherStyle.Fonts.body(13))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            accentColor,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func materialInfoRow(label: String, value: String) -> some View {
        Group {
            if !value.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(CipherStyle.Fonts.body(14, weight: .bold))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                    Text(value)
                        .font(CipherStyle.Fonts.body(14))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                }
            }
        }
    }

    /// Pick an accent color from the first dominant color for the "Did you know?" box
    private var factBoxColor: Color {
        if let first = viewModel.colorIntel?.dominantColors.first {
            return resolvedColor(for: first).opacity(0.85)
        }
        return Color(hex: "#5A6B52") // muted green fallback
    }

    // MARK: - Contemporary Relevance (Card 5)

    private var contemporaryRelevanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Contemporary Relevance")
                    .font(CipherStyle.Fonts.title2)
                    .padding(.top, 12)

                if let contemporary = viewModel.contemporary {
                    Text(contemporary.summary)
                        .font(CipherStyle.Fonts.body(15))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                        .lineSpacing(4)

                    // Notable references grid
                    if let refs = contemporary.notableReferences, !refs.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 20) {
                            ForEach(refs) { ref in
                                momentCard(ref)
                            }
                        }
                    }

                    // Closing sentence
                    Text(contemporary.whyItResonatesNow)
                        .font(CipherStyle.Fonts.titleItalic(17))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                        .lineSpacing(3)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func momentCard(_ moment: CulturalMoment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(4.0/3.0, contentMode: .fit)
                .overlay {
                    if let url = viewModel.momentImageURLs[moment.id] {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Rectangle().fill(.white.opacity(0.04))
                            default:
                                Rectangle().fill(.white.opacity(0.04))
                            }
                        }
                    } else {
                        Rectangle().fill(.white.opacity(0.04))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(moment.category)
                .font(CipherStyle.Fonts.body(13, weight: .bold))
                .foregroundStyle(CipherStyle.Colors.primaryText)

            Text(moment.description)
                .font(CipherStyle.Fonts.body(12))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
    }

    private func colorSwatchRow(_ entry: ColorEntry) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(resolvedColor(for: entry))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.color)
                    .font(CipherStyle.Fonts.body(14, weight: .semibold))

                Text(entry.symbolism)
                    .font(CipherStyle.Fonts.body(13))
                    .foregroundStyle(.secondary)

                if let keywords = entry.emotionalKeywords, !keywords.isEmpty {
                    Text(keywords.joined(separator: " \u{2022} "))
                        .font(CipherStyle.Fonts.body(13, weight: .bold))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                } else {
                    Text(entry.culturalMeaning)
                        .font(CipherStyle.Fonts.body(13, weight: .bold))
                        .foregroundStyle(CipherStyle.Colors.primaryText)
                }
            }
        }
    }

    private func resolvedColor(for entry: ColorEntry) -> Color {
        if let hex = entry.hexColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        // Fallback: resolve common textile color names
        let name = entry.color.lowercased()
        let map: [(String, String)] = [
            ("ox blood", "#6A1818"), ("crimson", "#8B0000"), ("scarlet", "#C41E3A"),
            ("burgundy", "#6B1C2A"), ("maroon", "#5C1A1A"), ("rust", "#A0522D"),
            ("red", "#C41E3A"), ("cobalt", "#1B3A8B"), ("navy", "#1B2A4A"),
            ("indigo", "#2E1A6B"), ("blue", "#2A5AA0"), ("turquoise", "#4AA8A0"),
            ("teal", "#2A7B7B"), ("cyan", "#3AAFBF"), ("green", "#2D6B2D"),
            ("olive", "#6B6B2F"), ("sage", "#7E8E6C"), ("emerald", "#2D7B4E"),
            ("gold", "#C49B1A"), ("saffron", "#E4B422"), ("ochre", "#CC7722"),
            ("amber", "#C49102"), ("yellow", "#D4A820"), ("copper", "#B87333"),
            ("brown", "#6B3A2A"), ("tan", "#C4A872"), ("beige", "#C8B896"),
            ("cream", "#F0E8D0"), ("ivory", "#F5F0E0"), ("white", "#F2EDE6"),
            ("black", "#1A1A1A"), ("charcoal", "#3A3A3A"), ("grey", "#7A7A7A"),
            ("gray", "#7A7A7A"), ("silver", "#A8A8A8"), ("pink", "#C87088"),
            ("rose", "#B85070"), ("coral", "#E07050"), ("peach", "#E8A880"),
            ("lavender", "#8878A8"), ("purple", "#6A3A8A"), ("plum", "#6B3060"),
            ("violet", "#7040A0"),
        ]
        for (key, hex) in map {
            if name.contains(key) { return Color(hex: hex) }
        }
        return Color(hex: "#888888")
    }

}

