# Feature-Sliced Design (FSD)

> The canonical architecture for frontend code under `src/`. This is the single source
> for *how app files are organized*. Other files (CLAUDE.md, rules.md, the workspaces)
> carry a one-line rule and point here. Backend / non-UI code is out of scope.

## Why

FSD makes a frontend codebase **readable** (open `pages/`, `features/`, `entities/` and you
see what the app does), **maintainable** (no circular dependencies), and **scalable**
(a change is isolated to one slice). The trade-off is a bit of upfront structure; for
anything past a prototype it pays for itself.

Reference: Feature-Sliced Design methodology — https://feature-sliced.design

## The three-level hierarchy

```
src/<layer>/<slice>/<segment>/...
        │       │        │
        │       │        └─ technical purpose: ui, model, api, lib, config
        │       └────────── business domain: user, product, cart, auth-by-phone …
        └────────────────── architectural role (fixed set, see below)
```

### 1. Layers (fixed, top → bottom)

A file may **only import from layers strictly below it.** Never sideways, never up.

| Layer | What lives here | Example |
|---|---|---|
| `app` | App-wide setup: providers, router, global styles, store init. The composition root. | `app/providers`, `app/router` |
| `pages` | Full pages/screens, composed from widgets and features. One slice per route. | `pages/home`, `pages/product-details` |
| `widgets` | Large self-contained UI blocks combining features/entities. | `widgets/header`, `widgets/product-card` |
| `features` | A thing a user *does* with entities (verbs). | `features/add-to-cart`, `features/auth-by-phone` |
| `entities` | A thing the business *has* (nouns). Data + its UI representation. | `entities/user`, `entities/product` |
| `shared` | Reusable, business-agnostic code: UI kit, API client, helpers, config. | `shared/ui`, `shared/api`, `shared/lib` |

> `app` and `shared` are the two layers that do **not** use business slices — `app` is a
> single composition root; `shared` is organized by segment only (`shared/ui`, `shared/api`, …).
>
> (Historical note: an older `processes` layer is **deprecated** — don't add it.)

### 2. Slices — business domains inside a layer

`features/add-to-cart`, `entities/user`, `pages/checkout`. Slices partition a layer by
**domain**, so all the code for one concern sits together.

**A slice must not import a sibling slice on the same layer.** If two slices need to share,
either lift the shared part down into `shared/` or `entities/`, or compose them in a higher
layer (a `widget` or `page`). This is what keeps the graph acyclic.

### 3. Segments — technical purpose inside a slice

| Segment | Holds |
|---|---|
| `ui` | Components, anything rendered |
| `model` | Business logic, state, stores, types |
| `api` | Backend requests for this slice |
| `lib` | Slice-local helpers/utilities |
| `config` | Constants, feature flags, config |

Segments are flexible — add others if a slice needs them. Most slices only need `ui` + `model`.

## Public API rule (the barrel)

Every slice exposes its surface through a single public entry point — an `index` barrel at
the slice root (e.g. `entities/user/index.ts`).

- **Import a slice only through its `index`.** Never reach into its internal files
  (`entities/user/model/store.ts`) from outside.
- The barrel re-exports only what's intended for outside use, so a slice can be
  reorganized internally without breaking importers.

```ts
// entities/user/index.ts
export { UserCard } from './ui/UserCard'
export { useUser } from './model/useUser'
export type { User } from './model/types'
```

## Concrete example

```
src/
├── app/
│   ├── providers/
│   └── router/
├── pages/
│   └── product-details/
│       ├── ui/
│       └── index.ts
├── widgets/
│   └── header/
│       ├── ui/
│       └── index.ts
├── features/
│   └── add-to-cart/
│       ├── ui/        # AddToCartButton
│       ├── model/     # logic, store
│       └── index.ts
├── entities/
│   └── product/
│       ├── ui/        # ProductCard
│       ├── model/     # types, selectors
│       ├── api/       # fetchProduct
│       └── index.ts
└── shared/
    ├── ui/            # Button, Input — the UI kit
    ├── api/           # configured HTTP client
    ├── lib/           # formatDate, cn, …
    └── config/        # env, constants
```

## Quick decision guide

- Is it a route/screen? → `pages`
- A big composed UI block reused across pages? → `widgets`
- Something the user *does* (verb)? → `features`
- A business noun (data + its card/row)? → `entities`
- Business-agnostic and reusable anywhere? → `shared`
- Wiring it all together (providers, router)? → `app`

When unsure between `feature` and `entity`: entities are what the business *sells/has*;
features are what users *do* with them.

## Checklist before writing a file under `src/`

- [ ] Picked the correct **layer** (and it only imports from layers below).
- [ ] Picked/created the right **slice** (no sibling-slice imports).
- [ ] Put the file in the right **segment** (`ui`/`model`/`api`/`lib`/`config`).
- [ ] Exposed anything external via the slice's **`index` barrel**; imported other slices via *their* barrels.
