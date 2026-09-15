# React + FSD naming

> Deep doc for the `react-fsd` pack. The one-paragraph summary lives in the applied `## Naming` section of `.context/rules.md`; this file is the full rule set with examples. Load by section.

## Folders

- Layers are fixed: `app`, `pages`, `widgets`, `features`, `entities`, `shared`.
- Slices and segments are `kebab-case`: `features/add-to-cart/`, `entities/user/ui/`.
- A feature slice is a **verb phrase** (`add-to-cart`, `auth-by-phone`); an entity slice is a **noun** (`user`, `product`); a page slice is the route (`checkout`, `product-details`); a widget is what it shows (`header`, `product-grid`).
- Every slice has an `index.ts` barrel and nothing imports past it.

## Files

- One component per file, file named after the component: `ProductCard.tsx`, `CartButton.tsx`.
- Hooks: `useCart.ts`, `useDebounce.ts`; one hook per file.
- Model and lib files `kebab-case`: `cart-store.ts`, `format-price.ts`.
- Tests beside the code: `ProductCard.test.tsx`, `format-price.test.ts`.
- Styles beside the component when co-located: `ProductCard.module.css`.

## Identifiers

| Thing | Rule | Example |
|---|---|---|
| Component | `PascalCase` | `ProductCard` |
| Hook | `use` + `PascalCase` | `useCart` |
| Props type | `<Component>Props` | `ProductCardProps` |
| Event prop | `on` + event | `onAddToCart` |
| Event handler | `handle` + event | `handleAddToCart` |
| Boolean prop / state | `is` / `has` / `can` prefix | `isOpen`, `hasError` |
| Store / model | noun + `Store` or `Model` | `cartStore` |
| Constant | `SCREAMING_SNAKE` | `MAX_ITEMS` |
| Enum-like union | `PascalCase` type, string literals `kebab-case` | `type Status = 'idle' \| 'loading'` |

## Exports

- Named exports everywhere; default exports only where a framework demands them (`pages/` route files, `app/` entry).
- A barrel re-exports the slice's public surface only; internal helpers stay unexported.

## Tests

- `describe` names the unit (`describe('ProductCard')`), `it` states behaviour in the user's words (`it('adds the product when the button is clicked')`).
- Queries by role and label, never by test id, unless the element has no accessible name.
