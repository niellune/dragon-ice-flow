## code-style
- **TypeScript strict** (`strict: true`); no `any` outside a typed boundary adapter, and then with a comment naming the boundary.
- **Formatting:** Prettier defaults; ESLint for correctness rules only, never style.
- **Imports:** absolute from `@/` for cross-slice imports; relative inside a slice. Import a slice only through its `index.ts` barrel.
- **Components** are function components; no class components, no default exports outside `pages/` and `app/`.

## architecture
- `src/` is laid out by **Feature-Sliced Design**: `app → pages → widgets → features → entities → shared`. Imports point downward only; a slice never imports a sibling slice (share via `shared/` or `entities/`, or compose in a higher layer). Decide a file's **layer → slice → segment** before writing it. Spec and decision guide: `reference/stacks/react-fsd/architecture.md`.
- Server-side code, scripts and infra are not governed by FSD.

## naming
- Components `PascalCase`, one component per file named after it (`ProductCard.tsx`); hooks `useX` (`useCart.ts`); slices and segments `kebab-case` folders (`features/add-to-cart/ui/`); props types `<Component>Props`; event handlers `onX` in props and `handleX` inside; tests `<name>.test.tsx` beside the code. Full rules and examples: `reference/stacks/react-fsd/naming.md`.

## testing
- Vitest with React Testing Library; a component test asserts behaviour through the DOM, never implementation details.
- Every `features/` and `entities/` slice ships a test beside its `model/` or `ui/`; `shared/` utilities are unit-tested.
- No `test.only` / `test.skip` in committed files; a flaky test is quarantined by name in a tracked issue, not skipped silently.
