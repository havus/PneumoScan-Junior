# Architecture Decision Records (ADRs)

This directory records the significant architectural decisions made on
PneumoScan-Junior, along with the context and trade-offs behind them.

An ADR captures **why** a decision was made — not just what the code does.
Code shows the *what*; ADRs preserve the reasoning so future contributors
(and future us) don't have to re-litigate settled questions or accidentally
undo a deliberate choice.

## When to write an ADR

Write one when a decision is:

- **Significant** — it shapes structure, tooling, or workflow (not a local
  implementation detail).
- **Hard to reverse** or costly to change later.
- **Non-obvious** — a reader might reasonably ask "why was it done this way?"

Small, easily-reversible choices don't need an ADR — a code comment is enough.

## Conventions

- **Format:** [MADR](https://adr.github.io/madr/) — see [`template.md`](template.md).
- **Filename:** `NNNN-short-title-in-kebab-case.md`, zero-padded and
  sequential (`0001-…`, `0002-…`). Numbers are never reused.
- **Status:** one of `Proposed`, `Accepted`, `Deprecated`, or
  `Superseded by NNNN`. ADRs are immutable once accepted — to change a
  decision, add a new ADR that supersedes the old one rather than editing it.

## How to add a new ADR

1. Copy [`template.md`](template.md) to `NNNN-your-title.md` (next number).
2. Fill it in and set the status.
3. Add it to the index below.

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-single-multistage-dockerfile-for-dev-and-prod.md) | Single multi-stage Dockerfile for dev and prod | Accepted |
