---
description: Apply DSSP 6-step audit methodology to an agent system or scaffold
---

Apply the `dssp-audit` skill workflow to the target the user describes.

## If target unspecified, ask:
- Agent name, repo URL, or paper reference
- Task class (SWE-bench / TerminalBench / research-browse / agentic-IO / etc.)
- Available evidence (paper sections, repo files, prior audits)

## Then execute the 6-step procedure:
1. POMDP 5-tuple extraction (S, A, π, ρ, τ, V)
2. Task-class profile + verifier soundness
3. 12-branch coverage table (★★ / ★ / △ / —)
4. Net activation score (sum: ★★=1.0, ★=0.5, △=0.25)
5. Predicted ceiling + top-3 bottlenecks
6. Latent advantages

## Output format
Markdown table per the dssp-audit skill template. Cite sources where claims are derived from external evidence (papers, repos, blog posts).
