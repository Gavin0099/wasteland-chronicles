extends RefCounted

# ==============================================================================
# ASP-2: RUMORS & ASPIRATIONS
# ==============================================================================
# Owner ruling: not an achievement checklist. The world tells the player about
# things that really exist in it; the player decides which to chase.
#
#   - A rumour is HEARD by having been in a town where people talk about it.
#     Where you have been is folded from the ledger (CHARACTER_CREATED and every
#     PLAYER_TRAVEL_STARTED origin) plus where you stand now.
#   - Every rumour points at a real thing (the standing raider, a road place),
#     and says what still stands between the player and it, from live state:
#     the forecast, a skill rank, a place's status.
#   - A rumour is DONE when the world says so, never when a counter ticks.
#   - The one the player is chasing is a RUMOR_TRACKED receipt; the last one
#     wins, and an empty id lets it go. Nothing else is saved.
# ==============================================================================

const RoadPlaces = preload("res://simulation/road_places.gd")
const Unique = preload("res://simulation/unique_gear.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Party = preload("res://simulation/party.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")

const RUMORS := {
	"rumor:gas_mask": {
		"title_zh": "封鎖站的防毒面具",
		"text_zh": "乾井到新希望的路，公路第一天會經過封鎖站。防護櫃裡留著軍規面具，能讓人走進荒野路第一天路旁的污染工坊。",
		"heard_in": ["settlement:dry_well", "settlement:new_hope"], "place_id": "place:sealed_checkpoint",
	},
	"rumor:engineer_tools": {
		"title_zh": "污染工坊的工程師",
		"text_zh": "工坊裡留著舊世工程師的精密工具。照他的程序修泵，機械熟練者也能精修；多花一天，就能讓井泵每天多出兩份水。",
		"heard_in": ["settlement:dry_well", "settlement:new_hope"], "place_id": "place:toxic_workshop",
	},
	"rumor:raider": {
		"title_zh": "披鐵甲的傢伙",
		"text_zh": "新希望貼著一張常駐賞單：一個拖鐵鎚的重裝掠奪者在乾井和新希望之間的荒野路上紮營，商隊都繞著走。",
		"heard_in": ["settlement:new_hope", "settlement:dry_well"],
	},
	"rumor:armory": {
		"title_zh": "沙裡的軍械庫",
		"text_zh": "商隊的人說，鐵鎚幫營地再往荒野走一天，沙裡埋著一座舊世的地下軍械庫。機械能拆門，電子加廢料能搭接線路；裡面的東西鎮上買不到。",
		"heard_in": ["settlement:new_hope", "settlement:dry_well"],
		"place_id": "place:old_armory",
	},
	"rumor:old_well": {
		"title_zh": "枯河邊的井",
		"text_zh": "灰谷往乾井的路上，枯河床邊有口舊井還聽得到水聲。哪個鎮先知道它，哪個鎮就少渴一點。",
		"heard_in": ["settlement:gray_valley", "settlement:dry_well"],
		"place_id": "place:old_well",
	},
	"rumor:fuel_station": {
		"title_zh": "塌頂的加油站",
		"text_zh": "灰谷往新希望的公路邊，那座塌了頂的加油站，地下儲槽可能還沒抽乾。",
		"heard_in": ["settlement:gray_valley", "settlement:new_hope"],
		"place_id": "place:fuel_station",
	},
}

static func ids() -> Array:
	var out: Array = RUMORS.keys()
	out.sort()
	return out

static func exists(rumor_id: Variant) -> bool:
	return typeof(rumor_id) == TYPE_STRING and RUMORS.has(rumor_id)

# Every town the player has stood in.
static func visited(world) -> Dictionary:
	var out := {}
	if world == null or world.player == null:
		return out
	for evt in world.event_log:
		if String(evt.actor_id) != String(world.player.npc_id):
			continue
		if evt.type == "CHARACTER_CREATED":
			out[String(evt.target_id)] = true
		elif evt.type == "PLAYER_TRAVEL_STARTED" and typeof(evt.payload) == TYPE_DICTIONARY:
			out[String(evt.payload.get("origin", ""))] = true
	var ls = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if ls != null and ls.status == NpcLifeState.Status.SETTLED:
		out[String(ls.population_container_id)] = true
	return out

static func heard(world, rumor_id: String) -> bool:
	if not exists(rumor_id):
		return false
	var been := visited(world)
	for town in RUMORS[rumor_id].heard_in:
		if been.has(String(town)):
			return true
	return false

static func tracked(world) -> String:
	if world == null:
		return ""
	for i in range(world.event_log.size() - 1, -1, -1):
		var evt = world.event_log[i]
		if evt.type == "RUMOR_TRACKED":
			var id := String(evt.payload.get("rumor_id", ""))
			return id if exists(id) and heard(world, id) else ""
	return ""

static func _raider_beaten(world) -> bool:
	for evt in world.event_log:
		if evt.type == "FIELD_RESULT" and String(evt.payload.get("outcome", "")) == "VICTORY" and String(evt.payload.get("enemy", "")) == Enemies.HEAVY_RAIDER:
			return true
	return false

# {done, next}: whether the world has settled this rumour, and if not, the one
# thing that stands between the player and it right now.
static func progress(world, rumor_id: String) -> Dictionary:
	match rumor_id:
		"rumor:gas_mask":
			if Unique.taken(world, "RECOVER_GAS_MASK"):
				return {"done": true, "next": "面具已取走；攜帶它與2廢料，可進荒野路第一天的污染工坊。" if world.player.item_inventory.contains("military_gas_mask") else "面具已取走，目前未持有；進污染工坊仍需帶上它。"}
			if Party.skill_rank(world, "MECHANICS") < 2:
				return {"done": false, "next": "需機械2；灰谷老焊工能教，阿扳同行也能幫忙。仍需實體工具2、廢料2。"}
			if Gear.tool_grade(world.player, "MECHANICS") < 2:
				return {"done": false, "next": "缺機械工具2；帶修理工具箱，再選「追這個」走乾井—新希望公路。"}
			return {"done": false, "next": "帶2廢料、足夠水糧，選「追這個」後走乾井—新希望公路第一天；開櫃另耗1天。"}
		"rumor:engineer_tools":
			if Unique.taken(world, "ENTER_TOXIC_WORKSHOP"):
				return {"done": true, "next": "工具已取走；持有它、機械2、3廢料，可花2天精修委託井泵，產水+2/日。"}
			if not world.player.item_inventory.contains("military_gas_mask"):
				return {"done": false, "next": "缺軍規防毒面具；先去公路第一天的封鎖站，再選擇追尋工坊，走荒野路第一天。"}
			return {"done": false, "next": "帶面具、2廢料與足夠水糧，選「追這個」後去荒野路第一天的污染工坊；取工具另耗1天。"}
		"rumor:raider":
			if _raider_beaten(world):
				return {"done": true, "next": "你把他打下來了。"}
			const Field = preload("res://simulation/field_adventure.gd")
			var read: Dictionary = Field.forecast_for_enemy(world, Enemies.HEAVY_RAIDER, true)
			if read.is_empty() or bool(read.beaten):
				return {"done": false, "next": "只靠近身攻擊，你現在打不贏他：把格鬥練上去（新希望的護衛隊長有在教），或換近戰武器；也可在新希望買槍與彈藥，用射擊應戰。"}
			return {"done": false, "next": "只靠近身攻擊，你現在打得贏他。去新希望接常駐懸賞，走荒野路。"}
		"rumor:armory":
			var armory := RoadPlaces.state(world, "place:old_armory")
			if bool(armory.prize_taken):
				return {"done": true, "next": "軍械庫裡的東西已經在你手上。"}
			var rank: int = Party.skill_rank(world, "MECHANICS")
			if Party.skill_rank(world, "ELECTRONICS") >= RoadPlaces.ARMORY_ELECTRONICS:
				return {"done": false, "next": "你的電子夠了。帶電錶（或更好的電子工具）、廢料 %d 與足夠水糧，走乾井—新希望的荒野路，第三天搭接軍械庫線路；開門另耗 1 天。" % RoadPlaces.ARMORY_CIRCUIT_SCRAP}
			if rank < RoadPlaces.ARMORY_MECHANICS:
				return {"done": false, "next": "門要機械 %d 才拆得開，你現在是 %d。灰谷的老焊工教機械，灰谷的技師阿扳能提供技能；仍需攜帶修理工具箱。也能用電子 %d 加廢料 %d 搭接：灰谷的電器修補匠教電子。" % [RoadPlaces.ARMORY_MECHANICS, rank, RoadPlaces.ARMORY_ELECTRONICS, RoadPlaces.ARMORY_CIRCUIT_SCRAP]}
			return {"done": false, "next": "你的機械夠了。帶修理工具箱（或精密修理組），走乾井—新希望的荒野路，第三天。帶足水糧，路上有他的營地。"}
		"rumor:old_well", "rumor:fuel_station":
			var place_id := String(RUMORS[rumor_id].place_id)
			var s := RoadPlaces.state(world, place_id)
			match String(s.status):
				"CLAIMED":
					return {"done": true, "next": "已經歸%s了。" % RoadPlaces.town_name(world, String(s.claimed_by))}
				"STRIPPED":
					return {"done": true, "next": "被你搬空了。"}
				"MARKED":
					return {"done": false, "next": "你記下了位置。走進%s就能回報。" % RoadPlaces.town_name(world, String(s.marked_for))}
			var towns := RoadPlaces.towns(place_id)
			return {"done": false, "next": "走%s—%s的公路，第一天就會經過。" % [RoadPlaces.town_name(world, towns[0]), RoadPlaces.town_name(world, towns[1])]}
	return {"done": false, "next": ""}

# What the character sheet shows: only rumours actually heard.
static func project(world) -> Array:
	var out: Array = []
	var chasing := tracked(world)
	for rumor_id in ids():
		if not heard(world, rumor_id):
			continue
		var p := progress(world, rumor_id)
		out.append({
			"id": rumor_id,
			"title": String(RUMORS[rumor_id].title_zh),
			"text": String(RUMORS[rumor_id].text_zh),
			"done": bool(p.done),
			"next": String(p.next),
			"tracked": rumor_id == chasing,
		})
	return out
