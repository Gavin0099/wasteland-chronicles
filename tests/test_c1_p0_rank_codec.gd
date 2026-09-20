extends SceneTree

const Codec = preload("res://simulation/rank_json_codec.gd")
var failed := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)

func _init() -> void:
	var prefix := '{"player":{"capability":{"skill_ranks":{"MECHANICS":'
	var suffix := '}}}}'
	for token in ["0", "1", "2", "3", "4", "5"]:
		var res := Codec.decode(prefix + token + suffix)
		check(res.success, "integer token must be accepted: " + token)
		if res.success:
			check(typeof(res.data.player.capability.skill_ranks.MECHANICS) == TYPE_INT, "rank must restore as TYPE_INT")
			check(res.data.player.capability.skill_ranks.MECHANICS == int(token), "rank must retain value")
	for token in ["2.0", "2e0", "2E+0", "2.5", "-1", "6", "-0", "true", "null", '"2"', "{}", "[]", "NaN", "Infinity"]:
		var res := Codec.decode(prefix + token + suffix)
		check(not res.success and res.data == null, "invalid rank must fail closed: " + token)
	for raw in [prefix + '2,"MECHANICS":3' + suffix, prefix + '2,"MECH\\u0041NICS":3' + suffix, '{"player":{},"player":{}}', prefix + '2,' + suffix]:
		check(not Codec.decode(raw).success, "duplicates/trailing comma must fail")
	var escaped := '{"note":"fake \\\"skill_ranks\\\": { \\\"MECHANICS\\\": 2.0 }", "player":{"capability":{"skill_ranks":{"MECH\\u0041NICS":2}}},"pressure":2.0,"ratio":2e0}'
	var decoded := Codec.decode(escaped)
	check(decoded.success, "escaped keys and strings must be parsed structurally")
	if decoded.success:
		check(typeof(decoded.data.player.capability.skill_ranks.MECHANICS) == TYPE_INT, "escaped identifier still targets rank domain")
		check(typeof(decoded.data.pressure) == TYPE_FLOAT and typeof(decoded.data.ratio) == TYPE_FLOAT, "ordinary world floats must remain native floats")
	for probe in NumericCanon.PROBE_CORPUS:
		var raw := JSON.stringify({"world_float": probe, "array": [{"nested": probe}]})
		var restored := Codec.decode(raw)
		check(restored.success and restored.data == JSON.parse_string(raw), "world numeric codec must be unchanged")
	var replay_a := Codec.decode(prefix + '2' + suffix)
	var replay_b := Codec.decode(JSON.stringify(replay_a.data))
	check(JSON.stringify(replay_a.data).sha256_text() == JSON.stringify(replay_b.data).sha256_text(), "codec canonical replay must match")
	print("C1-P0 strict rank codec: ", "PASS" if failed == 0 else "FAIL", "; failures=", failed)
	quit(0 if failed == 0 else 1)
