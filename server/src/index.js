import Anthropic from "@anthropic-ai/sdk";
import express from "express";
import sharp from "sharp";
import crypto from "crypto";

const app = express();
app.use(express.json({ limit: "20mb" }));

const anthropic = new Anthropic({ timeout: 3 * 60 * 1000 });

// In-memory job store
const jobs = new Map();

const SYSTEM_PROMPT = `You are Cipher, a cultural analyst of textile and carpet patterns.

VOICE & TONE
Write with the clarity of The New York Times cultural reporting, the restraint of The Gentlewoman, and the design literacy of Disegno Journal. Be informed but not academic. Editorial, not instructional. Confident, culturally aware, concise and controlled. Slightly poetic, never mystical. Observant and design-aware.

Avoid: textbook explanations, overly literal descriptions, excessive adjectives, long paragraphs, romantic exaggeration.
Prefer: a strong opening sentence that captures the essence. Short, elegant phrasing with restraint. Cultural references used selectively. Interpretation without overstatement.

Write for a design-literate reader. Assume intelligence. Each summary should feel like a tight cultural feature, not a database entry.

RULES
- Return JSON only — no markdown, no code fences.
- Summaries: 2-3 sentences max, editorially sharp.
- Array items: 2-3 per array. Each item a single clear sentence or phrase.
- Longer fields (dye_history, labor_and_social_history, etc.): 1-2 sentences, pointed.
- Total text across all fields should stay under 250 words where possible.
- Prioritize accuracy and cultural specificity over completeness.

Return this exact JSON structure. ALL fields are REQUIRED — do not omit any.
{
  "pattern_name": "e.g. Persian Herati",
  "pattern_origin": "e.g. Isfahan, Iran",
  "confidence_note": "your confidence level",
  "cultural_shifts": {
    "summary": "2 short paragraphs on how this pattern moved between social classes, power structures, and subcultures (aristocracy, military, working class, counterculture, colonial trade, religion). Max 180 words.",
    "revival_cycles": ["max 4 key revival moments, e.g. Clan identity, Victorian romanticism, Punk rebellion, Luxury branding"],
    "synthesis": "One closing sentence synthesizing the pattern's social journey"
  },
  "pattern_profile": [
    {"name": "Heritage", "score": 4},
    {"name": "Authority", "score": 3},
    {"name": "Rebellion", "score": 2},
    {"name": "Formality", "score": 5},
    {"name": "Structure", "score": 4}
  ],
  "history_and_origins": {
    "summary": "2-3 sentences",
    "origin_period": "when",
    "geographic_origin": "where",
    "cultural_origin": "which culture",
    "evolution_timeline": [{"period": "era", "description": "what happened"}],
    "trade_and_colonial_influences": ["brief items"],
    "revival_moments": ["brief items"]
  },
  "symbols_and_motifs": {
    "summary": "2-3 sentences",
    "primary_motifs": [{"name": "motif", "meaning": "meaning", "geometric_description": "shape"}],
    "sacred_vs_decorative": "brief",
    "hidden_meanings": ["brief items"],
    "cross_cultural_overlaps": ["brief items"],
    "mythological_references": ["brief items"]
  },
  "cultural_references": {
    "summary": "2-3 sentences",
    "literary_references": [{"title": "t", "description": "d", "source": "s"}],
    "myths_and_folklore": [{"title": "t", "description": "d", "source": "s"}],
    "artworks": [{"title": "t", "description": "d", "source": "s"}],
    "museum_collections": ["brief items"],
    "fashion_reinterpretations": ["brief items"]
  },
  "color_intelligence": {
    "summary": "2-3 sentences",
    "dominant_colors": [{"color": "name", "hex_color": "#8B0000", "symbolism": "brief", "cultural_meaning": "brief", "emotional_keywords": ["keyword1", "keyword2", "keyword3"]}],
    "emotional_associations": ["brief items"],
    "dye_history": "1-2 sentences",
    "status_markers": ["brief items"],
    "meaning_evolution": "1-2 sentences"
  },
  "material_and_technique": {
    "summary": "2-3 sentences",
    "textile_type": "type",
    "weaving_technique": "technique",
    "handcrafted_vs_industrial": "brief",
    "region_specific_techniques": ["brief items"],
    "labor_and_social_history": "1-2 sentences",
    "sustainability_notes": "1-2 sentences",
    "did_you_know": "One surprising, tactile, or little-known fact about how this specific textile is made. Keep it vivid and specific — something a textile designer would find fascinating.",
    "material_image_query": "A short Wikimedia Commons search query (2-4 words) to find an image of this material being made or the raw materials, e.g. 'handloom weaving wool' or 'silk dyeing vat' or 'jacquard loom textile'"
  },
  "music_film_pop_culture": {
    "summary": "2-3 sentences",
    "songs": [{"title": "t", "description": "d", "source": "s"}],
    "films_and_characters": [{"title": "t", "description": "d", "source": "s"}],
    "subcultures": ["brief items"],
    "pop_history_moments": ["brief items"],
    "notable_artists": ["brief items"]
  },
  "contemporary_relevance": {
    "summary": "1-2 sharp sentences on why this pattern still appears today. Max 80 words. Address: why it persists, what conversations it enters, whether it reads as nostalgic/ironic/authoritative/timeless.",
    "designer_reinterpretations": [{"title": "t", "description": "d", "source": "s"}],
    "political_social_reclaiming": ["brief items"],
    "trend_forecast": "1-2 sentences",
    "why_it_resonates_now": "1-2 sentences",
    "controversies": ["brief items"],
    "notable_references": [
      {"category": "Runway Moment", "description": "1 concise sentence about a specific designer runway use", "image_query": "designer name pattern runway fashion"},
      {"category": "Celebrity Association", "description": "1 concise sentence about a celebrity/icon linked to this pattern", "image_query": "celebrity name pattern fashion"},
      {"category": "Subculture Movement", "description": "1 concise sentence about a subculture that adopted this pattern", "image_query": "subculture name pattern fashion style"},
      {"category": "Film Reference", "description": "1 concise sentence about a notable film appearance", "image_query": "film name costume pattern scene"}
    ]
  }
}

CRITICAL: pattern_profile and cultural_shifts MUST be included — they appear near the top of the schema for a reason. pattern_profile MUST contain exactly 5 entries. Pick the 5 most relevant from: Heritage, Structure, Ornamentation, Authority, Subversion, Fluidity, Rebellion, Playfulness, Formality, Spirituality, Minimalism, Opulence. Score each 1-5.
notable_references MUST contain 3-5 entries. Pick from: Runway Moment, Celebrity Association, Subculture Movement, Film Reference, Music Reference. Use REAL, specific people/films/designers — never generic placeholders. image_query should be a short Wikimedia Commons search (3-5 words) to find a relevant photo.`;

// POST /api/analyze - Submit image, returns job ID immediately
app.post("/api/analyze", async (req, res) => {
  try {
    const { image } = req.body;
    if (!image) {
      return res.status(400).json({ error: "Missing image data" });
    }

    const jobId = crypto.randomUUID();
    const imageSize = (Buffer.byteLength(image, "utf8") / 1024).toFixed(0);
    console.log(`Job ${jobId}: Received image (${imageSize}KB base64)`);
    jobs.set(jobId, { status: "processing" });

    // Return immediately
    res.json({ jobId });

    // Process in background
    processAnalysis(jobId, image).catch((err) => {
      console.error("Background analysis error:", err.message);
      jobs.set(jobId, { status: "failed", error: err.message });
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/analyze/:jobId - Poll for results
app.get("/api/analyze/:jobId", (req, res) => {
  const job = jobs.get(req.params.jobId);
  if (!job) {
    return res.status(404).json({ error: "Job not found" });
  }
  res.json(job);
});

async function processAnalysis(jobId, imageBase64) {
  const rawBuffer = Buffer.from(imageBase64, "base64");
  const compressed = await sharp(rawBuffer)
    .resize(800, 800, { fit: "inside", withoutEnlargement: true })
    .jpeg({ quality: 50 })
    .toBuffer();
  const compressedBase64 = compressed.toString("base64");

  console.log(
    `Job ${jobId}: Image ${(rawBuffer.length / 1024).toFixed(0)}KB -> ${(compressed.length / 1024).toFixed(0)}KB`
  );

  const response = await anthropic.messages.create({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 8192,
    system: SYSTEM_PROMPT,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: "image/jpeg",
              data: compressedBase64,
            },
          },
          {
            type: "text",
            text: "Analyze this textile/carpet pattern. Return JSON only. IMPORTANT: You must include the cultural_shifts object and pattern_profile array (5 scored attributes) — these are required.",
          },
        ],
      },
    ],
  });

  const textBlock = response.content.find((b) => b.type === "text");
  if (!textBlock?.text) {
    throw new Error("No text content in response");
  }

  let jsonText = textBlock.text.trim();
  if (jsonText.startsWith("```")) {
    jsonText = jsonText
      .replace(/^```(?:json)?\n?/, "")
      .replace(/\n?```$/, "");
  }

  const analysis = JSON.parse(jsonText);
  const keys = Object.keys(analysis);
  console.log(`Job ${jobId}: Complete - ${analysis.pattern_name} | Keys: ${keys.join(", ")}`);
  console.log(`Job ${jobId}: cultural_shifts: ${analysis.cultural_shifts ? "YES" : "MISSING"}, pattern_profile: ${analysis.pattern_profile ? `YES (${analysis.pattern_profile.length} items)` : "MISSING"}`);

  // Guarantee cultural_shifts exists
  if (!analysis.cultural_shifts) {
    console.log(`Job ${jobId}: Adding fallback cultural_shifts`);
    analysis.cultural_shifts = {
      summary: analysis.contemporary_relevance?.summary || analysis.history_and_origins?.summary || "",
      revival_cycles: analysis.history_and_origins?.revival_moments || [],
      synthesis: analysis.contemporary_relevance?.why_it_resonates_now || "",
    };
  }

  // Guarantee pattern_profile exists with 5 entries
  if (!analysis.pattern_profile || !Array.isArray(analysis.pattern_profile) || analysis.pattern_profile.length === 0) {
    console.log(`Job ${jobId}: Adding fallback pattern_profile`);
    analysis.pattern_profile = [
      { name: "Heritage", score: 3 },
      { name: "Structure", score: 3 },
      { name: "Formality", score: 3 },
      { name: "Ornamentation", score: 3 },
      { name: "Spirituality", score: 3 },
    ];
  }

  jobs.set(jobId, { status: "completed", result: analysis });

  // Clean up after 10 minutes
  setTimeout(() => jobs.delete(jobId), 10 * 60 * 1000);
}

// GET /api/enrichment/europeana
app.get("/api/enrichment/europeana", async (req, res) => {
  try {
    const europeanaKey = process.env.EUROPEANA_API_KEY;
    if (!europeanaKey) return res.json({ items: [] });

    const query = req.query.q;
    if (!query)
      return res.status(400).json({ error: "Missing query parameter 'q'" });

    const params = new URLSearchParams({
      query,
      wskey: europeanaKey,
      rows: "5",
      profile: "rich",
      media: "true",
      reusability: "open",
    });

    const response = await fetch(
      `https://api.europeana.eu/record/v2/search.json?${params}`
    );
    const data = await response.json();
    res.json(data);
  } catch (err) {
    console.error("Europeana error:", err.message);
    res.json({ items: [] });
  }
});

app.get("/api/health", (req, res) => res.json({ status: "ok" }));

const port = process.env.PORT || 3000;
app.listen(port, "0.0.0.0", () => {
  console.log(`Cipher server running on 0.0.0.0:${port}`);
});
