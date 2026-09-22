extends SceneTree

const Registry = preload("res://simulation/item_registry.gd")
const Markets = preload("res://simulation/item_market_catalogue.gd")

var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-7: " + message)

func _init() -> void:
	check(Markets.validate_catalogue() == "", "canonical market metadata validates")
	check(Markets.settlement_key("settlement:new_hope") == "new_hope", "qualified settlement IDs normalize")
	check(Markets.settlement_key("gray_valley") == "gray_valley", "short settlement IDs normalize")
	check(Markets.settlement_key("settlement:unknown") == "", "unknown settlement fails closed")

	var gray := Markets.offers_for("settlement:gray_valley")
	check(gray.success and gray.offers.size() == 12, "all twelve canonical items have a non-none Gray Valley profile")
	var gray_ids: Array[String] = []
	var gray_seen := {}
	for offer in gray.offers:
		gray_ids.append(String(offer.item_id))
		gray_seen[String(offer.item_id)] = int(gray_seen.get(String(offer.item_id), 0)) + 1
	check(gray_seen.size() == gray.offers.size(), "offer IDs are unique")
	var sorted_ids := gray_ids.duplicate()
	sorted_ids.sort()
	check(gray_ids == sorted_ids, "offer ordering is stable by item ID")

	var wrench := Markets.profile_for("wrench", "gray_valley")
	check(wrench.success and wrench.supply == "high" and wrench.demand == "medium", "Gray Valley exposes wrench regional profile")
	var robe := Markets.profile_for("desert_robe", "dry_well")
	check(robe.success and robe.supply == "high" and robe.demand == "high", "Dry Well exposes desert robe regional profile")
	var knife := Markets.profile_for("rusted_knife", "new_hope")
	check(knife.success and knife.is_routinely_supplied, "New Hope exposes routinely supplied knife")
	check(Markets.profile_for("missing_item", "new_hope").error == "UNKNOWN_ITEM_ID", "unknown item fails closed")
	check(Markets.profile_for("rope", "settlement:missing").error == "UNKNOWN_SETTLEMENT", "unknown market fails closed")
	check(Markets.offers_for("missing").error == "UNKNOWN_SETTLEMENT", "unknown shop catalogue fails closed")

	var detached := Markets.offers_for("new_hope")
	var detached_offer: Dictionary = detached.offers[0]
	detached_offer.item_id = "forged"
	detached.offers.clear()
	var fresh := Markets.offers_for("new_hope")
	check(fresh.offers.size() == 12, "offer projection is detached")
	check(String(fresh.offers[0].item_id) != "forged", "nested offer mutation cannot alter registry")

	var before := JSON.stringify(Markets.offers_for("dry_well"), "", true)
	var after := JSON.stringify(Markets.offers_for("dry_well"), "", true)
	check(before == after, "market projection is deterministic")
	var summary := Markets.summary_for("dry_well")
	check(summary.success and summary.listed_item_count == 12, "summary counts listed items")
	check(int(summary.supply_counts.high) > 0 and int(summary.supply_counts.low) > 0, "summary preserves regional spread")
	check(Registry.all_definitions().size() == 12, "regional catalogue does not register new runtime items")

	print("ITEM-7 regional market catalogue: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
