# On-device plan — run the LLM + RAG entirely on the phone

Handoff doc. Goal: make Sage work **fully offline on the phone** — a small Liquid
model + RAG running on-device, no server, no Tailscale. This is the "on-device
tier" companion to the working "server tier."

## Where things stand (server tier — already working)

- GPU box (AMD RX 6600, 8GB) runs **sage-rag** (`:11500`) in front of Ollama.
- Answer model: **`lfm2.5:8b`** (LiquidAI LFM2.5-8B-A1B, Q4) — **116 tok/s**, 5.3GB
  VRAM, 100% GPU. Beat qwen2.5:7b (40) and gemma4:e2b (74).
- Embedder: `mxbai-embed-large` (1024-dim). Corpus: `knowledge-produce.json`.
- Verified: `produce-rag` returns grounded, correct answers (cranberry temp →
  2–5°C/35–41°F, matching the gold).
- Phone reaches it at `http://192.168.1.161:11500` (LAN) → harbour-sage thin client.

## The on-device target

```
harbour-sage (phone, fully local)
  ├─ small Liquid LLM        (llama.cpp, aarch64)
  ├─ small embedder          (embeds the live query)
  ├─ corpus vectors          (knowledge-*.json, ~21MB, in RAM)
  └─ cosine search           (trivial, C++/QML)
```

### Hardware (both on Sailfish OS = aarch64 Linux)
| Phone | SoC | Notes |
|---|---|---|
| **OnePlus 6** | Snapdragon 845 | stronger cores — **start here** |
| Xperia 10 III | Snapdragon 690 | official Sailfish device / first-class SDK target |

Rough CPU/Q4 tok/s expectations (Liquid may beat these):
| Model | OnePlus 6 | Xperia 10 III |
|---|---|---|
| LFM2-350M | ~30–45 | ~20–30 |
| LFM2-700M | ~20–30 | ~12–18 |
| LFM2-1.2B | ~10–18 | ~5–9 |

## Build & deploy path

1. **Cross-compile llama.cpp for aarch64** using the Sailfish SDK (the same SDK
   used to build the harbour-sage RPM). One binary runs on both phones.
   - Quicker alt: check **Chum / OpenRepos** for a prebuilt llama.cpp, or enable
     developer mode and build on-device on the OnePlus 6 (`devel-su`, `pkcon`).
2. **Get Liquid GGUFs** — LFM2-350M / 700M / 1.2B at Q4 (HuggingFace LiquidAI GGUF
   repos). `scp` them to the phone (developer mode = SSH).
3. **Benchmark** with `llama-bench` → raw tok/s for each size on each phone.
4. **On-device RAG** — embed query with a small embedder + cosine over the corpus.

## ⚠️ Critical gotcha — the corpus must be re-embedded

`knowledge-produce.json` was built with **`mxbai-embed-large` (1024-dim)**. Query
and corpus vectors MUST come from the **same** embedder, so you can't reuse that
index with a small on-device embedder. For on-device RAG you must **re-run
`ingest.py` with the small embedder** (e.g. `bge-small`, `all-MiniLM`, or a small
Liquid embedder) to produce a matching `knowledge-produce.json`. Otherwise
retrieval returns garbage.

## Endgame (harbour-sage app work)

Fold llama.cpp + the embedder + vector store + cosine search into the app as an
**on-device backend**, with a settings toggle:
- **Server mode** (today): thin client → `:11500` on the GPU box (best quality).
- **On-device mode** (new): fully local, offline, smaller brain.

## First tasks for whoever picks this up

1. Get llama.cpp running on the **OnePlus 6** (cross-compile via Sailfish SDK, or
   prebuilt/Chum). Confirm a Liquid GGUF generates text.
2. `llama-bench` LFM2-350M / 700M / 1.2B → record tok/s (both phones if possible).
3. Re-ingest the produce corpus with a **small** embedder → on-device
   `knowledge-produce.json`. Wire a minimal query→retrieve→answer loop.
4. Report tok/s + whether the 350M/700M can answer the gold produce questions
   correctly *with* the right chunk in context (the on-device quality question).

## How this feeds the benchmark

These on-device sizes (LFM2-350M/700M/1.2B) become candidates in the model-prowess
RAG leaderboard alongside the 8GB-GPU models — quantifying the **on-device tax**
(how much quality you trade to go fully local). Methodology for that benchmark is
being researched separately (RAG ablation: model-only / +RAG / +web / +both,
LLM-as-judge grading, accuracy-vs-speed-vs-size frontier).
