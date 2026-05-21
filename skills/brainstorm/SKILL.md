# Brainstorm Skill

> A lightweight skill loaded on demand when the user (or you) needs to *explore possibilities* before committing.
>
> Not a workspace. No gate. No artifacts required.
> Output is conversational by default; saved to `planning/` only when explicitly asked.

## When to Use

The user signals one of these:

- "let's brainstorm…"
- "what are some ways to…"
- "I have a rough idea, help me think through it"
- "before I commit, what could this look like?"
- Or: you (Claude) notice the user is heading toward `planning` but the problem space hasn't been explored yet — *suggest* brainstorming first.

## When NOT to Use

- A clear, scoped request — just answer it. Don't pad with brainstorming theater.
- Bug fixes — facts, not options.
- The user explicitly says "give me your recommendation" or "just pick one" — pick.

## Modes (pick one, state it upfront)

### 1. Divergent — generate options

Goal: many possibilities, no judgment.

- Aim for **5–10 distinct directions**, not 3 polished ones.
- Make them genuinely different — different mechanisms, different scopes, different assumptions. Not "the same idea in different colors."
- Briefly note the *core trade-off* of each (e.g. "fast but rigid", "flexible but expensive"). One line.
- **No recommendation at the end of divergent mode.** Stop there. Wait for the user to point.

### 2. Convergent — narrow to a decision

Goal: take a set of options and reduce to 1–2.

- Use a small comparison: criteria the user cares about (cost, complexity, time-to-ship, reversibility), score each option roughly.
- Surface **what you'd need to know** to pick — open questions, not decisions.
- End with a recommendation *only if asked*, framed as "given X, I'd lean Y because Z."

### 3. Stress-test — find the holes

Goal: take a proposed idea and try to break it.

- What assumptions is the idea making? List them explicitly.
- What's the failure mode? What does this look like at 10x scale? At 1/10th scale?
- Who's the unhappy user? What does the regulator / security team / accountant say?
- What's the cheapest experiment that would falsify the idea?

### 4. Analogize — find prior art

Goal: borrow patterns from other domains or projects.

- "This problem is structurally similar to X because…"
- Pull from `wiki/` if relevant (existing concepts), otherwise general knowledge.
- Be honest about where the analogy breaks down.

## Rules of Engagement

- **Surface the mode you're using.** "Divergent — here are 7 directions." Don't blur modes.
- **Don't commit to anything during brainstorming.** No "I'll go build X." That's planning's job.
- **No writing to `planning/` unless asked.** Brainstorming output is by default conversational and ephemeral.
- **If the user wants to capture brainstorm output**, save to `planning/stories/_brainstorm-[topic].md` as a temporary note, status: `draft`. Convert to a real story later if it lands.
- **Avoid the "AI sycophancy spiral".** Don't say every option is great. Name trade-offs honestly.
- **One question at a time** when probing for more context. Don't fire 5 clarifying questions in one message.

## Anti-Patterns

- ❌ Generating 3 watered-down "options" that are actually the same idea
- ❌ Recommending one option in divergent mode (defeats the purpose)
- ❌ Brainstorming when the user asked for an answer
- ❌ Writing files during brainstorm (use chat — files come later in planning)
- ❌ Open-ended brainstorming with no time-box; if it sprawls past ~3 exchanges, switch to convergent or stop

## Declaration Wrapper

Every brainstorm response opens with this wrapper. Three reasons: it forces mode commitment (no blending), gives the user a clean surface to redirect (they edit `<mode>` to switch), and lets you self-check before generating.

```xml
<brainstorm>
  <mode>divergent | convergent | stress-test | analogize</mode>
  <subject>One sentence — what we're brainstorming about.</subject>
  <constraints>Time-box, scope limits, anything ruled out. If empty, "none".</constraints>
</brainstorm>
```

After the wrapper, the response continues in the mode's output template (below) — prose and tables, not more XML.

If the user replies "switch to convergent" or "stress-test option 2", open a new `<brainstorm>` block with the new mode. Don't blur.

## Output Templates

### Divergent

```
Mode: divergent — N directions

1. **[Name]** — [one-line description]. *Trade-off:* [X vs Y].
2. **[Name]** — [one-line description]. *Trade-off:* [X vs Y].
...

Want me to narrow these, stress-test one, or generate more?
```

### Convergent

```
Mode: convergent

| Option | [Criterion 1] | [Criterion 2] | [Criterion 3] |
|---|---|---|---|
| A | ... | ... | ... |
| B | ... | ... | ... |

Leaning [X] if [condition], [Y] if [condition].
Need to know: [open question].
```

### Stress-test

```
Mode: stress-test — [idea]

**Assumptions baked in:**
- ...

**Failure modes:**
- At scale: ...
- Edge case: ...
- Unhappy user: ...

**Cheapest falsifying experiment:** ...
```

## Transition Out

Brainstorming ends one of three ways:

1. **"Let's plan this"** → switch to the `planning` workspace, carry the chosen direction forward.
2. **"Not now"** → done; if anything was worth keeping, optionally save to `planning/stories/_brainstorm-[topic].md`.
3. **"Just do it"** → if scope is tiny, write a `<task>` directly under `feature-development`. The brainstorm itself is enough context; don't force a planning artifact.
