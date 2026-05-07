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

## Recommended skill triggers
- Stuck in tuning loop → `live-swe-reflection`
- Audit of a candidate model → `dssp-audit`
- Runtime error / repeated failure → `forgecode-recover-mode`
- Pre-deploy CI design → `ecc-prevent-mode`
- Commit / PR → `monogram-commit`
