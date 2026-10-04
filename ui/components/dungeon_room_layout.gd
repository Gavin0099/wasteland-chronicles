extends RefCounted

# Presentation geometry. Simulation owns which passages are legal/open.
const NORTH: Vector2 = Vector2(500, 116)
const SOUTH: Vector2 = Vector2(500, 416)
const WEST: Vector2 = Vector2(112, 266)
const EAST: Vector2 = Vector2(888, 266)
const HINTS: Dictionary = {
	"entrance": "灰谷的樓梯在南側。北門通往設備前廳。",
	"foyer": "警衛區在北側；東側是維修廊。西側零件庫是另一條支路。",
	"guard": "散落的封存貨箱擋在兩側；北門通往泵房。",
	"maintenance": "沿著停轉的設備走廊，可從北門到達泵房。",
	"pump": "兩條前路在這裡相接。北側控制室與東側庫房仍值得查看。",
	"control": "控制室東側的返回門可從這一端解除門閂，直接回到入口。",
	"parts_store": "堆放的封存貨箱占據庫房。東門通往設備前廳。",
	"polluted_store": "停轉的設備旁留下水漬；返回泵房的門在西側。"
}

static func door(target: String, point: Vector2) -> Dictionary:
	return {"room_id": target, "point": point}

static func doors(room: String, opened: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match room:
		"entrance":
			result = [door("foyer", NORTH), {"label": "樓梯・返回灰谷", "command": "EXIT", "point": SOUTH}]
			if opened: result.append(door("control", EAST))
		"foyer": result = [door("entrance", SOUTH), door("guard", NORTH), door("maintenance", EAST), door("parts_store", WEST)]
		"guard": result = [door("foyer", SOUTH), door("pump", NORTH)]
		"maintenance": result = [door("foyer", WEST), door("pump", NORTH)]
		"pump": result = [door("guard", SOUTH), door("maintenance", WEST), door("control", NORTH), door("polluted_store", EAST)]
		"control":
			result = [door("pump", SOUTH)]
			result.append(door("entrance", EAST) if opened else {"command": "OPEN_SHORTCUT", "label": "解除門閂・開啟捷徑", "point": EAST})
		"parts_store": result = [door("foyer", EAST)]
		"polluted_store": result = [door("pump", WEST)]
	for passage: Dictionary in result:
		if not passage.has("command"):
			passage.command = "MOVE"
			passage.label = SimulationEngine.Dungeon.ROOMS[passage.room_id]
	return result

static func arrival(room_doors: Array[Dictionary], from_room: String) -> Vector2:
	for passage: Dictionary in room_doors:
		if passage.get("room_id", "") == from_room:
			var point: Vector2 = passage.point
			if point == NORTH: return Vector2(500, 150)
			return point + point.direction_to(Vector2(500, 266)) * 68
	return Vector2(500, 348)

static func obstacles(room: String) -> Array[Rect2]:
	match room:
		"entrance": return [Rect2(140, 155, 168, 100), Rect2(742, 285, 104, 85)]
		"foyer": return [Rect2(165, 155, 200, 90), Rect2(675, 155, 140, 95)]
		"guard": return [Rect2(210, 160, 180, 90), Rect2(620, 300, 170, 80)]
		"maintenance": return [Rect2(200, 160, 190, 90), Rect2(660, 300, 160, 80)]
		"pump": return [Rect2(160, 150, 225, 90), Rect2(625, 300, 220, 85)]
		"control": return [Rect2(190, 160, 190, 85), Rect2(645, 310, 160, 80)]
		"parts_store": return [Rect2(200, 155, 190, 90), Rect2(620, 310, 200, 80)]
		"polluted_store": return [Rect2(200, 155, 185, 90), Rect2(640, 310, 160, 80)]
	return []

static func approach(passage: Dictionary) -> Vector2:
	var point: Vector2 = passage.point
	return point + point.direction_to(Vector2(500, 266)) * 20
