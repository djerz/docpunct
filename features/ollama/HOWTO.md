# Ollama feature HOWTO

The `ollama` feature installs the latest official Linux release under
`~/.local/share/docpunct/ollama`, links `~/.local/bin/ollama`, and installs a
per-user systemd service bound to `127.0.0.1:11434`. It does not install a
model or GPU driver. Models and configuration under `~/.ollama` remain
user-owned and are preserved when the feature is removed.

## Install a model

An Ollama server without a model cannot answer requests. List installed models
and pull one by its exact library tag:

```sh
ollama list
ollama pull gpt-oss:20b
ollama run gpt-oss:20b
```

Exit an interactive model session with `/bye`. Pulling a model can download
several to tens of gigabytes. Check its size in the
[Ollama model library](https://ollama.com/search) first.

Manage local models with:

```sh
ollama show gpt-oss:20b
ollama rm gpt-oss:20b
ollama ps
```

Only use models advertising tool/function calling for coding agents. Codex and
Copilot CLI also need large context windows; both upstream integrations
recommend at least 64K tokens. The managed service therefore sets
`OLLAMA_CONTEXT_LENGTH=65536`. Without that setting, Ollama's 4K default can be
consumed entirely by Codex's initial instructions, causing a prompt to finish
without a visible answer. A large context consumes additional memory; see
Ollama's [context-length documentation](https://docs.ollama.com/context-length).

## Recommendations for this computer class

The computer inspected while adding this feature has an Intel Core i7-1270P,
30 GiB RAM, and integrated Intel Iris Xe graphics. Ollama will effectively be
CPU-only on this hardware. These are the best relevant agentic coding choices
that fit in memory, but responses and tool loops will be substantially slower
than on a discrete GPU:

1. `qwen3-coder:30b` — 19 GB, 256K context, coding- and agent-focused. Best
   coding specialization here, but the least memory headroom and likely the
   slowest practical option.
2. `gpt-oss:20b` — 14 GB, 128K context, tools and configurable reasoning. Best
   balanced starting point for Codex and Copilot CLI.
3. `devstral-small-2:24b` — 15 GB, 384K context, tools and software-engineering
   specialization. Useful for comparison with `gpt-oss:20b`, but still slow on
   CPU.

Start with `gpt-oss:20b`. Do not load all three simultaneously. If latency is
more important than agent quality, try `qwen3:4b` (2.5 GB, tools, 256K context)
as a lightweight fallback.

## Recommendations for GPU computers

GPU capacity means usable VRAM, not system RAM. These choices cover common
high-performance tiers; allow extra VRAM for the context/KV cache:

1. Around 24 GB VRAM: `qwen3-coder:30b` (19 GB model).
2. At least 64 GB aggregate/unified VRAM: `qwen3-coder-next:q4_K_M` (52 GB,
   256K context), optimized for local agentic coding.
3. One 80 GB GPU or equivalent: `gpt-oss:120b` (65 GB, 128K context), the
   highest-quality gpt-oss option and explicitly designed to fit an 80 GB GPU.

For a particular GPU machine, check its exact GPU model and VRAM before
pulling one of the larger models. Multi-GPU support, driver compatibility, and
the desired context length can change which option is actually fastest.

Model metadata and sizes above come from the current Ollama library pages for
[Qwen3-Coder](https://ollama.com/library/qwen3-coder),
[gpt-oss](https://ollama.com/library/gpt-oss),
[Devstral Small 2](https://ollama.com/library/devstral-small-2), and
[Qwen3-Coder-Next](https://ollama.com/library/qwen3-coder-next).

## Server lifecycle

When a user systemd manager was available during installation, the feature
enabled and started `ollama.service`:

```sh
systemctl --user status ollama
systemctl --user restart ollama
journalctl --user -u ollama -e
curl http://127.0.0.1:11434/api/version
```

On a host without a user systemd manager, run the server in a terminal:

```sh
ollama serve
```

The managed service listens only on loopback. Do not expose Ollama directly to
an untrusted network: its local API has no authentication by default.

The service defaults to a 65,536-token context so coding agents have room for
their instructions, repository context, tool calls, and responses. Check the
active context after a model is loaded:

```sh
ollama ps
```

To use a different value, create a systemd drop-in instead of editing the
docpunct-managed unit:

```sh
systemctl --user edit ollama.service
```

For example, a lower-memory machine can use:

```ini
[Service]
Environment=OLLAMA_CONTEXT_LENGTH=32768
```

Then apply it:

```sh
systemctl --user daemon-reload
systemctl --user restart ollama.service
```

Reducing the context below 64K is not recommended for Codex or Copilot CLI.

## Codex CLI

The simplest setup lets Ollama create a temporary Codex profile and refresh
the model catalog:

```sh
ollama launch codex --model gpt-oss:20b
```

Or invoke Codex's built-in local provider directly:

```sh
codex --oss --local-provider ollama -m gpt-oss:20b
```

On CPU-only systems, the first response can take several minutes because Codex
sends a substantial initial instruction prompt before the user's message.

Use `ollama launch codex --config` to generate the Ollama-backed Codex profile
without starting Codex, and `ollama launch codex --restore` to remove that
generated profile. See the official
[Ollama Codex integration](https://docs.ollama.com/integrations/codex).

## GitHub Copilot CLI

Recent Copilot CLI versions support local Ollama through BYOK provider
settings. The Responses API configuration recommended by Ollama is:

```sh
COPILOT_PROVIDER_BASE_URL=http://localhost:11434/v1 \
COPILOT_PROVIDER_API_KEY= \
COPILOT_PROVIDER_WIRE_API=responses \
COPILOT_MODEL=gpt-oss:20b \
COPILOT_OFFLINE=true \
copilot
```

`COPILOT_OFFLINE=true` prevents Copilot CLI itself from contacting GitHub;
keep it only when that is the intended behavior. The selected model must
support streaming and tool calls. See the official
[Ollama Copilot CLI integration](https://docs.ollama.com/integrations/copilot-cli)
and [GitHub BYOK documentation](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/use-byok-models).

## CopilotChat.nvim

The CopilotChat.nvim version pinned by this repository supports custom
providers but does not include a built-in Ollama provider. Add an explicit
adapter to the plugin's `opts` in
`dotfiles/.config/nvim/lua/plugins/copilotchat.lua`:

```lua
local local_model = "gpt-oss:20b"
local provider_helpers = require("CopilotChat.config.providers")

opts = {
  model = local_model,
  providers = {
    ollama = {
      get_url = function()
        return "http://127.0.0.1:11434/v1/chat/completions"
      end,
      get_models = function()
        return {
          {
            id = local_model,
            name = local_model .. " (Ollama)",
            max_input_tokens = 65536,
            max_output_tokens = 8192,
            streaming = true,
            tools = true,
          },
        }
      end,
      prepare_input = provider_helpers.copilot.prepare_input,
      prepare_output = provider_helpers.copilot.prepare_output,
    },
  },
}
```

Merge this with the existing `opts` table rather than defining `opts` twice.
Restart Neovim, run `:CopilotChatModels`, and select the Ollama model. This
adapter is tied to the repository's pinned CopilotChat.nvim provider API;
recheck the plugin's upstream provider documentation when updating its lock.

## Direct API usage

Ollama exposes both a native API and an OpenAI-compatible API:

```sh
curl http://127.0.0.1:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"model":"gpt-oss:20b","stream":false,"messages":[{"role":"user","content":"Explain this repository."}]}'

curl http://127.0.0.1:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"gpt-oss:20b","messages":[{"role":"user","content":"Explain this repository."}]}'
```

OpenAI SDKs generally need `http://127.0.0.1:11434/v1` as the base URL and a
dummy non-empty API key such as `ollama`; Ollama ignores that local key. See
the official [OpenAI compatibility reference](https://docs.ollama.com/api/openai-compatibility).

## Update and remove

Update the Ollama runtime without changing models:

```sh
./bin/docpunct update ollama
```

Update reloads the managed unit and restarts the user service so service
environment changes take effect. Running models are unloaded during restart.

Remove the managed runtime and service:

```sh
./bin/docpunct remove ollama
```

Removal intentionally keeps `~/.ollama`, including large model files. Inspect
and delete that directory manually only when the models and configuration are
no longer wanted.
