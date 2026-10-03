extends RefCounted

const Towns = preload("res://game_data/faction_catalogue.gd")

static func extended(world) -> bool:
	return world.settlements.has(&"settlement:spring_ford") or world.settlements.has(&"settlement:iron_pass")

static func has_direct_road(world, origin: StringName, destination: StringName) -> bool:
	if not world.settlements.has(origin) or not world.settlements.has(destination) or origin == destination:
		return false
	for caravan in world.caravans.values():
		if (caravan.origin_id == origin and caravan.destination_id == destination) or (caravan.origin_id == destination and caravan.destination_id == origin):
			return true
	return false

static func permits(world, origin: StringName, destination: StringName) -> bool:
	return not extended(world) or has_direct_road(world, origin, destination)

static func hint(world, origin: StringName, destination: StringName) -> String:
	if permits(world, origin, destination): return ""
	var hub := "settlement:gray_valley"
	if origin == &"settlement:spring_ford" or (origin != &"settlement:iron_pass" and destination == &"settlement:spring_ford"):
		hub = "settlement:new_hope"
	return "沒有直達商路；先前往%s，再選下一段路。" % Towns.town_name(hub)
