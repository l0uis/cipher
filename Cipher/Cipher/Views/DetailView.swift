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

            if let data = viewModel.historyOrigins {
                sectionDivider
                categorySection(title: "History & Origins", icon: "clock.arrow.circlepath") {
                    historyContent(data)
                }
            }

            if let data = viewModel.culturalRefs {
                sectionDivider
                categorySection(title: "Cultural References", icon: "book.closed") {
                    culturalContent(data)
                }
            }

            if let data = viewModel.popCulture {
                sectionDivider
                categorySection(title: "Music, Film & Pop Culture", icon: "film") {
                    popCultureContent(data)
                }
            }

            if let data = viewModel.contemporary {
                sectionDivider
                categorySection(title: "Contemporary Relevance", icon: "sparkles") {
                    contemporaryContent(data)
                }
            }

            if !viewModel.metItems.isEmpty || !viewModel.europeanaItems.isEmpty {
                sectionDivider
                enrichmentSection
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

    // MARK: - Category Section

    private func categorySection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(CipherStyle.Fonts.title2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            content()
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Category Content Builders

    @ViewBuilder
    private func historyContent(_ data: HistoryOrigins) -> some View {
        Text(data.summary)
            .font(CipherStyle.Fonts.subheadline)

        InfoRow(label: "Period", value: data.originPeriod)
        InfoRow(label: "Geographic Origin", value: data.geographicOrigin)
        InfoRow(label: "Cultural Origin", value: data.culturalOrigin)

        if !data.evolutionTimeline.isEmpty {
            Text("Evolution Timeline")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
                .padding(.top, 4)

            ForEach(data.evolutionTimeline) { entry in
                HStack(alignment: .top, spacing: 10) {
                    Text(entry.period)
                        .font(CipherStyle.Fonts.body(11, weight: .medium))
                        .frame(width: 80, alignment: .leading)
                    Text(entry.description)
                        .font(CipherStyle.Fonts.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        if !data.tradeAndColonialInfluences.isEmpty {
            Text("Trade & Colonial Influences")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
                .padding(.top, 4)
            BulletList(items: data.tradeAndColonialInfluences)
        }

        if !data.revivalMoments.isEmpty {
            Text("Revival Moments")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
                .padding(.top, 4)
            BulletList(items: data.revivalMoments)
        }
    }

    @ViewBuilder
    private func symbolsContent(_ data: SymbolsMotifs) -> some View {
        Text(data.summary)
            .font(CipherStyle.Fonts.subheadline)

        if !data.primaryMotifs.isEmpty {
            Text("Primary Motifs")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))

            ForEach(data.primaryMotifs) { motif in
                VStack(alignment: .leading, spacing: 2) {
                    Text(motif.name)
                        .font(CipherStyle.Fonts.body(13, weight: .medium))
                    Text(motif.meaning)
                        .font(CipherStyle.Fonts.caption)
                        .foregroundStyle(.secondary)
                    Text(motif.geometricDescription)
                        .font(CipherStyle.Fonts.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
        }

        InfoRow(label: "Sacred vs Decorative", value: data.sacredVsDecorative)

        if !data.hiddenMeanings.isEmpty {
            Text("Hidden Meanings")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.hiddenMeanings)
        }

        if !data.crossCulturalOverlaps.isEmpty {
            Text("Cross-Cultural Overlaps")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.crossCulturalOverlaps)
        }

        if !data.mythologicalReferences.isEmpty {
            Text("Mythological References")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.mythologicalReferences)
        }
    }

    @ViewBuilder
    private func culturalContent(_ data: CulturalRefs) -> some View {
        Text(data.summary)
            .font(CipherStyle.Fonts.subheadline)

        ReferenceList(title: "Literary References", references: data.literaryReferences)
        ReferenceList(title: "Myths & Folklore", references: data.mythsAndFolklore)
        ReferenceList(title: "Artworks", references: data.artworks)

        if !data.museumCollections.isEmpty {
            Text("Museum Collections")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.museumCollections)
        }

        if !data.fashionReinterpretations.isEmpty {
            Text("Fashion Reinterpretations")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.fashionReinterpretations)
        }
    }

    @ViewBuilder
    private func colorContent(_ data: ColorIntel) -> some View {
        Text(data.summary)
            .font(CipherStyle.Fonts.subheadline)

        if !data.dominantColors.isEmpty {
            Text("Dominant Colors")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))

            ForEach(data.dominantColors) { color in
                VStack(alignment: .leading, spacing: 2) {
                    Text(color.color)
                        .font(CipherStyle.Fonts.body(13, weight: .medium))
                    Text("Symbolism: \(color.symbolism)")
                        .font(CipherStyle.Fonts.caption)
                        .foregroundStyle(.secondary)
                    Text("Cultural: \(color.culturalMeaning)")
                        .font(CipherStyle.Fonts.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
        }

        if !data.emotionalAssociations.isEmpty {
            Text("Emotional Associations")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.emotionalAssociations)
        }

        InfoRow(label: "Dye History", value: data.dyeHistory)

        if !data.statusMarkers.isEmpty {
            Text("Status Markers")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.statusMarkers)
        }

        InfoRow(label: "Meaning Evolution", value: data.meaningEvolution)
    }

    @ViewBuilder
    private func materialContent(_ data: MaterialTech) -> some View {
        Text(data.summary)
            .font(CipherStyle.Fonts.subheadline)

        InfoRow(label: "Textile Type", value: data.textileType)
        InfoRow(label: "Weaving Technique", value: data.weavingTechnique)
        InfoRow(label: "Handcrafted vs Industrial", value: data.handcraftedVsIndustrial)

        if !data.regionSpecificTechniques.isEmpty {
            Text("Region-Specific Techniques")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.regionSpecificTechniques)
        }

        InfoRow(label: "Labor & Social History", value: data.laborAndSocialHistory)
        InfoRow(label: "Sustainability", value: data.sustainabilityNotes)
    }

    @ViewBuilder
    private func popCultureContent(_ data: PopCultureRefs) -> some View {
        Text(data.summary)
            .font(CipherStyle.Fonts.subheadline)

        ReferenceList(title: "Songs", references: data.songs)
        ReferenceList(title: "Films & Characters", references: data.filmsAndCharacters)

        if !data.subcultures.isEmpty {
            Text("Subcultures")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.subcultures)
        }

        if !data.popHistoryMoments.isEmpty {
            Text("Pop History Moments")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.popHistoryMoments)
        }

        if !data.notableArtists.isEmpty {
            Text("Notable Artists")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.notableArtists)
        }
    }

    @ViewBuilder
    private func contemporaryContent(_ data: ContemporaryRel) -> some View {
        Text(data.summary)
            .font(CipherStyle.Fonts.subheadline)

        ReferenceList(title: "Designer Reinterpretations", references: data.designerReinterpretations)

        if !data.politicalSocialReclaiming.isEmpty {
            Text("Political & Social Reclaiming")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.politicalSocialReclaiming)
        }

        InfoRow(label: "Trend Forecast", value: data.trendForecast)
        InfoRow(label: "Why It Resonates Now", value: data.whyItResonatesNow)

        if !data.controversies.isEmpty {
            Text("Controversies & Debates")
                .font(CipherStyle.Fonts.body(13, weight: .semibold))
            BulletList(items: data.controversies)
        }
    }

    // MARK: - Enrichment Section

    private var enrichmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Visual References")
                .font(CipherStyle.Fonts.title2)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            if !viewModel.metItems.isEmpty {
                Text("The Metropolitan Museum of Art")
                    .font(CipherStyle.Fonts.body(12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.metItems) { item in
                            MetMuseumCardView(item: item)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            if !viewModel.europeanaItems.isEmpty {
                Text("Europeana Collection")
                    .font(CipherStyle.Fonts.body(12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.europeanaItems) { item in
                            EuropeanaCardView(item: item)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(.bottom, 28)
    }
}

