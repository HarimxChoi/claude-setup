---
description: LaTeX paper style. Path-scoped to paper/**/*.tex.
paths: ["paper/**/*.tex", "**/*.tex"]
---

- `\cref{}` over `\ref{}` (cleveref).
- `siunitx` for numbers + units (`\SI{5}{kg}`).
- BibTeX entries verified against arxiv ID.
- Theorems numbered per section, not globally.
- `\footnote` sparingly; prefer parenthetical or main text.
- No `\\` for line breaks in paragraphs (paragraph-level only).
- Use `\enquote{}` (csquotes) for "quotes", not raw `"..."`.
