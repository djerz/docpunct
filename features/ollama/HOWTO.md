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

## A note on quantization

Quantization	RAM usage	CPU speed	Quality
Q2	Lowest	Fastest	Noticeable quality loss
Q3_K_M	Low	Very fast	Good
Q4_K_M	Moderate	Fast	Excellent balance
Q5_K_M	Higher	Slightly slower	Slight quality improvement
Q6_K	Higher	Slower	Very close to full precision
Q8_0	Much higher	Much slower	Near-lossless
FP16/BF16	Highest	Slowest on CPU	Reference quality

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

For progressively faster CPU-only experiments, consider these three Qwen3
tiers relative to `gpt-oss:20b` on this computer class. The multipliers are
rough engineering targets, not guarantees; prompt length, context size,
quantization, and tool loops materially affect elapsed time:

1. Around 2x faster: `qwen3:8b` (5.2 GB, tools). This is the best faster
   alternative when useful coding and agent behavior still matter. Expect a
   noticeable quality reduction from `gpt-oss:20b`, but it is the most
   credible of these three for routine Codex experiments.
2. Around 10x faster: `qwen3:1.7b` (1.4 GB, tools). Use it for short,
   well-scoped prompts where responsiveness matters more than reasoning depth.
   Expect weaker code understanding, planning, and multi-step tool use.
3. Nominal 100x tier: `qwen3:0.6b` (523 MB, tools). No model this small is a
   credible 100x-faster replacement for `gpt-oss:20b` in Codex. A more
   realistic target is roughly 15x to 30x, with poor coding and tool-call
   reliability; treat it as a latency experiment rather than a dependable
   coding agent.

Install and try one tier at a time:

```sh
ollama pull qwen3:8b
ollama pull qwen3:1.7b
ollama pull qwen3:0.6b

codex --oss --local-provider ollama -m qwen3:8b
```

Current sizes and tool support are listed in the
[Ollama Qwen3 library](https://ollama.com/library/qwen3).

gemma4:e4b
phi4-mini
phi4-mini-reasoning
deepseek-r1:7b
mistral-small

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

Control the user service with `systemctl --user`:

```sh
systemctl --user start ollama.service
systemctl --user restart ollama.service
systemctl --user stop ollama.service
systemctl --user status ollama.service
journalctl --user -u ollama.service -e
```

If you change a drop-in such as `~/.config/systemd/user/ollama.service.d/keep-alive.conf`,
reload systemd before restarting:

```sh
systemctl --user daemon-reload
systemctl --user restart ollama.service
```

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

## Mistral Vibe CLI

Install the docpunct feature and make sure the local Ollama service and a
tool-capable model are available:

```sh
./bin/docpunct install mistral-vibe
systemctl --user start ollama.service
ollama list
ollama pull qwen2.5-coder:7b-instruct-q4_K_M
```

Vibe supports generic OpenAI-compatible providers. The following lean profile
uses Vibe's minimal system prompt and only the tools needed for normal local
editing. It favors first-response latency over connectors, skills, subagents,
web tools, and automatic TODO management. If `~/.vibe/config.toml` already
contains settings, merge these entries instead of replacing the file. Top-level
options such as `active_model` must appear before the other TOML tables:

```sh
mkdir -p ~/.vibe
chmod 700 ~/.vibe
```

```toml
active_model = "ollama-qwen2.5-coder"
enable_telemetry = false
system_prompt_id = "minimal"
include_commit_signature = false
include_prompt_detail = false
include_project_context = true
enable_connectors = false
enabled_tools = [
  "bash",
  "grep",
  "read_file",
  "edit",
  "write_file",
  "ask_user_question",
  "exit_plan_mode",
]

[project_context]
default_commit_count = 1

[[providers]]
name = "ollama"
api_base = "http://127.0.0.1:11434/v1"
api_key_env_var = "OLLAMA_API_KEY"
api_style = "openai"
backend = "generic"

[[models]]
name = "qwen2.5-coder:7b-instruct-q4_K_M"
provider = "ollama"
alias = "ollama-qwen2.5-coder"
temperature = 0.2
input_price = 0.0
output_price = 0.0
```

This exact Qwen 2.5 Coder model was used for the CPU-only measurements below.
Replace its name and alias when using another exact tag from `ollama list`;
coding-agent use requires reliable tool calling.

Ollama does not authenticate loopback API requests, but Vibe's generic
provider expects an API-key variable. Give it a non-secret dummy value for the
current shell:

```sh
export OLLAMA_API_KEY=ollama
```

For persistent configuration, add the same assignment to `~/.vibe/.env` and
keep that file private:

```text
OLLAMA_API_KEY=ollama
```

```sh
chmod 600 ~/.vibe/.env
```

Keep the model and its prompt cache resident for one hour with a host-specific
user-service drop-in. Do not edit the docpunct-managed unit:

```sh
mkdir -p ~/.config/systemd/user/ollama.service.d
```

```ini
# ~/.config/systemd/user/ollama.service.d/keep-alive.conf
[Service]
Environment=OLLAMA_KEEP_ALIVE=1h
```

```sh
systemctl --user daemon-reload
systemctl --user restart ollama.service
ollama run qwen2.5-coder:7b-instruct-q4_K_M ""
ollama ps
```

Restart only when no agent request is active. This model remains about 6.9 GB
in resident memory until the keep-alive expires. The service's managed
`OLLAMA_CONTEXT_LENGTH=65536` setting remains useful for larger models; Ollama
clips this Qwen model to its native 32,768-token context, as shown by
`ollama ps`.

Start Vibe from the project it should work on:

```sh
cd /path/to/project
vibe
```

Use `/model` inside Vibe to confirm or switch to `ollama-qwen2.5-coder`.
`ollama run` sends a small prompt, while an agent client also sends its system
instructions, project context, and JSON tool schemas. Those additions can be
thousands of tokens and dominate first-response latency on a CPU-only host.

Use a harmless one-turn plan-agent request to compare cold and warm behavior:

```sh
ollama ps
vibe --agent plan --prompt 'Reply with exactly READY. Do not call any tools.' \
  --max-turns 1 --trust
journalctl --user -u ollama.service -e
```

In the journal, `task.n_tokens` is the initial prefix size, `cached n_tokens`
shows prompt-cache reuse, and the prompt timing lines separate prompt
processing from generation. On the reference CPU-only host, this profile cut
the initial prefix from 5,714 to 1,954 tokens (65.8%). The cold prompt took
124.6 seconds in Ollama. Repeating the same request while the model stayed
loaded reused 1,827 tokens, processed only 125, and reduced Ollama time to 4.79
seconds (6.07 seconds end to end). `ollama ps` should report about one hour in
the `UNTIL` column after either request; if it does not, confirm the drop-in is
loaded with `systemctl --user show ollama.service -p Environment`.

### Add explicit local-tool guidance and URL fetching

The minimal prompt reduces latency, but a small local model may still decline
to inspect the working directory even though the `bash` tool is available. Add
a short custom prompt that explicitly tells the model when to use its local
tools, without restoring Vibe's full default prompt:

```sh
mkdir -p ~/.vibe/prompts
chmod 700 ~/.vibe/prompts
```

Create `~/.vibe/prompts/minimal-local.md` with:

```md
You are Mistral Vibe, a CLI coding agent working through tools.

Use available tools instead of claiming you lack access:
- Use bash with pwd or ls to inspect directories.
- Use grep and read_file to inspect local files.
- Use web_fetch when the user provides a URL.
- Attempt the appropriate tool before reporting that an operation is unavailable.

Make minimal changes and verify them.
```

Then select that prompt and add `web_fetch` to the existing tool allowlist in
`~/.vibe/config.toml`:

```toml
system_prompt_id = "minimal-local"

enabled_tools = [
  "bash",
  "grep",
  "read_file",
  "edit",
  "write_file",
  "web_fetch",
  "ask_user_question",
  "exit_plan_mode",
]
```

Keep `enable_connectors = false`. `web_fetch` is a built-in, read-only tool
that retrieves a known HTTP or HTTPS URL and converts HTML to Markdown. It
does not require a Mistral API key, but Vibe asks for permission before
accessing a domain. It is not a search engine: requests that do not provide a
URL still require Vibe's `web_search` with a Mistral API key, or a separately
configured search connector.

Validate both capabilities with harmless programmatic requests:

```sh
vibe --prompt 'Use bash to run pwd and ls, then summarize the result.' \
  --max-turns 2 --auto-approve --trust
vibe --prompt 'Fetch https://example.com and report its page title.' \
  --max-turns 2 --auto-approve --trust
```

Recheck `task.n_tokens` in the Ollama journal afterward. The custom guidance
adds only a short instruction, while `web_fetch` also adds its JSON tool
schema; measure the resulting prefix rather than assuming the original 1,954
token result is unchanged.

See Mistral's
[configuration documentation](https://docs.mistral.ai/vibe/code/cli/configuration)
and Ollama's
[OpenAI compatibility reference](https://docs.ollama.com/api/openai-compatibility)
and [FAQ](https://docs.ollama.com/faq).

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
