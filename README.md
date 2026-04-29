<div align="center">

# ask

**Ask questions from the terminal.**

Pipe in context, attach files, or just type. Uses [pi](https://github.com/anthropics/pi) as the runtime — any model, any provider.

![shell: bash](https://img.shields.io/badge/shell-bash-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![runtime: pi](https://img.shields.io/badge/runtime-pi-7c3aed?style=flat)](https://github.com/anthropics/pi)
![tests: 10](https://img.shields.io/badge/tests-10-green?style=flat)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

## Install

```bash
shiv install ask
```

## Usage

```bash
# Direct question
ask q "What is a mutex?"

# Pipe context from anywhere
shimmer web fetch "https://example.com" | ask q "Summarize this page"
cat error.log | ask q "What went wrong?"

# File context
ask q -f schema.sql "Explain these tables"
ask q -f a.rs -f b.rs "Compare these implementations"

# Clipboard context
ask q -c "What's this?"

# Model and provider selection
ask q -m gpt-5.4 "Quick answer"
ask q --provider anthropic -m sonnet "Explain this"

# Interactive menu
ask
```

## How it works

`ask` assembles context from stdin, files, and the clipboard, then sends it to `pi -p` in non-interactive mode. Context goes in XML tags before the prompt — models focus on what's near the end, so the question lands last.

History is saved to `~/.ask/history.jsonl` — every prompt with a timestamp, for later recall.

## Development

```bash
gh repo clone KnickKnackLabs/ask
cd ask && mise trust && mise install
mise run test   # 10 tests
```

<div align="center">

## License

MIT

This README was created using [readme](https://github.com/KnickKnackLabs/readme).

</div>
