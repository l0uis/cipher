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

Return this exact JSON structure:
{
  "pattern_name": "e.g. Persian Herati",
  "pattern_origin": "e.g. Isfahan, Iran",
  "confidence_note": "your confidence level",
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
    "dominant_colors": [{"color": "name", "symbolism": "brief", "cultural_meaning": "brief"}],
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
    "sustainability_notes": "1-2 sentences"
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
    "summary": "2-3 sentences",
    "designer_reinterpretations": [{"title": "t", "description": "d", "source": "s"}],
    "political_social_reclaiming": ["brief items"],
    "trend_forecast": "1-2 sentences",
    "why_it_resonates_now": "1-2 sentences",
    "controversies": ["brief items"]
  }
}`;

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
    max_tokens: 4096,
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
            text: "Analyze this textile/carpet pattern. JSON only.",
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
  console.log(`Job ${jobId}: Complete - ${analysis.pattern_name}`);

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
