# Project priors — ML production

## Track
Production ML system. Live business KPI; daily iteration. Examples: government bid prediction, ranking model, demand forecast.

## Stack assumptions
- Python 3.10+
- ML: NGBoost / XGBoost / scikit-learn / pandas / pyarrow
- EC2 GPU for training, local CPU for inference. Drop-in compatible pkls required.
- AWS S3 for data lake.

## Commands (fill in for project)
- `pytest tests/`
- `python -m cli.run_inference`
- `python -m cli.run_pipeline`

## Discipline
- KPI must improve or be neutral; regressions are reverts unless justified.
- Evaluate per-segment (per bracket / per cohort), not aggregate-only.
- Bootstrap CI on every comparison (≥1000 resamples).
- Version naming explicit (e.g., v4.x.7g → v4.x.7h). Increment on substantive change.
- Local CPU requirements ≠ EC2 GPU requirements. Two requirements files.

## Forbidden
- Modifying numeric library version pins without checking upstream issues.
- Aggregating across cohorts without per-cohort breakdown.
- Pushing model artifacts to git (use S3 / artifact store).
- Editing `data/production/` without explicit confirmation.

## Skill activation policy

| Skill | Tier | When |
|---|---|---|
| `monogram-commit` | T1 lifecycle | every `git commit` (auto via PreToolUse hook) |
| `forgecode-recover-mode` patterns | T1 lifecycle | tool errors, doom-loop, pending todos (auto via hooks) |
| `dssp-audit` | T3 explicit | invoke via `/audit` when evaluating a candidate model architecture |
| `live-swe-reflection` | T2 priors | stuck in tuning loop / repeated failure |
| `ecc-prevent-mode` | T2 priors | designing pre-deploy CI gate / governance |
| `gepa-reflection` | T3 explicit | invoke via `/reflect` when refining prompt with ≥3 failures |

Track A primary triggers: `dssp-audit` (model architecture eval) + `ecc-prevent-mode` (CI gate design).
