// ollama.js
// The "telephone line" to your AI brain.
// This file knows how to call your Ollama server's /api/chat endpoint and
// stream the answer back word-by-word, so the chat bubble fills in live
// instead of waiting for the whole reply.
//
// Ollama streams its answer as many tiny JSON lines (one per chunk), like:
//   {"message":{"role":"assistant","content":"Hel"},"done":false}
//   {"message":{"role":"assistant","content":"lo"},"done":false}
//   {"message":{...},"done":true}
// We read them as they arrive and hand each new piece of text to onDelta().

.pragma library

// Start a streaming chat request.
//   baseUrl  : e.g. "http://100.120.174.125:11434"
//   model    : e.g. "gpt-oss:20b"
//   messages : array of {role, content} — the whole conversation so far
//   callbacks: { onDelta(text), onDone(), onError(message) }
// Returns the XMLHttpRequest so the caller can .abort() to stop generation.
function sendChat(baseUrl, model, messages, callbacks) {
    var xhr = new XMLHttpRequest();
    var url = baseUrl.replace(/\/+$/, "") + "/api/chat";

    var processed = 0;   // how many characters of responseText we've already parsed

    function drainBuffer(finalPass) {
        var buf = xhr.responseText;
        // Walk forward consuming complete newline-terminated JSON lines.
        var newlineIndex;
        while ((newlineIndex = buf.indexOf("\n", processed)) !== -1) {
            var line = buf.substring(processed, newlineIndex).trim();
            processed = newlineIndex + 1;
            if (line.length === 0)
                continue;
            handleLine(line);
        }
        // On the final pass, there may be a last line with no trailing newline.
        if (finalPass && processed < buf.length) {
            var tail = buf.substring(processed).trim();
            processed = buf.length;
            if (tail.length > 0)
                handleLine(tail);
        }
    }

    function handleLine(line) {
        var obj;
        try {
            obj = JSON.parse(line);
        } catch (e) {
            return; // ignore a malformed line (we only feed complete lines here, so this is rare)
        }
        if (obj.error) {
            callbacks.onError(obj.error);
            return;
        }
        if (obj.message && obj.message.content)
            callbacks.onDelta(obj.message.content);
        if (obj.done === true)
            callbacks.onDone();
    }

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.LOADING) {
            // Partial data has arrived mid-stream — parse whatever full lines we have.
            drainBuffer(false);
        } else if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                drainBuffer(true);   // flush any remaining buffered line
            } else if (xhr.status === 0) {
                callbacks.onError(qsTr("Can't reach the server. Is Ollama running and is the address right?"));
            } else {
                callbacks.onError(qsTr("Server error (%1)").arg(xhr.status));
            }
        }
    };

    try {
        xhr.open("POST", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({
            "model": model,
            "messages": messages,
            "stream": true
        }));
    } catch (e) {
        callbacks.onError(qsTr("Bad server address."));
    }

    return xhr;
}

// Fetch the list of models installed on the server (for the Settings picker).
//   callbacks: { onResult(arrayOfModelNames), onError(message) }
function listModels(baseUrl, callbacks) {
    var xhr = new XMLHttpRequest();
    var url = baseUrl.replace(/\/+$/, "") + "/api/tags";
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    var names = (data.models || []).map(function(m) { return m.name; });
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
    xhr.send();
    return xhr;
}
