```markdown
# Design System Document: The Curated Closet

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Atelier"**

This design system moves away from the utilitarian "inventory" look of typical utility apps and leans into the world of high-end editorial fashion. The goal is to make the user feel like a curator of their own boutique rather than a manager of a database. 

To achieve a "premium" feel, we break the standard mobile template by embracing **Editorial Asymmetry** and **Negative Space as a Luxury**. Instead of rigid, centered grids, we use intentional white space to let the photography (the clothes) breathe. Layouts should feel like a page from *Vogue* or *Kinfolk*—airy, intentional, and calm. We replace heavy structural lines with "tonal layering," creating a sense of depth that feels like stacked sheets of fine linen paper.

---

## 2. Colors: The Palette of Freshness
The color strategy is rooted in "Organic Cleanliness." We use a base of warm neutrals to provide a soft, human touch, punctuated by a sophisticated 'Sage' accent (`primary`) that evokes freshness and renewal.

### Functional Color Roles
- **Surface & Background:** Use `background` (#fafaf5) for the base canvas. It’s softer on the eyes than pure white, providing an immediate sense of "luxury" and "warmth."
- **The Sage Accent:** Use `primary` (#47645e) for moments of action. This is a muted, mature green that feels like high-end organic cotton—never neon, never digital.
- **Tonal Neutrals:** `secondary` (#5e5f5f) and its variants provide the structural contrast needed for secondary actions and metadata.

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders to separate sections.
Boundaries must be defined by background color shifts. To separate a header from a list, transition from `surface` to `surface-container-low`. To isolate a card, place a `surface-container-lowest` (#ffffff) card on a `surface-container` (#ecefe7) background. This creates a soft, modern boundary that feels architectural rather than "drawn."

### The "Glass & Gradient" Rule
For floating action buttons or navigation bars, use **Glassmorphism**. Apply `surface_bright` at 80% opacity with a `20px` backdrop blur. For high-impact CTA buttons, use a subtle linear gradient from `primary` (#47645e) to `primary_dim` (#3c5852) to provide a tactile, "weighted" feel that flat colors lacks.

---

### 3. Typography: Editorial Authority
We utilize a pairing of **Manrope** for structure and **Inter** for functional precision.

- **Display & Headlines (Manrope):** Large, bold, and authoritative. Use `display-lg` (3.5rem) for "Welcome" screens and `headline-sm` (1.5rem) for category headers. Tighten letter spacing (-2%) on headlines to create a bespoke, high-end look.
- **Body & Titles (Manrope):** `body-lg` (1rem) is your workhorse. It is spacious and highly legible. 
- **Labels (Inter):** For technical data—like fabric type or size—switch to `label-md` (0.75rem) in Inter. The slightly more "tech" feel of Inter distinguishes metadata from the editorial copy of Manrope.

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows are often "dirty." In this system, we use light and tone to create a sense of organized calm.

- **The Layering Principle:** 
    1. Base: `surface` (#fafaf5)
    2. Large Section: `surface-container-low` (#f3f4ee)
    3. Interactive Card: `surface-container-lowest` (#ffffff)
- **Ambient Shadows:** When a card must float (e.g., a garment detail modal), use a shadow color tinted with the `on-surface` color. 
    * *Spec:* `0px 12px 32px rgba(46, 52, 45, 0.06)`. This creates a natural, ambient lift rather than a harsh drop shadow.
- **The Ghost Border Fallback:** If accessibility requires a border (e.g., in high-contrast mode), use `outline-variant` (#aeb4aa) at **15% opacity**. It should be felt, not seen.

---

## 5. Components: Style & Execution

### Cards & Lists
*   **The Rule:** Forbid divider lines. 
*   **Execution:** Use `xl` (1.5rem) vertical spacing from the spacing scale to separate list items. Use `surface-container-high` as a background for "inactive" items and `surface-container-lowest` for active items.
*   **Rounding:** All garment cards must use the `xl` (1.5rem) corner radius to feel soft and approachable.

### Buttons
*   **Primary:** `primary` (#47645e) background with `on_primary` (#dffef7) text. Roundedness: `full` (pill-shaped) for a premium, boutique feel.
*   **Secondary:** `surface-container-highest` background with `on_surface` text. No border.

### Wardrobe Specifics
*   **Garment Chips:** Use `secondary_container` (#e3e2e2) with `lg` (1rem) rounding. These should feel like small fabric swatches.
*   **Input Fields:** Use `surface_container_low` for the fill. Do not use an underline. Use a `3.5` (1.2rem) padding to give text plenty of room to "breathe" inside the box.
*   **Empty States:** Use `display-sm` typography with high-contrast `on_surface_variant` (#5b6159) to turn an empty closet into a minimalist design statement.

---

## 6. Do’s and Don’ts

### Do
*   **DO** use asymmetric margins (e.g., 24px on the left, 32px on the right) for headline sections to create an editorial feel.
*   **DO** use "surface-nesting" to group related items (e.g., placing multiple white cards on a single warm gray section).
*   **DO** prioritize high-quality photography; the UI is the frame, the clothes are the art.

### Don’ts
*   **DON'T** use 100% black (#000000). Use `on_background` (#2e342d) for all "black" text to maintain the soft, organic vibe.
*   **DON'T** use standard 1px dividers. If you feel you need a divider, increase the white space instead.
*   **DON'T** use the `error` color for minor warnings. Reserve the deep red (#9f403d) only for destructive actions like "Delete Garment." Use `tertiary` (#576342) for "Freshness" tips or "Clean" indicators.

---

## 7. Spacing & Rhythm
The system relies on a **1.4rem (scale 4)** baseline. 
*   Use `spacing-8` (2.75rem) for major section breathing room.
*   Use `spacing-3` (1rem) for internal card padding.
*   Always err on the side of *too much* space rather than too little. In luxury design, space is the ultimate signifier of value.```