# AGENTS.md
<!-- governance-baseline: overridable -->
<!-- baseline_version: 1.0.0 -->
<!-- This file is repo-specific. Edit freely. -->
<!-- DO NOT edit AGENTS.base.md — it is a protected framework file. -->

This file extends `AGENTS.base.md`.
All rules in `AGENTS.base.md` are non-negotiable and apply to this repo unconditionally.

Add repo-specific rules below.
Fill in each section below, or write `N/A` if the section is not applicable to this repo.

Quick start:

1. Start with the top 1-3 risky paths in this repo, not a full policy rewrite.
2. If you already have a checklist / runbook / test convention, copy that wording here instead of inventing new terms.
3. If a section truly does not apply, keep `N/A` and move on.

---

## AI Governance Update Intent Rule

When the user asks to "Update AI Governance to latest" or 「把 AI Governance
更新到最新」, do not interpret this as checking whether `AGENTS.md`,
`AGENTS.base.md`, or local governance instruction files are clean.

First determine whether the repository consumes AI Governance through a
submodule path such as:
- `ai-governance-framework`
- `.ai-governance-framework`

If a governance submodule exists, the request maps to the governed submodule
update workflow. The agent must compare the nested governance HEAD with the
approved target upstream HEAD, preferably through the governed submodule updater
dry-run path.

The agent must not claim AI Governance is already current based only on:
- `AGENTS.md` unchanged
- `AGENTS.base.md` unchanged
- parent repository `HEAD == origin/main`
- `git pull --ff-only` reporting already up to date
- clean parent repository working tree

A valid `already_current` conclusion for a submodule consumer must include:
- governance submodule path
- nested governance HEAD
- target upstream framework HEAD
- dry-run update result

For completion or partial-completion update reports, retain the first three
non-empty lines as 結果 / 原因 / 下一步 (translated in other session languages).
Explain local completion, commit/push/merge state, and important unverified
behavior in plain language before the complete adoption table and technical
fields. Other task classes retain their existing rendering rules. Follow
`governance/AI_GOVERNANCE_UPDATE_PROTOCOL.md`; suggested actions do not grant
authorization. Installed hooks or writers do not prove real-session execution.

Required technical evidence shape (after the plain-language opening; not a
replacement for the complete adoption table):

```text
AI Governance update check: <already_current | update_available | updated | manual_update | destructive_manual_update | not_submodule_consumer | not_verified>
governance submodule path: <path | NOT FOUND | NOT CHECKED>
nested governance HEAD: <sha | NOT CHECKED>
target framework HEAD: <sha | NOT CHECKED>
dry-run: PASS | FAIL | NOT RUN
update mode: already_current | fast_forward | detached_target_checkout | NOT CLAIMED
parent repo commit: <hash | NOT NEEDED | NOT CREATED>
governance maturity summary: RUN | NOT RUN | NOT AVAILABLE
user-facing adoption status: <minimal | partial | full_candidate | not_governed | unknown | NOT REPORTED>
framework topology: <copy_based | repo_owned_framework_path | submodule_consumer | unknown | NOT REPORTED>
static self-contained: yes | no | unknown | NOT REPORTED
runtime capable: not_checked | <other explicit value | NOT REPORTED>
hook framework root: inside_repo | external | absent | unknown | NOT REPORTED
framework pin freshness: <current_vs_local_tracking | behind_local_tracking | ahead_or_diverged_vs_local_tracking | unknown | not_applicable | NOT REPORTED>
repo-specific rules: true | false | NOT REPORTED
domain contract: true | false | NOT REPORTED
validator surface: true | false | not_checked | NOT REPORTED
memory workflow surface: <value from summary | NOT REPORTED>
adoption cannot claim: <short cannot-claim list from the summary | NOT REPORTED>
human_readable_adoption_summary: REPORTED | NOT REPORTED
```

### Response Envelope Boundary

- Response envelope contract version: v0.8. Compact human responses are the
  default.
- Ordinary expanded reporting retains three trigger IDs:
  `full_evidence_request`, `owner_decision_required`, and `failed_or_partial`.
- Failed/partial work and owner decisions may remain compact only when the
  blocker, ability to proceed, risks, non-claims, and required choice or
  authorization stay clear. Expand when a short answer cannot preserve those
  boundaries, canonical evidence cannot be preserved, or full evidence is
  requested. Existing F-7 expanded-report exceptions remain.
- Keep all raw fields in canonical evidence; display exact tokens only when
  their value affects the current decision / claim boundary or full evidence is
  requested. Explain each displayed token in plain language.
- The three-line preface applies to completion-class reports. Diagnosis,
  review, and concept requests use the contract's Engineering Explanation shape
  without forcing an irrelevant next action.
- Keep validation commands, counts, and diagnostics under `驗證` or
  `evidence_refs`; use `注意` only for one decision-relevant limitation.

If the session only updates `AGENTS.md` or other local instruction files, report
that as an instruction-file update and mark the AI Governance Framework update
as `not_verified`. Do not collapse instruction-file sync into framework update
status.

Invalid conclusion:

```text
AGENTS.md was updated and the parent repo is up to date, so AI Governance is current.
```

Valid partial conclusion:

```text
結果：這次只更新了指令文件，尚不能確認治理框架更新完成；沒有建立提交，上傳與合併狀態未確認。
原因：治理框架的版本與導入狀態尚未檢查。
下一步：先檢查框架版本及導入狀態，再判定是否需要更新；不因此取得更新或上傳授權。

AI Governance update check: not_verified
governance submodule path: NOT CHECKED
nested governance HEAD: NOT CHECKED
target framework HEAD: NOT CHECKED
dry-run: NOT RUN
update mode: NOT CLAIMED
parent repo commit: NOT CREATED
governance maturity summary: NOT RUN
user-facing adoption status: NOT REPORTED
human_readable_adoption_summary: NOT REPORTED
```

### AI Governance Check Vs Update Intent

Classify the user's wording before acting:

`check` intent examples:
- "檢查 AI Governance 是否最新"
- "確認 AI Governance 有沒有更新"
- "verify AI Governance version"
- "check whether AI Governance is up to date"

Action: verify-only. Do not update the submodule pointer.

`update` intent examples:
- "幫我更新最新版 AI Governance"
- "把 AI Governance 更新到最新"
- "更新 AI Governance 到最新版"
- "Update AI Governance to latest"

Action: route the request to `governance_tools.f7_full_update` as the primary
orchestrator. This applies to "幫我更新最新版 AI Governance" and equivalent
natural-language update requests even when the user does not name F-7. The
governed submodule updater is an F-7 backend/stage, not a substitute for the
complete F-7 report.

For `update` intent, do not stop after direct HEAD comparison when nested
governance HEAD differs from target framework HEAD. A direct HEAD comparison may
establish `update_available`, but it is not a completed update.

If the repository is a submodule consumer and no blocker exists, the agent must
continue from `update_available` to the governed update step.

The agent must not ask "要不要我幫你更新？" after the user has already used
update wording. Ask only when the user intent is ambiguous or when a blocker
requires user decision.

AI Governance update status must use one of these fixed values only:

- `already_current`: nested governance HEAD already matches the target framework HEAD.
- `update_available`: nested governance HEAD differs from the target framework HEAD, but update has not yet been applied.
- `updated`: governed update flow completed and nested governance HEAD now matches the target framework HEAD.
- `manual_update`: the agent changed a governance submodule pointer, gitlink,
  framework checkout, or lock file without governed updater/F-7 evidence. This
  may report what changed, but must not accompany `already_current`,
  `updated`, `completed`, `latest`, or full-adoption claims.
- `destructive_manual_update`: a `manual_update` path that discarded local
  framework checkout state, such as nested worktree changes or untracked files.
  The final report must list the discarded modified and untracked paths.
- `blocked`: update could not proceed due to dirty worktree, staged changes, dirty nested submodule, dry-run failure, missing path, or other explicit blocker.
- `not_submodule_consumer`: repository does not consume AI Governance through a submodule.
- `not_verified`: the agent could not safely determine current or target governance state.

For update intent, `update_available` is an intermediate state, not a final
successful outcome. Final response must be one of:
`already_current | updated | manual_update | destructive_manual_update | blocked | not_submodule_consumer | not_verified`.

This baseline is a propagated, managed consumer instruction copy of the
canonical manual-update reporting vocabulary in
`governance/AI_GOVERNANCE_UPDATE_PROTOCOL.md`. It is intentionally explicit so
agents can see the rule in the consumer repo, but it must not drift into an
independent definition of `manual_update` or `destructive_manual_update`.

Updating the governance submodule pointer does not automatically authorize a
parent repository commit or push unless the user explicitly requested commit/push
or the active workflow already defines commit/push as part of the governed
update task.

If no parent repo commit is created, report:
`parent repo commit: NOT CREATED`.

Manual update paths are allowed only as an honest fallback report. They are not
evidence that the governed update flow ran.

Manual update conclusion template:

```text
AI Governance update check: manual_update
ai_governance_update_result: REPORTED
framework_update_status: manual_update
governance maturity summary: <RUN | NOT RUN | NOT AVAILABLE>
adoption_status: <from maturity summary | unknown>
human_readable_adoption_summary: <REPORTED | NOT REPORTED>
reason: governed updater/F-7 was not used
claim boundary: manual pointer/lock/checkout changes may be reported; do not claim completed/latest/full adoption
```

Destructive manual update conclusion template:

```text
AI Governance update check: destructive_manual_update
ai_governance_update_result: REPORTED
framework_update_status: destructive_manual_update
discarded_modified_paths: <list | none reported>
discarded_untracked_paths: <list | none reported>
governance maturity summary: <RUN | NOT RUN | NOT AVAILABLE>
human_readable_adoption_summary: <REPORTED | NOT REPORTED>
claim boundary: destructive local cleanup occurred; do not claim completed/latest/full adoption
```

Before discarding local state in a nested framework checkout, first inspect and
record the modified and untracked paths that would be discarded. The final
operator-facing report must include that discarded-path inventory. A statement
such as "cleaned the submodule" is not a substitute for the inventory.

When `governance_maturity_summary` is available, the final update report must
surface the user-facing adoption status summary. Do not collapse this into
`adoption_doctor: findings 0`, `governance_version_check: compatible`, a clean
build, or a submodule pointer update. Those signals do not tell the operator
which governance surfaces are present.

When `human_readable_adoption_summary` is present, relay its table rows as a
table for the operator. This baseline is only the execution-surface projection;
the canonical adoption-summary contract lives in the framework's
`governance/AI_GOVERNANCE_UPDATE_PROTOCOL.md`, and the concrete output
projection is produced by `governance_tools/governance_update_reporting.py`. Do
not report only machine-readable fields such as `user_facing_status`,
`framework_topology`, or `runtime_capable` while omitting the table. If the
table cannot be produced or relayed, report
`human_readable_adoption_summary: NOT REPORTED` with the reason.
Also report `update_report_complete=false` and
`completion_claim_allowed=false`, and do not claim a complete AI Governance
update report. This applies to updated, already-current, blocked, and
fallback/manual terminal outcomes. A blocked update may still have a complete
report when the real table is relayed; report completeness does not mean the
update succeeded.

### Test Quality Expectations

For non-trivial behavior changes, do not report happy-path-only tests as
sufficient evidence.

- Reproducible bug fixes need regression tests when feasible.
- Expected values must come from a specification, invariant, reviewed fixture,
  or other independent source, not copied production logic.
- Mock-only assertions are weak evidence unless the test also asserts
  observable behavior, state, output, or persisted effect.
- Domain validators need pass/fail fixtures, and fixture evidence is strongest
  only when a focused harness actually executes the validator against those
  fixtures.

Report-only `test_signal_quality_audit` output can help reviewers find weak
signals. It does not prove tests are industry-grade, does not prove domain
correctness, and does not create enforcement.

If the update path used a direct submodule fast-forward plus lock-file update
instead of F-7 or `adopt_governance.py`, run or relay
`governance_maturity_summary` before final reporting. If it cannot be run,
state:

```text
governance maturity summary: NOT RUN
reason: <why it was not run>
claim boundary: update commit/build evidence only; adoption completeness was not reported
```

### F-7 Full Update Semantics

F-7 is the AI Governance Full Update workflow. The governed submodule update is
Stage 1 of F-7, not the whole workflow.

When the user asks to update or adopt the latest AI Governance, including
"幫我更新最新版 AI Governance" and equivalent natural-language wording, the
request routes to F-7 even when the user does not name F-7. F-7 must execute the
full adoption/update workflow or explicitly report a blocker.
A submodule pointer update alone is insufficient and must be reported as
`partially_updated`, not completed.

Required stages:

1. framework pointer update
2. repo-local instruction refresh
3. memory writer coverage check
4. hook / validator coverage check
5. existing memory normalization status check
6. final adoption status report backed by `governance_maturity_summary`

Layered status fields:

```text
framework_pointer: updated | already_current | blocked | not_present | not_verified
repo_local_instruction: updated | already_current | blocked | missing | not_verified
memory_writer_coverage: verified | updated | blocked | missing | not_applicable | not_verified
hook_validator_enforcement: verified | updated | blocked | missing | not_applicable | not_verified
existing_memory_normalization: completed | needed | blocked | not_applicable | not_verified
governance_maturity_summary: present | not_available | not_run
human_readable_adoption_summary: reported | not_reported
final_status: full_update_completed | already_current | partially_updated | blocked | not_submodule_consumer | not_verified
```

`full_update_completed` may be used only when every required stage is
`updated`, `already_current`, `verified`, `completed`, or `not_applicable`.
If any required surface is `missing`, `needed`, `blocked`, or `not_verified`,
the final status must not be `full_update_completed`.

The final adoption status report must be operator-facing. It must follow the
framework's canonical adoption-summary contract in
`governance/AI_GOVERNANCE_UPDATE_PROTOCOL.md`; the concrete table and
final-report projection are produced by
`governance_tools/governance_update_reporting.py`. When
`human_readable_adoption_summary` is present, relay its rows as a table. The
machine-readable fields remain useful evidence, but they are not a substitute
for the operator-facing table.

`adoption_doctor: findings 0`, `governance_version_check: compatible`, a clean
build, or a framework pointer update is not a substitute for the final adoption
status report. If `governance_maturity_summary` cannot be produced, report
`governance_maturity_summary: not_available` or
`governance_maturity_summary: not_run` with the reason.

This semantic update defines the required F-7 contract. It does not by itself
implement updater automation for all stages.

NOT CLAIMED unless separately implemented and validated:
- updater automation performs all F-7 stages
- hooks changed
- validators changed
- artifact schema changed
- existing memory was normalized

## AI Governance Memory Workflow Router
<!-- governance:key=memory_workflow -->

- Before claiming completion for any change touching `memory/**`, run `python -m governance_tools.memory_workflow --check --repo .`.
- For memory completion claims, run `python -m governance_tools.memory_workflow --check --repo . --run-guard` and report blockers before claiming DONE.
- Use the canonical memory writer for session-derived memory; do not edit memory records as ordinary markdown.
- Canonical writer signal: `governance_tools.memory_record` / `memory_record.py`.

## Repo-Specific Risk Levels
<!-- governance:key=risk_levels -->

- **HIGH**: 變更 `simulation/` 核心模擬引擎、世界狀態（`world_state.gd`、`settlement_state.gd`）、8 階段離散日生命週期時序、人口生命總量守恆不變量。
- **MEDIUM**: 調整商品敏感度、定價公式、遷徙門檻、治安衰退/掠奪公式、NPC 註冊表。
- **LOW**: 規格文件更新（`docs/`）、Walkthrough、純測試代碼新增（不影響既有斷言）。

## Must-Test Paths
<!-- governance:key=must_test_paths -->

- `simulation/`: 任何程式碼變更必須執行全套 Godot 測試套件（`tests/test_*.gd`），且 Exit Code 必須為 0。
- `tests/`: 任何新切片加入時，必須具備雙軌決定論 SHA-256 重播驗證與全域不變量檢查。

## L1 → L2 Escalation Triggers
<!-- governance:key=escalation_triggers -->

- 修改全域人類生命總量守恆公式（`Living + In-Transit + Deaths == Initial Population`）。
- 修改 8 階段唯一離散日旅行時間公式（$\text{Arrival Day} = \text{Departure Day} + \text{Route Days} - 1$）。
- 引入全新實體生命週期（如 S4 具名個體 NPC 之實體化、遷徙與死亡提交）。
- 模擬出現極端滅絕或永久崩潰模式（必須由負責人決策，嚴禁私自加調節器）。

## Repo-Specific Forbidden Behaviors
<!-- governance:key=forbidden_behaviors -->

- **嚴禁提前實作未來切片系統**（Axiom 2：指定 Slice 前不寫技能、XP、戰鬥或自由行為）。
- **嚴禁 LLM / 敘事層具備世界狀態修改權**（Axiom 3, 16：敘事純下游投射，0 狀態修改權限）。
- **嚴禁具名 NPC 實體化導致人口通膨**（Axiom 11：具名為表徵子集，絕非增長人口）。
- **嚴禁隨機數/時間戳鑄造實體 ID**（Axiom 12：必須使用單調遞增序號保證重播決定論）。
- **嚴禁未授權之自主行為發明**（Axiom 14：未授權動作強制 Fail-Closed）。
- **嚴禁私自添加人為調節器掩蓋模擬失敗**（Axiom 8：發現異常必須記錄客觀因果並呈報）。

## Wasteland UI Skill Routing

For this repository's in-game UI or UI artwork, read
`.agents/skills/wc-survivor-pda-design-system/SKILL.md` first. It is the single
visual source; `wasteland-chronicles-ui-v1` is a compatibility pointer. Reuse the
shared tokens/theme/components and verify rendered screens. User instructions
and authorized gameplay scope take precedence; this routing does not authorize
future systems by itself.
