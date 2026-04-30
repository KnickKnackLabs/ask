<div align="center">

# ask

**Ask questions from the terminal.**

Pipe in context, attach files, or just type. Uses [sessions](https://github.com/KnickKnackLabs/sessions) for conversation continuity.

![shell: bash](https://img.shields.io/badge/shell-bash-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![runtime: sessions](https://img.shields.io/badge/runtime-sessions-7c3aed?style=flat)](https://github.com/KnickKnackLabs/sessions)
![tests: 25](https://img.shields.io/badge/tests-25-green?style=flat)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

## Install

```bash
shiv install ask
```

## Usage

```bash
# Direct question (new conversation by default)
ask q -m openai-codex/gpt-5.5 "What is a mutex?"

# Pipe context from anywhere
shimmer web fetch "https://example.com" | ask q -m openai-codex/gpt-5.5 "Summarize this page"
cat error.log | ask q -m openai-codex/gpt-5.5 "What went wrong?"

# File context
ask q -m openai-codex/gpt-5.5 -f schema.sql "Explain these tables"
ask q -m openai-codex/gpt-5.5 -f a.rs -f b.rs "Compare these implementations"

# Clipboard context
ask q -m openai-codex/gpt-5.5 -c "What's this?"

# Continue previous conversations
ask q -m openai-codex/gpt-5.5 --continue "Can you expand on that?"

# Model and provider selection
ask q -m openai-codex/gpt-5.5 "Quick answer"
ask q --provider openai-codex -m gpt-5.5 "Explain this"

# Interactive menu
ask -m openai-codex/gpt-5.5
```

## How it works

`ask` assembles context from stdin, files, and the clipboard, then sends it through `sessions`. Each question starts a fresh conversation by default; pass `--continue` for the latest ask session. Context goes in XML tags before the prompt — models focus on what's near the end, so the question lands last.

History is saved to `~/.ask/history.jsonl` with timestamps and session IDs for later recall.

## Development

```bash
gh repo clone KnickKnackLabs/ask
cd ask && mise trust && mise install
mise run test   # 25 tests
```

<div align="center">

## License

MIT

This README was created using [readme](https://github.com/KnickKnackLabs/readme).

</div>
