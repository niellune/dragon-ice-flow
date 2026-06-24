# src/ — Feature-Sliced Design

Frontend code is organized by **Feature-Sliced Design**. Full spec:
[`reference/architecture/feature-sliced-design.md`](../reference/architecture/feature-sliced-design.md).

## Layers (top → bottom)

Imports may **only point downward**. A slice never imports a sibling slice.

```
app      → composition root: providers, router, global setup
pages    → full screens, one slice per route
widgets  → large composed UI blocks reused across pages
features → things a user does (verbs): add-to-cart, auth-by-phone
entities → business nouns (data + its UI): user, product
shared   → business-agnostic reusable code: ui kit, api client, lib, config
```

`app` and `shared` have no business slices (`app` is one root; `shared` is split by segment).

## Inside a slice — segments

`ui` (components) · `model` (logic/state/types) · `api` (requests) · `lib` (helpers) · `config` (constants).

Expose a slice's surface through its `index` barrel; import other slices only via *their* barrel.
