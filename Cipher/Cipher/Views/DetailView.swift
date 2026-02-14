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
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle(scan.patternName ?? "Analysis")
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
                    .font(.title2.weight(.bold))
            }

            if let origin = scan.patternOrigin {
                Label(origin, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(scan.capturedAt, format: .dateTime.month(.wide).day().year().hour().minute())
                .font(.caption)
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
                .font(.headline)

            if let error = scan.errorMessage {
                Text(error)
                    .font(.caption)
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
                .font(.subheadline)

            InfoRow(label: "Period", value: data.originPeriod)
            InfoRow(label: "Geographic Origin", value: data.geographicOrigin)
            InfoRow(label: "Cultural Origin", value: data.culturalOrigin)

            if !data.evolutionTimeline.isEmpty {
                Text("Evolution Timeline")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)

                ForEach(data.evolutionTimeline) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Text(entry.period)
                            .font(.caption.weight(.medium))
                            .frame(width: 80, alignment: .leading)
                        Text(entry.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !data.tradeAndColonialInfluences.isEmpty {
                Text("Trade & Colonial Influences")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)
                BulletList(items: data.tradeAndColonialInfluences)
            }

            if !data.revivalMoments.isEmpty {
                Text("Revival Moments")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)
                BulletList(items: data.revivalMoments)
            }
        }
    }

    @ViewBuilder
    private func symbolsContent(_ data: SymbolsMotifs) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.summary)
                .font(.subheadline)

            if !data.primaryMotifs.isEmpty {
                Text("Primary Motifs")
                    .font(.subheadline.weight(.semibold))

                ForEach(data.primaryMotifs) { motif in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(motif.name)
                            .font(.subheadline.weight(.medium))
                        Text(motif.meaning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(motif.geometricDescription)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }

            InfoRow(label: "Sacred vs Decorative", value: data.sacredVsDecorative)

            if !data.hiddenMeanings.isEmpty {
                Text("Hidden Meanings")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.hiddenMeanings)
            }

            if !data.crossCulturalOverlaps.isEmpty {
                Text("Cross-Cultural Overlaps")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.crossCulturalOverlaps)
            }

            if !data.mythologicalReferences.isEmpty {
                Text("Mythological References")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.mythologicalReferences)
            }
        }
    }

    @ViewBuilder
    private func culturalContent(_ data: CulturalRefs) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.summary)
                .font(.subheadline)

            ReferenceList(title: "Literary References", references: data.literaryReferences)
            ReferenceList(title: "Myths & Folklore", references: data.mythsAndFolklore)
            ReferenceList(title: "Artworks", references: data.artworks)

            if !data.museumCollections.isEmpty {
                Text("Museum Collections")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.museumCollections)
            }

            if !data.fashionReinterpretations.isEmpty {
                Text("Fashion Reinterpretations")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.fashionReinterpretations)
            }
        }
    }

    @ViewBuilder
    private func colorContent(_ data: ColorIntel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.summary)
                .font(.subheadline)

            if !data.dominantColors.isEmpty {
                Text("Dominant Colors")
                    .font(.subheadline.weight(.semibold))

                ForEach(data.dominantColors) { color in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(color.color)
                            .font(.subheadline.weight(.medium))
                        Text("Symbolism: \(color.symbolism)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Cultural: \(color.culturalMeaning)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }

            if !data.emotionalAssociations.isEmpty {
                Text("Emotional Associations")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.emotionalAssociations)
            }

            InfoRow(label: "Dye History", value: data.dyeHistory)

            if !data.statusMarkers.isEmpty {
                Text("Status Markers")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.statusMarkers)
            }

            InfoRow(label: "Meaning Evolution", value: data.meaningEvolution)
        }
    }

    @ViewBuilder
    private func materialContent(_ data: MaterialTech) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.summary)
                .font(.subheadline)

            InfoRow(label: "Textile Type", value: data.textileType)
            InfoRow(label: "Weaving Technique", value: data.weavingTechnique)
            InfoRow(label: "Handcrafted vs Industrial", value: data.handcraftedVsIndustrial)

            if !data.regionSpecificTechniques.isEmpty {
                Text("Region-Specific Techniques")
                    .font(.subheadline.weight(.semibold))
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
                .font(.subheadline)

            ReferenceList(title: "Songs", references: data.songs)
            ReferenceList(title: "Films & Characters", references: data.filmsAndCharacters)

            if !data.subcultures.isEmpty {
                Text("Subcultures")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.subcultures)
            }

            if !data.popHistoryMoments.isEmpty {
                Text("Pop History Moments")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.popHistoryMoments)
            }

            if !data.notableArtists.isEmpty {
                Text("Notable Artists")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.notableArtists)
            }
        }
    }

    @ViewBuilder
    private func contemporaryContent(_ data: ContemporaryRel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.summary)
                .font(.subheadline)

            ReferenceList(title: "Designer Reinterpretations", references: data.designerReinterpretations)

            if !data.politicalSocialReclaiming.isEmpty {
                Text("Political & Social Reclaiming")
                    .font(.subheadline.weight(.semibold))
                BulletList(items: data.politicalSocialReclaiming)
            }

            InfoRow(label: "Trend Forecast", value: data.trendForecast)
            InfoRow(label: "Why It Resonates Now", value: data.whyItResonatesNow)

            if !data.controversies.isEmpty {
                Text("Controversies & Debates")
                    .font(.subheadline.weight(.semibold))
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
                    .font(.title3.weight(.semibold))
                    .padding(.top, 8)

                if !viewModel.metItems.isEmpty {
                    Text("The Metropolitan Museum of Art")
                        .font(.caption.weight(.medium))
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
                        .font(.caption.weight(.medium))
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
