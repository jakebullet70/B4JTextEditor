# B4JEditor

A full-featured programmer's text editor for the desktop, inspired by Microsoft
[`edit`](https://github.com/microsoft/edit). Clean, native desktop styling with multi-document
tabs, syntax highlighting, find/replace, and per-document encoding control.  

B4J programmers can learn from it, take and use any code they want.  

## Overview

B4JEditor is a JavaFX desktop application written in **B4J** (B4X / Basic4Java). The editing
surface is built on the **RichTextFX `CodeArea`** — a virtualized, gutter-aware text component —
giving it a line-number gutter, smooth scrolling over large files, and regex-driven syntax
highlighting. The entire UI is constructed in code (no `.bjl` layout file) on a JavaFX
`AnchorPane`, and the whole window chrome is themeable (Light/Dark) by overriding JavaFX's modena
looked-up colors.

## Features

- **Multi-document tabs** — each tab keeps its own text, undo history, syntax highlighting, and
  modified (`*`) state. New (`Ctrl+N`), Close (`Ctrl+W`), switch with `Ctrl+PageUp/PageDown`.
- **File operations** — New / Open / Save / Save As / Exit, with per-document save prompts on close
  and a window-close guard.
- **Edit operations** — Undo / Redo / Cut / Copy / Paste / Select All.
- **Syntax highlighting** — multi-language (Java, Python, JSON, B4X, Markdown), auto-detected by
  file extension with a `View ▸ Language` override. One regex-driven engine, theme-colored token
  categories (comment / string / char / annotation / number / type / keyword).
- **Find / Replace bar** — non-modal floating widget (`Ctrl+F` / `Ctrl+R`): Prev/Next with an
  "x of y" count, Replace / Replace All, **Match case**, **Whole word**, **Regex** (with `$1` group
  references), and **All tabs** (search/replace across every open document). Esc to close.
- **Go to Line** (`Ctrl+G`).
- **Word wrap** (`Alt+Z`).
- **Setup panel** (Help ▸ Setup) — global settings: theme (Light/Dark), font family + size, tab
  size, soft/hard tabs, line numbers, word wrap, highlight current line, auto indent, default
  encoding, default EOL. Persisted to `settings.properties`.
- **This Document panel** (View ▸ This Document) — the active document's encoding, line endings, and
  read-only toggle.
- **Multi-encoding I/O** — UTF-8, UTF-8 BOM, UTF-16 LE, UTF-16 BE with BOM detection on open;
  LF/CRLF detected on open and re-applied on save.
- **Read-only documents** — per-document, seeded from the file's read-only attribute on open.
- **Recent files** — MRU list under File ▸ Open Recent, persisted across sessions.
- **Drag-and-drop** — drop files onto the window to open them.
- **Status bar** — Ln / Col / encoding / EOL / language / modified indicator.
- **Keyboard-first** — Alt menu mnemonics and Ctrl accelerators throughout.

## Written in

- **B4J** (B4X / Basic4Java) — RAD JavaFX desktop development by [Anywhere Software](https://www.b4x.com/).
- Target: `AppType=JavaFX` desktop application.

### B4J libraries

`jcore`, `jfx`, `jxui`, `javaobject`.

## Java JARs used

The RichTextFX editor stack is referenced via `#AdditionalJar:` in the project. The jars live in
`C:\dev\b4x\b4j\ext_libs`:

| JAR | Version | Purpose |
| --- | --- | --- |
| richtextfx | 0.11.7 | The `CodeArea` editor surface (gutter, virtualized text, style spans) |
| flowless | 0.7.4 | Virtualized scroll pane (`VirtualizedScrollPane`) wrapping the CodeArea |
| undofx | 2.1.1 | Undo/redo manager backing the CodeArea |
| wellbehavedfx | 0.3.3 | Event-handler / key-binding support for RichTextFX |
| reactfx | 2.0-M5 | Reactive event streams used by RichTextFX |

> Fallback: if a future JDK/JavaFX upgrade breaks richtextfx 0.11.7, drop to 0.11.2.

## Build / run

- Project file: `Editor.b4j`.
- Build in the **B4J IDE** (or via the b4j MCP tools). Output jar: `Objects/Editor.jar`.
- Entry point: `AppStart` in `Editor.b4j` — the UI is built entirely in code (no layout file is
  loaded).
