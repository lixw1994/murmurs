<!-- paseo-agent-team:begin -->
# AGENTS.md — Engineering Workflow

This project uses the paseo-agent-team engineering discipline. Any coding agent working in this repository must follow this file.

## Engineering discipline (OpenSpec workflow)

This project manages changes with OpenSpec. The default schema is `spec-driven-with-adr` (proposal → specs → design → adr → tasks); see `openspec/config.yaml`.

- **Large changes go through the OpenSpec pipeline**: new capabilities, public interface / data model changes, new dependencies, cross-module work. Start a change with the `openspec-new-change` skill, complete all five artifacts, apply, then archive. Small changes (typos, small bugs, local refactors) go straight in.
- **Exploratory spikes take the light path**: prototypes may use `--schema minimalist` (specs → tasks) or skip the process entirely. When a validated spike graduates to a real implementation, return to the full pipeline and backfill design and ADR; spike code must not be promoted as-is.
- **Two sources of truth**: `openspec/specs/` records current system capabilities; `adr/` records current architecture decisions. Read both before designing. Accepted ADRs are immutable — supersede them with new ADRs (see `adr/README.md`).
- **Visualize complex content**: when explaining complex structures, flows, or relationships — in docs, artifacts, or replies — prefer visualization (Mermaid diagrams, tables, directory trees) over long prose.
- **Architecture document**: keep an up-to-date architecture overview at `docs/architecture.md` (create it if missing); update it whenever a structural change lands.
- **Development stage**: target the current product model. Do not add backward-compatibility fields, legacy branches, or migration/reset mechanisms unless the user explicitly requires them.
- **Current documentation**: update affected guides and both README languages in the same change as user-facing behavior, setup, or requirement changes. Verify affected commands and links, remove obsolete instructions and temporary migration/reset notes, and document shipped behavior only. Follow `CONTRIBUTING.md` when present.

## Paseo Agent Team (optional)

- **Solo by default**: complete tasks yourself. Only delegate when the user explicitly requests collaboration. Installed tools and environment variables never activate a team.
- **Paseo enhancement**: when requested, use the Paseo Agent Team plugin or available native Paseo tools and skills. The user chooses member roles, profiles, and workspace isolation, then assigns work through their conversations. Review results before integration.
- **Tech Lead ownership**: the existing primary agent owns architecture, core development, maintenance, and all `openspec/` and `adr/` edits. Keep hard problems and final decisions with the lead; helpers follow their assigned scope. Do not spawn an extra lead.
- **Helper roles**: Researcher handles external information only, returning sourced findings and writing requested reports only under `.paseo-agent-team/handoff/`. Writer may read the project but writes only `docs/`, following the available tech-doc skill. Worker is used sparingly for simple, explicitly bounded, independently verifiable chores in an isolated worktree; it stops and reports when architectural judgment or complex work is required. Custom helpers follow their user-defined responsibilities and current task under the same Tech Lead ownership and review rules. Custom standing responsibilities are optional. Creating a member sends no assignment; wait for explicit work through its conversation. Helpers do not create further agents.
- **Handoff and review**: provide context, concrete requirements, expected output, and acceptance criteria. Continue independent work while a helper runs; wait only when blocked. Require condensed conclusions and change summaries. The lead reviews all results personally, including worker code line by line.
- **Independent workflow**: when Paseo is unavailable, continue the OpenSpec engineering workflow solo. The default installer has no Paseo dependency.
- **Runtime state**: the plugin creates `.paseo-agent-team/` only when needed. It contains local team state and project-specific custom presets, is ignored by Git, and is not a source of architectural truth. Presets save role/configuration preferences; selecting or saving one does not create a member. Creation snapshots that configuration; later conversation messages supply assignments.
<!-- paseo-agent-team:end -->
