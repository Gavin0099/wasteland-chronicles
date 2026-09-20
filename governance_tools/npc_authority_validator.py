#!/usr/bin/env python3
"""
NPC Authority Domain Validator (Level G1.5-A / S4-A)
Validates that NPC identity materialization respects population authority,
subset bounds, deterministic ID minting, and valid settlement references.
"""

from __future__ import annotations

import json
import math
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

	# S4-C closed Background enum, mirroring NpcProfile.Background.
	# Deliberately has no UNASSIGNED member: "has no profile" and
	# "background is UNASSIGNED" are different statements; only the former exists.
	BACKGROUND_NAMES = ("CARAVAN_GUARD", "MECHANIC", "FARMER", "SCAVENGER")
	VALID_BACKGROUNDS = frozenset(range(len(BACKGROUND_NAMES)))

	# S4-D closed trait enum, mirroring NpcProfile.Trait. Traits are set-like
	# metadata: closed membership and no duplicates. They confer nothing.
	TRAIT_NAMES = (
		"CAUTIOUS", "LOYAL", "GREEDY", "AGGRESSIVE", "COMPASSIONATE", "STUBBORN",
	)
	VALID_TRAITS = frozenset(range(len(TRAIT_NAMES)))

	@property
	def rule_ids(self) -> list[str]:
		return [
			"G1.5-A", "NPC-001", "NPC-002", "NPC-003", "NPC-004", "NPC-007", "NPC-008",
			"EVENT-001", "EVENT-002", "EVENT-003", "EVENT-004",
			"NUM-001", "NUM-002", "NUM-003", "TRAIT-001", "TRAIT-002",
		]

	def validate(self, payload: dict) -> ValidatorResult:
		violations: list[str] = []
		warnings: list[str] = []

		settlements: dict = payload.get("settlements", {})
		npc_registry: dict = payload.get("npc_registry", {})
		npc_profile_registry: dict = payload.get("npc_profile_registry", {})
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

		# 4. S4-C profile checks: closed Background enum, profiles are a subset of
		#    identities. Profiles are OPTIONAL — an NPC without one is fully valid,
		#    so absence is never a violation. Backgrounds carry no capability and
		#    are therefore never consulted for any authority decision here.
		for profile_id, profile_data in npc_profile_registry.items():
			record_id = profile_data.get("npc_id", "") if isinstance(profile_data, dict) else ""
			if record_id != profile_id:
				violations.append(
					f"NPC-007: Profile key '{profile_id}' does not match record npc_id '{record_id}'"
				)

			if profile_id not in npc_registry:
				violations.append(
					f"NPC-007: Profile '{profile_id}' has no corresponding identity "
					f"(profiles must be a subset of the identity registry)"
				)

			# TRAIT-001 / TRAIT-002: closed enum membership, no duplicates.
			traits = profile_data.get("traits", []) if isinstance(profile_data, dict) else []
			if not isinstance(traits, list):
				violations.append(
					f"TRAIT-002: Profile '{profile_id}' traits must be an array, got "
					f"{type(traits).__name__}"
				)
			else:
				seen_traits: set = set()
				for trait_value in traits:
					if isinstance(trait_value, bool) or not isinstance(trait_value, (int, float)):
						violations.append(
							f"TRAIT-001: Profile '{profile_id}' has trait {trait_value!r} "
							f"which is not a numeric enum member"
						)
						continue
					if float(trait_value) != int(trait_value) or int(trait_value) not in self.VALID_TRAITS:
						violations.append(
							f"TRAIT-001: Profile '{profile_id}' has trait {trait_value!r} outside the "
							f"closed enum {sorted(self.VALID_TRAITS)} "
							f"({', '.join(self.TRAIT_NAMES)})"
						)
						continue
					if int(trait_value) in seen_traits:
						violations.append(
							f"TRAIT-002: Profile '{profile_id}' holds duplicate trait "
							f"{self.TRAIT_NAMES[int(trait_value)]}"
						)
					seen_traits.add(int(trait_value))

			background = profile_data.get("background", None) if isinstance(profile_data, dict) else None
			if background not in self.VALID_BACKGROUNDS:
				violations.append(
					f"NPC-008: Profile '{profile_id}' has background {background!r} outside the "
					f"closed enum {sorted(self.VALID_BACKGROUNDS)} "
					f"({', '.join(self.BACKGROUND_NAMES)})"
				)

		if len(npc_profile_registry) > len(npc_registry):
			violations.append(
				f"NPC-007: Profile count ({len(npc_profile_registry)}) exceeds identity count "
				f"({len(npc_registry)})"
			)

		# 5. S4-C.1 Event Ledger checks. These re-derive everything independently
		#    from the raw snapshot; nothing here consults the GDScript loader's
		#    conclusions, so agreement between the two is real corroboration.
		violations.extend(self._validate_event_ledger(payload))

		# 6. S4-C.2 numeric domain checks. Re-derived independently here: this
		#    validator does not consult the GDScript restore implementation, so
		#    agreement between the two is real corroboration rather than an echo.
		violations.extend(self._validate_numeric_domains(payload))

		event_summary = "no ledger"
		if isinstance(payload.get("events"), list):
			event_summary = f"{len(payload['events'])} events"

		evidence = (
			f"Validated {len(npc_registry)} NPCs across {len(settlements)} settlements, "
			f"{len(npc_profile_registry)} backgrounds, {event_summary}. "
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
				"profile_count": len(npc_profile_registry),
				"event_count": len(payload["events"]) if isinstance(payload.get("events"), list) else None,
				"max_sequence": max_seq_found,
				"next_sequence": next_npc_sequence,
			},
		)


	# ── S4-C.1: Event Ledger ──────────────────────────────────────────────────
	# The committed events ledger is the SINGLE AUTHORITY for historical world
	# facts. event_count is derived metadata and is CHECKED here, never trusted:
	# a snapshot that merely asserts "20 things happened" without carrying them
	# is a snapshot whose history has been lost.
	REQUIRED_EVENT_FIELDS = ("day", "type", "actor_id", "target_id", "payload")

	def _validate_event_ledger(self, payload: dict) -> list[str]:
		violations: list[str] = []

		events = payload.get("events", None)
		declared_count = payload.get("event_count", None)

		if events is None:
			# A snapshot with a count but no ledger is the dangerous case: read
			# naively it asserts that nothing has ever happened.
			if declared_count is not None:
				violations.append(
					f"EVENT-001: snapshot declares event_count={declared_count} but carries no "
					f"'events' array; historical facts cannot be reconstructed from a count"
				)
			return violations

		if not isinstance(events, list):
			violations.append(f"EVENT-002: 'events' must be an array, got {type(events).__name__}")
			return violations

		# EVENT-001: derived count agreement. Independently recomputed here.
		if declared_count is not None:
			if not isinstance(declared_count, int) or isinstance(declared_count, bool):
				violations.append(
					f"EVENT-001: event_count must be an integer, got {declared_count!r}"
				)
			elif declared_count != len(events):
				violations.append(
					f"EVENT-001: event_count ({declared_count}) does not match the serialized "
					f"ledger length ({len(events)})"
				)

		for index, record in enumerate(events):
			# EVENT-002: required fields present and well-typed.
			if not isinstance(record, dict):
				violations.append(f"EVENT-002: events[{index}] is not an object")
				continue

			for field in self.REQUIRED_EVENT_FIELDS:
				if field not in record:
					violations.append(f"EVENT-002: events[{index}] is missing required field '{field}'")

			if "day" in record and (not isinstance(record["day"], int) or isinstance(record["day"], bool)):
				violations.append(f"EVENT-002: events[{index}].day must be an integer")
			if "type" in record:
				if not isinstance(record["type"], str):
					violations.append(f"EVENT-002: events[{index}].type must be a string")
				elif record["type"] == "":
					violations.append(f"EVENT-002: events[{index}].type is empty")

			# EVENT-004: payload structurally valid and JSON-representable.
			if "payload" in record:
				if not isinstance(record["payload"], dict):
					violations.append(f"EVENT-004: events[{index}].payload must be an object")
				else:
					violations.extend(
						self._validate_payload_value(
							record["payload"], f"events[{index}].payload"
						)
					)

		# EVENT-003: ordering must survive serialization verbatim. The ledger is
		# COMMIT order and is explicitly NOT sorted (not by day, not by type), so
		# this cannot assert any particular order. What it CAN assert, from the
		# snapshot alone, is that the ledger is carried in an order-preserving
		# container and that a JSON round-trip performed here — independently of
		# the GDScript loader — reproduces the identical sequence.
		sequence_before = [
			(r.get("day"), r.get("type"), r.get("actor_id"), r.get("target_id"))
			for r in events
			if isinstance(r, dict)
		]
		try:
			reparsed = json.loads(json.dumps(events))
		except (TypeError, ValueError) as exc:
			violations.append(f"EVENT-003: ledger is not JSON round-trippable: {exc}")
			return violations

		sequence_after = [
			(r.get("day"), r.get("type"), r.get("actor_id"), r.get("target_id"))
			for r in reparsed
			if isinstance(r, dict)
		]
		if sequence_before != sequence_after:
			violations.append(
				"EVENT-003: event ordering is not preserved by a serialization round-trip"
			)

		return violations

	def _validate_payload_value(self, value, path: str) -> list[str]:
		"""Recursively check a payload value against the JSON value model."""
		violations: list[str] = []
		if value is None or isinstance(value, (bool, int, float, str)):
			if isinstance(value, int) and not isinstance(value, bool) and abs(value) > 2**53:
				violations.append(
					f"EVENT-004: {path} is an integer beyond the exact JSON range ({value})"
				)
			return violations
		if isinstance(value, dict):
			for key, item in value.items():
				if not isinstance(key, str):
					violations.append(f"EVENT-004: {path} has a non-string key {key!r}")
					continue
				violations.extend(self._validate_payload_value(item, f"{path}.{key}"))
			return violations
		if isinstance(value, list):
			for i, item in enumerate(value):
				violations.extend(self._validate_payload_value(item, f"{path}[{i}]"))
			return violations
		violations.append(f"EVENT-004: {path} has unsupported type {type(value).__name__}")
		return violations


	# ── S4-C.2: numeric domain canonicality ───────────────────────────────────
	# Declared domain types, mirrored from the GDScript schema but re-stated here
	# deliberately. A number is judged against its DECLARED type, never against
	# what its serialized form happens to look like.
	SETTLEMENT_INT_FIELDS = {
		"population": 0, "maintenance_scrap": 0, "maintenance_fuel": 0,
		"reference_population": 0, "days_since_last_migration": 0,
		"cumulative_deaths": 0, "target_water": 0, "target_food": 0,
		"target_scrap": 0, "target_fuel": 0,
	}
	SETTLEMENT_FLOAT_FIELDS = (
		"metabolism_water_rate", "metabolism_food_rate",
		"water_pressure", "food_pressure", "water_exposure", "food_exposure",
		"security", "base_price_water", "base_price_food",
		"base_price_scrap", "base_price_fuel",
		"price_water", "price_food", "price_scrap", "price_fuel",
	)
	MAX_SAFE_INT = 2**53 - 1

	def _is_domain_int(self, value) -> bool:
		"""finite AND mathematically integral AND within the safe integer range."""
		if isinstance(value, bool):
			return False
		if isinstance(value, int):
			return abs(value) <= self.MAX_SAFE_INT
		if isinstance(value, float):
			if math.isnan(value) or math.isinf(value):
				return False
			if value != math.floor(value):
				return False
			return abs(value) <= self.MAX_SAFE_INT
		return False

	def _validate_numeric_domains(self, payload: dict) -> list[str]:
		violations: list[str] = []
		settlements = payload.get("settlements", {})
		if not isinstance(settlements, dict):
			return violations

		for s_id, s in settlements.items():
			if not isinstance(s, dict):
				continue

			# NUM-001: int-domain fields must be restorable as integers in range.
			for field, minimum in self.SETTLEMENT_INT_FIELDS.items():
				if field not in s:
					continue
				value = s[field]
				if not self._is_domain_int(value):
					violations.append(
						f"NUM-001: settlements.{s_id}.{field} = {value!r} is declared int but is "
						f"not a finite integral value within the safe integer range"
					)
				elif int(value) < minimum:
					violations.append(
						f"NUM-001: settlements.{s_id}.{field} = {int(value)} is below its domain minimum {minimum}"
					)

			# NUM-002: float-domain fields must be finite.
			for field in self.SETTLEMENT_FLOAT_FIELDS:
				if field not in s:
					continue
				value = s[field]
				if isinstance(value, bool) or not isinstance(value, (int, float)):
					violations.append(
						f"NUM-002: settlements.{s_id}.{field} = {value!r} is declared float but is "
						f"{type(value).__name__}"
					)
				elif math.isnan(value) or math.isinf(value):
					violations.append(
						f"NUM-002: settlements.{s_id}.{field} is NaN or infinite and cannot be persisted"
					)

			# NUM-003: cumulative_disorder_loss is ACCOUNTING STATE,
			#          Dictionary[StringName, int], non-negative.
			cumulative = s.get("cumulative_disorder_loss", {})
			if not isinstance(cumulative, dict):
				violations.append(
					f"NUM-003: settlements.{s_id}.cumulative_disorder_loss must be an object"
				)
			else:
				for key, value in cumulative.items():
					if not self._is_domain_int(value):
						violations.append(
							f"NUM-003: settlements.{s_id}.cumulative_disorder_loss.{key} = {value!r} "
							f"is declared int but is not a finite integral value"
						)
					elif int(value) < 0:
						violations.append(
							f"NUM-003: settlements.{s_id}.cumulative_disorder_loss.{key} is negative"
						)

			# production_credits / disorder_loss_credits are authoritative floats.
			for credit_field in ("production_credits", "disorder_loss_credits"):
				credits = s.get(credit_field, {})
				if not isinstance(credits, dict):
					violations.append(f"NUM-002: settlements.{s_id}.{credit_field} must be an object")
					continue
				for key, value in credits.items():
					if isinstance(value, bool) or not isinstance(value, (int, float)):
						violations.append(
							f"NUM-002: settlements.{s_id}.{credit_field}.{key} = {value!r} is declared float"
						)
					elif math.isnan(value) or math.isinf(value):
						violations.append(
							f"NUM-002: settlements.{s_id}.{credit_field}.{key} is NaN or infinite"
						)

		return violations


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

		# S4-C: a profile-free world stays valid (profiles are optional)
		res_no_profiles = validator.validate(valid_fixture)
		assert res_no_profiles.ok, "World without profiles must remain valid!"

		# S4-C: legal backgrounds on a subset of identities
		valid_profile_fixture = dict(valid_fixture)
		valid_profile_fixture["npc_profile_registry"] = {
			"npc:00000001": {"npc_id": "npc:00000001", "background": 0},
		}
		res_profile_ok = validator.validate(valid_profile_fixture)
		assert res_profile_ok.ok, f"Valid profile fixture failed: {res_profile_ok.violations}"

		# S4-C: background outside the closed enum (NPC-008)
		bad_background_fixture = dict(valid_fixture)
		bad_background_fixture["npc_profile_registry"] = {
			"npc:00000001": {"npc_id": "npc:00000001", "background": 7},
		}
		res_bad_bg = validator.validate(bad_background_fixture)
		assert not res_bad_bg.ok, "Out-of-enum background falsely passed!"

		# S4-C: profile without a matching identity (NPC-007)
		orphan_profile_fixture = dict(valid_fixture)
		orphan_profile_fixture["npc_profile_registry"] = {
			"npc:00009999": {"npc_id": "npc:00009999", "background": 1},
		}
		res_orphan = validator.validate(orphan_profile_fixture)
		assert not res_orphan.ok, "Orphan profile falsely passed!"

		# ── S4-C.1 Event Ledger fixtures ─────────────────────────────────────
		def ev(day: int, typ: str = "FIXTURE_EVENT") -> dict:
			return {
				"day": day,
				"type": typ,
				"actor_id": "settlement:gray_valley",
				"target_id": "settlement:new_hope",
				"payload": {"causes": ["water"], "loss": {"scrap": 4.0}, "risk": 50.0},
			}

		# Legal: 7 events, event_count 7
		legal_ledger = dict(valid_fixture)
		legal_ledger["events"] = [ev(i) for i in range(7)]
		legal_ledger["event_count"] = 7
		res_ledger_ok = validator.validate(legal_ledger)
		assert res_ledger_ok.ok, f"Legal 7/7 ledger failed: {res_ledger_ok.violations}"

		# The recorded negative fixture: event_count = 9 with only 7 events.
		lying_ledger = dict(valid_fixture)
		lying_ledger["events"] = [ev(i) for i in range(7)]
		lying_ledger["event_count"] = 9
		res_lying = validator.validate(lying_ledger)
		assert not res_lying.ok, "event_count=9 with 7 events falsely passed!"
		assert any("EVENT-001" in v for v in res_lying.violations), res_lying.violations

		# A count with no ledger at all must not read as "nothing ever happened".
		countless_ledger = dict(valid_fixture)
		countless_ledger["event_count"] = 20
		res_countless = validator.validate(countless_ledger)
		assert not res_countless.ok, "event_count=20 with no events falsely passed!"
		assert any("EVENT-001" in v for v in res_countless.violations), res_countless.violations

		# An empty ledger is legal: "nothing has happened yet" is itself a fact.
		empty_ledger = dict(valid_fixture)
		empty_ledger["events"] = []
		empty_ledger["event_count"] = 0
		res_empty = validator.validate(empty_ledger)
		assert res_empty.ok, f"Empty ledger rejected: {res_empty.violations}"

		# A record missing a required field must be refused.
		broken_ledger = dict(valid_fixture)
		broken_record = ev(3)
		del broken_record["payload"]
		broken_ledger["events"] = [ev(1), ev(2), broken_record]
		broken_ledger["event_count"] = 3
		res_broken = validator.validate(broken_ledger)
		assert not res_broken.ok, "Record missing 'payload' falsely passed!"
		assert any("EVENT-002" in v for v in res_broken.violations), res_broken.violations

		# An empty event type is not a committed fact.
		untyped_ledger = dict(valid_fixture)
		untyped_ledger["events"] = [ev(1, "")]
		untyped_ledger["event_count"] = 1
		res_untyped = validator.validate(untyped_ledger)
		assert not res_untyped.ok, "Empty event type falsely passed!"

		# A payload integer beyond the exact JSON range would be silently
		# corrupted by any reader, so it is refused.
		huge_ledger = dict(valid_fixture)
		huge_record = ev(1)
		huge_record["payload"] = {"count": 2**60}
		huge_ledger["events"] = [huge_record]
		huge_ledger["event_count"] = 1
		res_huge = validator.validate(huge_ledger)
		assert not res_huge.ok, "Out-of-range payload integer falsely passed!"
		assert any("EVENT-004" in v for v in res_huge.violations), res_huge.violations

		# ── S4-C.2 numeric domain fixtures ───────────────────────────────────
		def settlement(**overrides) -> dict:
			base = {
				"population": 50, "cumulative_deaths": 2, "security": 87.5,
				"water_pressure": 12.25, "cumulative_disorder_loss": {"scrap": 31},
				"production_credits": {"scrap": 0.375},
			}
			base.update(overrides)
			return base

		def world(s: dict) -> dict:
			return {
				"next_npc_sequence": 1,
				"settlements": {"settlement:gray_valley": s},
				"npc_registry": {},
			}

		assert validator.validate(world(settlement())).ok, "Clean numeric fixture failed!"

		# Integral float is a legal canonical representation of an int domain.
		assert validator.validate(world(settlement(population=50.0))).ok, 			"Integral float population falsely rejected!"
		assert validator.validate(
			world(settlement(cumulative_disorder_loss={"scrap": 31.0}))
		).ok, "Integral float accounting value falsely rejected!"

		# Fractional value in an int domain must never be silently truncated.
		res_frac = validator.validate(world(settlement(population=3.7)))
		assert not res_frac.ok, "Fractional population falsely passed!"
		assert any("NUM-001" in v for v in res_frac.violations), res_frac.violations

		res_neg = validator.validate(world(settlement(population=-5)))
		assert not res_neg.ok, "Negative population falsely passed!"

		res_nan = validator.validate(world(settlement(security=float("nan"))))
		assert not res_nan.ok, "NaN security falsely passed!"
		assert any("NUM-002" in v for v in res_nan.violations), res_nan.violations

		res_inf = validator.validate(world(settlement(water_pressure=float("inf"))))
		assert not res_inf.ok, "Infinite pressure falsely passed!"

		res_huge = validator.validate(world(settlement(population=2**60)))
		assert not res_huge.ok, "Population beyond safe integer range falsely passed!"

		res_acct = validator.validate(
			world(settlement(cumulative_disorder_loss={"scrap": 2.5}))
		)
		assert not res_acct.ok, "Fractional accounting value falsely passed!"
		assert any("NUM-003" in v for v in res_acct.violations), res_acct.violations

		res_acct_neg = validator.validate(
			world(settlement(cumulative_disorder_loss={"scrap": -3}))
		)
		assert not res_acct_neg.ok, "Negative accounting value falsely passed!"

		# ── S4-D trait fixtures ──────────────────────────────────────────────
		def profiled(traits) -> dict:
			f = dict(valid_fixture)
			f["npc_profile_registry"] = {
				"npc:00000001": {"npc_id": "npc:00000001", "background": 0, "traits": traits},
			}
			return f

		assert validator.validate(profiled([])).ok, "Empty trait list rejected!"
		assert validator.validate(profiled([0, 1, 5])).ok, "Legal traits rejected!"
		# A profile with no traits key at all is still valid (pre-S4-D profiles).
		assert validator.validate(valid_profile_fixture).ok, "Traitless profile rejected!"

		res_bad_trait = validator.validate(profiled([0, 6]))
		assert not res_bad_trait.ok, "Out-of-enum trait falsely passed!"
		assert any("TRAIT-001" in v for v in res_bad_trait.violations), res_bad_trait.violations

		res_dup_trait = validator.validate(profiled([2, 2]))
		assert not res_dup_trait.ok, "Duplicate trait falsely passed!"
		assert any("TRAIT-002" in v for v in res_dup_trait.violations), res_dup_trait.violations

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
