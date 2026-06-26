// ollama.js
// The "telephone line" to your AI brain. Despite the name, this now speaks
// three dialects and picks the right one from the selected provider:
//
//   1. OpenAI-compatible (OpenRouter, OpenAI, etc.).
//        URL looks like  https://openrouter.ai/api/v1
//        Needs an API key (Bearer token). Streams Server-Sent Events:
//          data: {"choices":[{"delta":{"content":"Hel"}}]}
//          data: {"choices":[{"delta":{"content":"lo"}}]}
//          data: [DONE]
//        The text lives at  choices[0].delta.content.
//
//   2. Google Gemini.
//        URL looks like  https://generativelanguage.googleapis.com/v1beta
//        Needs a Google API key. Streams Server-Sent Events:
//          data: {"candidates":[{"content":{"parts":[{"text":"Hel"}]}}]}
//
//   3. Ollama (your own machine over Tailscale).
//        URL looks like  http://100.120.174.125:11434
//        No key. Streams newline-delimited JSON:
//          {"message":{"content":"Hel"},"done":false}
//          {"message":{"content":"lo"},"done":false}
//          {"message":{...},"done":true}
//        The text lives at  message.content.
//
// Either way we read chunks as they arrive and hand each new piece to onDelta().

.pragma library

function providerKind(provider, baseUrl) {
    if (provider === "google")
        return "google";
    if (provider === "ollama")
        return "ollama";
    if (provider === "openrouter")
        return "openai";
    return isOpenAICompatible(baseUrl) ? "openai" : "ollama";
}

// Backward-compatible address sniffing for old settings and ad-hoc endpoints.
function isOpenAICompatible(baseUrl) {
    var u = (baseUrl || "").toLowerCase();
    return u.indexOf("openrouter.ai") !== -1
        || u.indexOf("api.openai.com") !== -1
        || /\/v1\/?$/.test(u);
}

function providerName(kind) {
    if (kind === "google")
        return qsTr("Google");
    if (kind === "openai")
        return qsTr("OpenRouter");
    return qsTr("Ollama");
}

function trimSlashes(s) {
    return (s || "").replace(/\/+$/, "");
}

function googleModelName(model) {
    model = model || "gemini-2.5-flash";
    return model.indexOf("models/") === 0 ? model.substring(7) : model;
}

function googleContents(messages) {
    var contents = [];
    var system = [];
    for (var i = 0; i < messages.length; i++) {
        var m = messages[i];
        if (m.role === "system") {
            system.push(m.content);
            continue;
        }
        contents.push({
            "role": m.role === "assistant" ? "model" : "user",
            "parts": [{ "text": m.content }]
        });
    }
    return { "contents": contents, "system": system };
}

// Start a streaming chat request.
//   provider : "openrouter", "google", or "ollama"
//   baseUrl  : e.g. "https://openrouter.ai/api/v1" or "http://host:11434"
//   apiKey   : provider key ("" for Ollama)
//   model    : e.g. "openai/gpt-oss-20b:free" or "gpt-oss:20b"
//   messages : array of {role, content} — the whole conversation so far
//   callbacks: { onDelta(text), onDone(), onError(message) }
// Returns the XMLHttpRequest so the caller can .abort() to stop generation.
function sendChat(provider, baseUrl, apiKey, model, messages, callbacks) {
    var kind = providerKind(provider, baseUrl);
    if ((kind === "openai" || kind === "google") && (!apiKey || apiKey.length === 0)) {
        callbacks.onError(qsTr("%1 API key is missing. Open Settings and paste it.").arg(providerName(kind)));
        return null;
    }

    var xhr = new XMLHttpRequest();
    var url;
    if (kind === "openai")
        url = trimSlashes(baseUrl) + "/chat/completions";
    else if (kind === "google")
        url = trimSlashes(baseUrl) + "/models/" + encodeURIComponent(googleModelName(model))
            + ":streamGenerateContent?alt=sse&key=" + encodeURIComponent(apiKey);
    else
        url = trimSlashes(baseUrl) + "/api/chat";

    var processed = 0;   // chars of responseText already parsed
    var finished = false; // guard so onDone fires exactly once

    function drainBuffer(finalPass) {
        var buf = xhr.responseText;
        var newlineIndex;
        while ((newlineIndex = buf.indexOf("\n", processed)) !== -1) {
            var line = buf.substring(processed, newlineIndex).trim();
            processed = newlineIndex + 1;
            if (line.length === 0)
                continue;
            handleLine(line);
        }
        if (finalPass && processed < buf.length) {
            var tail = buf.substring(processed).trim();
            processed = buf.length;
            if (tail.length > 0)
                handleLine(tail);
        }
    }

    function done() {
        if (finished)
            return;
        finished = true;
        callbacks.onDone();
    }

    function handleLine(line) {
        if (kind === "openai" || kind === "google") {
            // SSE: keep-alive comments start with ":" — ignore them.
            if (line.charAt(0) === ":")
                return;
            if (line.indexOf("data:") === 0)
                line = line.substring(5).trim();
            if (line === "[DONE]") {
                done();
                return;
            }
        }
        var obj;
        try {
            obj = JSON.parse(line);
        } catch (e) {
            return; // ignore a malformed/partial line
        }
        if (obj.error) {
            callbacks.onError(typeof obj.error === "string"
                              ? obj.error
                              : (obj.error.message || qsTr("Unknown error")));
            return;
        }
        if (kind === "openai") {
            var choice = obj.choices && obj.choices[0];
            if (choice) {
                if (choice.delta && choice.delta.content)
                    callbacks.onDelta(choice.delta.content);
                if (choice.finish_reason)
                    done();
            }
        } else if (kind === "google") {
            var candidate = obj.candidates && obj.candidates[0];
            if (candidate) {
                var parts = candidate.content && candidate.content.parts;
                if (parts) {
                    for (var i = 0; i < parts.length; i++) {
                        if (parts[i].text)
                            callbacks.onDelta(parts[i].text);
                    }
                }
                if (candidate.finishReason)
                    done();
            }
        } else {
            if (obj.message && obj.message.content)
                callbacks.onDelta(obj.message.content);
            if (obj.done === true)
                done();
        }
    }

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.LOADING) {
            drainBuffer(false);
        } else if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                drainBuffer(true);
                done();   // some hosts close without a [DONE]/finish_reason line
            } else if (xhr.status === 0) {
                callbacks.onError(kind === "ollama"
                    ? qsTr("Can't reach the server. Is Ollama running and is the address right?")
                    : qsTr("Can't reach %1. Check your connection and API key.").arg(providerName(kind)));
            } else if (xhr.status === 401) {
                callbacks.onError(qsTr("Unauthorized (401) — check your API key in Settings."));
            } else if (xhr.status === 403) {
                callbacks.onError(qsTr("Forbidden (403) — this API key may not be enabled for %1.").arg(providerName(kind)));
            } else {
                callbacks.onError(qsTr("Server error (%1)").arg(xhr.status));
            }
        }
    };

    try {
        xhr.open("POST", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        var body;
        if (kind === "openai") {
            xhr.setRequestHeader("Authorization", "Bearer " + apiKey);
            // OpenRouter likes (optional) attribution headers.
            xhr.setRequestHeader("HTTP-Referer", "https://github.com/nigelmsipa/harbour-sage");
            xhr.setRequestHeader("X-Title", "Sage");
            body = {
                "model": model,
                "messages": messages,
                "stream": true
            };
        } else if (kind === "google") {
            var gc = googleContents(messages);
            body = { "contents": gc.contents };
            if (gc.system.length > 0)
                body.systemInstruction = { "parts": [{ "text": gc.system.join("\n\n") }] };
        } else {
            body = {
                "model": model,
                "messages": messages,
                "stream": true
            };
        }
        xhr.send(JSON.stringify(body));
    } catch (e) {
        callbacks.onError(qsTr("Bad server address."));
    }

    return xhr;
}

// Fetch the list of available models (for the Settings picker).
//   callbacks: { onResult(arrayOfModelNames), onError(message) }
function listModels(provider, baseUrl, apiKey, callbacks) {
    var kind = providerKind(provider, baseUrl);
    if ((kind === "openai" || kind === "google") && (!apiKey || apiKey.length === 0)) {
        callbacks.onError(qsTr("%1 API key is missing.").arg(providerName(kind)));
        return null;
    }

    var xhr = new XMLHttpRequest();
    var url;
    if (kind === "openai")
        url = trimSlashes(baseUrl) + "/models";
    else if (kind === "google")
        url = trimSlashes(baseUrl) + "/models?key=" + encodeURIComponent(apiKey);
    else
        url = trimSlashes(baseUrl) + "/api/tags";

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    var names;
                    if (kind === "openai") {
                        names = (data.data || []).map(function(m) { return m.id; });
                    } else if (kind === "google") {
                        names = (data.models || [])
                            .filter(function(m) {
                                var methods = m.supportedGenerationMethods || [];
                                return methods.indexOf("generateContent") !== -1
                                    || methods.indexOf("streamGenerateContent") !== -1;
                            })
                            .map(function(m) {
                                return (m.name || "").replace(/^models\//, "");
                            });
                    } else {
                        names = (data.models || []).map(function(m) { return m.name; });
                    }
                    callbacks.onResult(names);
                } catch (e) {
                    callbacks.onError(qsTr("Couldn't read the model list."));
                }
            } else {
                callbacks.onError(qsTr("Can't reach the server."));
            }
        }
    };
    xhr.open("GET", url);
    if (kind === "openai" && apiKey && apiKey.length > 0)
        xhr.setRequestHeader("Authorization", "Bearer " + apiKey);
    xhr.send();
    return xhr;
}
