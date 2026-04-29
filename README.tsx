/** @jsxImportSource jsx-md */

import { readdirSync, readFileSync } from "fs";
import { join, resolve } from "path";

import {
  Heading, Paragraph, CodeBlock,
  Bold, Code, Link,
  Badge, Badges, Center, Section,
} from "readme/src/components";

// ── Dynamic data ─────────────────────────────────────────────

const REPO_DIR = resolve(import.meta.dirname);

// Count tests from .bats files
const testDir = join(REPO_DIR, "test");
const testCount = readdirSync(testDir)
  .filter((f) => f.endsWith(".bats"))
  .reduce((sum, f) => {
    const content = readFileSync(join(testDir, f), "utf-8");
    return sum + (content.match(/@test /g) || []).length;
  }, 0);

// ── README ───────────────────────────────────────────────────

const readme = (
  <>
    <Center>
      <Heading level={1}>ask</Heading>

      <Paragraph>
        <Bold>Ask questions from the terminal.</Bold>
      </Paragraph>

      <Paragraph>
        Pipe in context, attach files, or just type. Uses{" "}
        <Link href="https://github.com/anthropics/pi">pi</Link> as the runtime
        — any model, any provider.
      </Paragraph>

      <Badges>
        <Badge label="shell" value="bash" color="4EAA25" logo="gnubash" logoColor="white" />
        <Badge label="runtime" value="pi" color="7c3aed" href="https://github.com/anthropics/pi" />
        <Badge label="tests" value={`${testCount}`} color="green" />
        <Badge label="License" value="MIT" color="blue" href="LICENSE" />
      </Badges>
    </Center>

    <Section title="Install">
      <CodeBlock lang="bash">{`shiv install ask`}</CodeBlock>
    </Section>

    <Section title="Usage">
      <CodeBlock lang="bash">{`# Direct question
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
ask`}</CodeBlock>
    </Section>

    <Section title="How it works">
      <Paragraph>
        <Code>ask</Code> assembles context from stdin, files, and the clipboard,
        then sends it to <Code>pi -p</Code> in non-interactive mode. Context goes
        in XML tags before the prompt — models focus on what's near the end, so
        the question lands last.
      </Paragraph>

      <Paragraph>
        History is saved to <Code>~/.ask/history.jsonl</Code> — every prompt
        with a timestamp, for later recall.
      </Paragraph>
    </Section>

    <Section title="Development">
      <CodeBlock lang="bash">{`gh repo clone KnickKnackLabs/ask
cd ask && mise trust && mise install
mise run test   # ${testCount} tests`}</CodeBlock>
    </Section>

    <Center>
      <Section title="License">
        <Paragraph>MIT</Paragraph>
      </Section>

      <Paragraph>
        {"This README was created using "}
        <Link href="https://github.com/KnickKnackLabs/readme">readme</Link>.
      </Paragraph>
    </Center>
  </>
);

console.log(readme);
