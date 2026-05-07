---
description: Python code style — applies to all *.py files
paths: ["**/*.py"]
---

- Type hints on every function signature (PEP 484).
- f-strings, not %-format or `.format()`.
- `pathlib.Path`, not `os.path.join`.
- No `print` debugging in committed code; use `logging` or breakpoints.
- pytest with `parametrize` for table tests.
- Avoid `dataclass` with mutable default values; use `field(default_factory=...)`.
- Prefer `dict | None` over `Optional[dict]` (PEP 604, Python 3.10+).
- Imports: stdlib → third-party → local, alphabetized within group.
