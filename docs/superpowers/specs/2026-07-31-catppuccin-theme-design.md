# Quartz Catppuccin Theme Design

## Goal

Replace the Quartz default visual theme with the standard Catppuccin theme while preserving the existing wide Base homepage layout.

## Design

- Keep `@quartz-themes/core` as the Quartz 5 theme transformer.
- Select `catppuccin` with `mode: both` so Quartz continues to support its light/dark toggle.
- Install and lock `@quartz-themes/catppuccin` rather than relying on build-time automatic installation.
- Keep the existing `custom.scss` homepage rule unchanged because it is functional layout CSS, not a competing visual theme.
- Do not alter notes, Bases, Quartz components, navigation, or publishing behavior.

## Verification

- A clean dependency installation succeeds on Node 22.
- Quartz builds all staged vault content without theme resolution errors.
- Generated CSS contains Catppuccin theme output.
- The homepage still uses the wide two-column desktop grid rule.

