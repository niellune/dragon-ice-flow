# src/ — Feature-Sliced Design

Stack pack `react-fsd` applied. Layers, top to bottom, imports point down only; a slice never imports a sibling slice; import a slice through its `index.ts` barrel.

```
app      -> composition root
pages    -> one slice per route
widgets  -> large composed blocks
features -> things a user does (verbs)
entities -> business nouns
shared   -> business-agnostic code, by segment
```

Segments inside a slice: `ui/`, `model/`, `api/`, `lib/`, `config/`. Full spec: `reference/stacks/react-fsd/architecture.md`; naming: `reference/stacks/react-fsd/naming.md`.
