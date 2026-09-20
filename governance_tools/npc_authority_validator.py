#!/usr/bin/env python3
"""
NPC Authority Domain Validator (Level G1.5-A / S4-A)
Validates that NPC identity materialization respects population authority,
subset bounds, deterministic ID minting, and valid settlement references.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

# Add framework to path if needed for validator interface
FRAMEWORK_ROOT = Path(__file__).resolve().parent.parent / "additional" / "ai-governance-framework"
if FRAMEWORK_ROOT.exists() and str(FRAMEWORK_ROOT) not in sys.path:
    sys.path.insert(0, str(FRAMEWORK_ROOT))

try:
    from governance_tools.validator_interface import DomainValidator, ValidatorResult
except ImportError:
    # Standalone fallback if framework module not in path
    from dataclasses import dataclass, field

    @dataclass
    class ValidatorResult:
        ok: bool
        rule_ids: list[str]
        violations: list[str] = field(default_factory=list)
        warnings: list[str] = field(default_factory=list)
        evidence_summary: str = ""
        metadata: dict[str, object] = field(default_factory=dict)
        schema_version: str = "1.0"

        def to_dict(self) -> dict:
            return {
                "ok": self.ok,
                "rule_ids": self.rule_ids,
                "violations": self.violations,
                "warnings": self.warnings,
                "evidence_summary": self.evidence_summary,
                "metadata": self.metadata,
                "schema_version": self.schema_version,
            }

    class DomainValidator:
        pass


class NpcAuthorityValidator(DomainValidator):
	NPC_ID_REGEX = re.compile(r"^npc:\d{8}$")

	@property
	def rule_ids(self) -> list[str]:
		return ["G1.5-A", "NPC-001", "NPC-002", "NPC-003", "NPC-004"]

	def validate(self, payload: dict) -> ValidatorResult:
		violations: list[str] = []
		warnings: list[str] = []

		settlements: dict = payload.get("settlements", {})
		npc_registry: dict = payload.get("npc_registry", {})
		next_npc_sequence: int = payload.get("next_npc_sequence", 1)

		if not settlements and not npc_registry:
			return ValidatorResult(
				ok=True,
				rule_ids=self.rule_ids,
				evidence_summary="Empty payload, no NPC authority checks required",
			)

		# 1. Check NPC ID format, uniqueness, and reference validity
		seen_ids: set[str] = set()
		named_counts: dict[str, int] = {s_id: 0 for s_id in settlements}
		max_seq_found: int = 0

		# Check next_npc_sequence >= 1
		if next_npc_sequence < 1:
			violations.append(f"NPC-000: next_npc_sequence must be >= 1, got {next_npc_sequence}")

		for npc_id, npc_data in npc_registry.items():
			# Check dict key == record.id
			record_id = npc_data.get("id", "")
			if record_id != npc_id:
				violations.append(
					f"NPC-000: Dictionary key '{npc_id}' does not match record id '{record_id}'"
				)

			# Check ID regex
			if not self.NPC_ID_REGEX.match(npc_id):
				violations.append(
					f"NPC-001: Invalid NPC ID format '{npc_id}', must be 'npc:00000001' style"
				)

			# Check uniqueness
			if npc_id in seen_ids:
				violations.append(f"NPC-002: Duplicate NPC ID detected: '{npc_id}'")
			seen_ids.add(npc_id)

			# Track sequence
			try:
				seq_num = int(npc_id.split(":")[1])
				if seq_num > max_seq_found:
					max_seq_found = seq_num
			except (IndexError, ValueError):
				pass

			# Check origin settlement existence
			origin_id = npc_data.get("origin_settlement_id", "")
			if origin_id not in settlements:
				violations.append(
					f"NPC-003: NPC '{npc_id}' references non-existent origin settlement '{origin_id}'"
				)
			else:
				named_counts[origin_id] = named_counts.get(origin_id, 0) + 1

		# 2. Check next_npc_sequence monotonic invariant
		if max_seq_found >= next_npc_sequence:
			violations.append(
				f"NPC-004: next_npc_sequence ({next_npc_sequence}) <= max sequence found in registry ({max_seq_found})"
			)

		# 3. Check subset invariant for each settlement
		for s_id, s_data in settlements.items():
			pop = s_data.get("population", 0) if isinstance(s_data, dict) else s_data
			named = named_counts.get(s_id, 0)
			if named > pop:
				violations.append(
					f"NPC-005: Settlement '{s_id}' named NPC count ({named}) exceeds aggregate population ({pop})"
				)
			anon = pop - named
			if anon < 0:
				violations.append(
					f"NPC-006: Settlement '{s_id}' anonymous population is negative ({anon})"
				)

		evidence = (
			f"Validated {len(npc_registry)} NPCs across {len(settlements)} settlements. "
			f"Violations: {len(violations)}, Warnings: {len(warnings)}"
		)

		return ValidatorResult(
			ok=len(violations) == 0,
			rule_ids=self.rule_ids,
			violations=violations,
			warnings=warnings,
			evidence_summary=evidence,
			metadata={
				"npc_count": len(npc_registry),
				"max_sequence": max_seq_found,
				"next_sequence": next_npc_sequence,
			},
		)


def main() -> int:
	import argparse

	parser = argparse.ArgumentParser(description="NPC Authority Domain Validator")
	parser.add_argument("--snapshot", type=str, help="Path to world snapshot JSON file")
	parser.add_argument("--input", type=str, help="Alias for --snapshot")
	parser.add_argument("--check", action="store_true", help="Self-check test fixtures")
	args = parser.parse_args()

	validator = NpcAuthorityValidator()

	if args.check:
		# Run built-in pass/fail self-check fixtures
		print("Running NpcAuthorityValidator self-check fixtures...")
		valid_fixture = {
			"next_npc_sequence": 3,
			"settlements": {
				"settlement:gray_valley": {"population": 50},
				"settlement:new_hope": {"population": 100},
			},
			"npc_registry": {
				"npc:00000001": {"id": "npc:00000001", "origin_settlement_id": "settlement:gray_valley"},
				"npc:00000002": {"id": "npc:00000002", "origin_settlement_id": "settlement:new_hope"},
			},
		}
		res_valid = validator.validate(valid_fixture)
		assert res_valid.ok, f"Valid fixture failed: {res_valid.violations}"

		invalid_subset_fixture = {
			"next_npc_sequence": 3,
			"settlements": {
				"settlement:gray_valley": {"population": 1},
			},
			"npc_registry": {
				"npc:00000001": {"id": "npc:00000001", "origin_settlement_id": "settlement:gray_valley"},
				"npc:00000002": {"id": "npc:00000002", "origin_settlement_id": "settlement:gray_valley"},
			},
		}
		res_subset = validator.validate(invalid_subset_fixture)
		assert not res_subset.ok, "Invalid subset fixture falsely passed!"

		invalid_ref_fixture = {
			"next_npc_sequence": 2,
			"settlements": {"settlement:gray_valley": {"population": 10}},
			"npc_registry": {
				"npc:00000001": {"id": "npc:00000001", "origin_settlement_id": "settlement:moon_base"},
			},
		}
		res_ref = validator.validate(invalid_ref_fixture)
		assert not res_ref.ok, "Invalid reference fixture falsely passed!"

		print("PASS: All NpcAuthorityValidator fixtures verified successfully!")
		return 0

	target_file = args.snapshot or args.input
	if target_file:
		with open(target_file, "r", encoding="utf-8") as f:
			payload = json.load(f)
		result = validator.validate(payload)
		print(json.dumps(result.to_dict(), indent=2))
		return 0 if result.ok else 1

	print("Usage: python npc_authority_validator.py --snapshot artifacts/world_snapshot.json OR --check")
	return 0


if __name__ == "__main__":
	sys.exit(main())
