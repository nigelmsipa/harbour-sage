# Sage — a native Sailfish OS chat client for a private AI

**Sage** is a hand-built [Sailfish OS](https://sailfishos.org/) app that turns a
phone into a front-end for a *self-hosted* AI assistant. Instead of talking to a
cloud service, it talks to my **own** model server (Ollama) running on my own
computer over a private [Tailscale](https://tailscale.com/) network — and, in
knowledge mode, to a custom RAG service over a curated knowledge base.

> The backend brains — retrieval, knowledge base, evaluation — live in the
> companion repo: **[sage-rag](https://github.com/nigelmsipa/sage-rag)**.

---

## Why

I wanted "my own ChatGPT": private, no subscription, my data never leaving my
machines — on one of the rarest, most privacy-focused mobile platforms there is.
Sailfish has no app for this, so I built one the proper way, following the
platform's native design language (Silica).

## What it does

- **Streaming chat** with a local model (`gpt-oss:20b`) — replies render token by
  token, like ChatGPT
- **Knowledge mode** — point it at the RAG service and it answers from a curated
  domain corpus, with sources
- **Saved conversations** — chats persist to disk as JSON; reopen any past chat
- **A slide-out chat drawer** with a custom **frosted-glass** effect (live blur
  of the content behind it) — accessibility over dogma, but still themed to the
  system ambience
- **Cover page** (the Sailfish minimized-app card) and **pulley menus** — proper
  native interaction patterns

## Built natively, the platform way

| Piece | Approach |
|-------|----------|
| UI | QML + **Silica** (Sailfish's toolkit) — theme colors, pulley menus, cover, gestures |
| Networking | streaming `XMLHttpRequest` against the Ollama-compatible API |
| Persistence | a small C++ `FileIO` helper (QML can't write files) + `Nemo.Configuration` for settings |
| Packaging | built to an `.rpm` with the Sailfish SDK and deployed over the air |

## Architecture

```
Sage (this app, on the phone)
   │  Tailscale (private network)
   ▼
RAG service ──► Ollama ──► gpt-oss:20b
(curated corpus)   (local model engine, my computer)
```

## Notable implementation details

- **Frosted glass without artifacts:** the drawer blurs a *downscaled* live
  snapshot of the chat behind it (`ShaderEffectSource` → `FastBlur`), which both
  looks like native Sailfish glass and avoids readable text bleeding through.
- **Reasoning-model handling:** the answer model is a reasoning model; the app
  shows the clean final answer and streams it as it arrives.
- **Settings that travel:** server address + model are stored with
  `Nemo.Configuration`, so knowledge mode is a setting, not a rebuild.

## Tech stack

Sailfish OS · QML · Silica · C++ (Qt) · `QtGraphicalEffects` · Ollama API ·
Tailscale

## What this demonstrates

- Shipping a **native** app on a non-mainstream platform, respecting its design
  language rather than porting a generic UI
- Pragmatic UX decisions (the accessible drawer vs. "pure" Sailfish navigation)
- Designing a thin client against a self-hosted AI backend
