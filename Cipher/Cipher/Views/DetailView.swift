import SwiftUI

struct DetailView: View {
    let scan: PatternScan
    @State private var viewModel: DetailViewModel

    init(scan: PatternScan) {
        self.scan = scan
        self._viewModel = State(initialValue: DetailViewModel(scan: scan))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                headerSection

                if scan.analysisStatus == "analyzing" {
                    LoadingAnalysisView()
                } else if scan.analysisStatus == "failed" {
                    errorSection
                } else if scan.analysisStatus == "completed" {
                    analysisContent
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(CipherStyle.Colors.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadImage()
        }
        .onChange(of: scan.analysisStatus) {
            viewModel.refreshIfNeeded()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = viewModel.scanImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if let name = scan.patternName {
                Text(name)
                    .font(CipherStyle.Fonts.title1)
            }

            if let origin = scan.patternOrigin {
                Label(origin, systemImage: "mappin.and.ellipse")
                    .font(CipherStyle.Fonts.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(scan.capturedAt, format: .dateTime.month(.wide).day().year().hour().minute())
                .font(CipherStyle.Fonts.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.bottom, 8)
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Analysis Content

    private var analysisContent: some View {
        VStack(spacing: 12) {
            // 1. History & Origins
            if let data = viewModel.historyOrigins {
                CategorySectionView(
                    title: "History & Origins",
                    icon: "clock.arrow.circlepath",
                    summary: data.summary
                ) {
                    historyContent(data)
                }
            }

            // 2. Symbols & Motifs
            if let data = viewModel.symbolsMotifs {
                CategorySectionView(
                    title: "Symbols & Motifs",
                    icon: "star.circle",
                    summary: data.summary
                ) {
                    symbolsContent(data)
                }
            }

            // 3. Cultural References
            if let data = viewModel.culturalRefs {
                CategorySectionView(
                    title: "Cultural References",
                    icon: "book.closed",
                    summary: data.summary
                ) {
                    culturalContent(data)
                }
            }

            // 4. Color Intelligence
            if let data = viewModel.colorIntel {
                CategorySectionView(
                    title: "Color Intelligence",
                    icon: "paintpalette",
                    summary: data.summary
                ) {
                    colorContent(data)
                }
            }

            // 5. Material & Technique
            if let data = viewModel.materialTech {
                CategorySectionView(
                    title: "Material & Technique",
                    icon: "hand.draw",
                    summary: data.summary
                ) {
                    materialContent(data)
                }
            }

            // 6. Music, Film & Pop Culture
            if let data = viewModel.popCulture {
                CategorySectionView(
                    title: "Music, Film & Pop Culture",
                    icon: "film",
                    summary: data.summary
                ) {
                    popCultureContent(data)
                }
            }

            // 7. Contemporary Relevance
            if let data = viewModel.contemporary {
                CategorySectionView(
                    title: "Contemporary Relevance",
                    icon: "sparkles",
                    summary: data.summary
                ) {
                    contemporaryContent(data)
                }
            }

            // Enrichment
            enrichmentSection
        }
    }

    // MARK: - Category Content Builders

    @ViewBuilder
    private func historyContent(_ data: HistoryOrigins) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }

    @ViewBuilder
    private func symbolsContent(_ data: SymbolsMotifs) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }

    @ViewBuilder
    private func culturalContent(_ data: CulturalRefs) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }

    @ViewBuilder
    private func colorContent(_ data: ColorIntel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }

    @ViewBuilder
    private func materialContent(_ data: MaterialTech) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }

    @ViewBuilder
    private func popCultureContent(_ data: PopCultureRefs) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }

    @ViewBuilder
    private func contemporaryContent(_ data: ContemporaryRel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }

    // MARK: - Enrichment Section

    @ViewBuilder
    private var enrichmentSection: some View {
        if !viewModel.metItems.isEmpty || !viewModel.europeanaItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Related Museum Pieces")
                    .font(CipherStyle.Fonts.title3)
                    .padding(.top, 8)

                if !viewModel.metItems.isEmpty {
                    Text("The Metropolitan Museum of Art")
                        .font(CipherStyle.Fonts.body(11, weight: .medium))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.metItems) { item in
                                MetMuseumCardView(item: item)
                            }
                        }
                    }
                }

                if !viewModel.europeanaItems.isEmpty {
                    Text("Europeana Collection")
                        .font(CipherStyle.Fonts.body(11, weight: .medium))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.europeanaItems) { item in
                                EuropeanaCardView(item: item)
                            }
                        }
                    }
                }
            }
        }
    }
}
