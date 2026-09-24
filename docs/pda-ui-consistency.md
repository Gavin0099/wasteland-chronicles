# Survivor PDA UI consistency — 2026-09-22

The maintained skill is `.agents/skills/wc-survivor-pda-design-system/SKILL.md`.
The former v1 entry routes to it; repo AGENTS.md requires reading it for UI work.
The skill is automatically discoverable in `.agents/skills` and includes Codex UI metadata.

Implementation uses shared `pda_tokens.gd`, generated theme type variations, a reusable
skill rank row and a read-only character/supplies sheet. No external asset download.
Verified reference links and their applications are in the skill's `references/resources.md`.
Both skills pass skill-creator quick_validate.

The character sheet shows actual resources, capacity, skills and selected traits.
Opening/closing it leaves the world SHA unchanged. Trait copy reflects C2, and blocked
encounter tooltips use readable causes rather than engine codes. C2 option ordering,
visibility, costs and effects remain unchanged. No C2-B player-experience claim.

Evidence: `artifacts/pda-ui-20260922/results.json` records 38 suites with exit 0 and no
SCRIPT ERROR. Screenshots cover 1280×720 and 1152×648. Known existing shell shutdown
CanvasItem/ObjectDB/RID diagnostics remain and are preserved in logs.

Owner chose small turn-based combat for the following gameplay slice; this UI delivery
does not itself claim equipment or combat completion. No push.
