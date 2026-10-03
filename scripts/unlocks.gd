class_name Unlocks
extends RefCounted
## What is open and what is still to be earned. The first lot of items is
## there from the start; the rest -- and the evil mode and the girls -- each
## wait on a deed: knocking out a boss, finding a secret room, a jackpot, a
## floor without a scratch... (data/unlocks.json: a deed's name, a hint of
## how to do it, and what it opens). A thing is open if no deed opens it,
## or the deed that does has been done.
##
## Deeds count only in a real game: the bot, tours and checks see
## everything open and write nothing down ([member everything],
## [member recording], both set by Main).

## Everything open: for the bot, tours, checks, and `-- all`.
static var everything := true
## Deeds go into the records.
static var recording := false
## Deeds done in this run, newest last: for the card at the end.
static var this_run: Array[String] = []


static func deeds() -> Dictionary:
	return GameData.unlocks()


## The deed that opens [param id], or "" for one open from the start.
static func opener(id: String) -> String:
	var all := deeds()
	for deed: String in all:
		if (all[deed].get("opens", []) as Array).has(id):
			return deed
	return ""


static func is_open(id: String) -> bool:
	if everything:
		return true
	var deed := opener(id)
	return deed == "" or Records.deeds.has(deed)


## A brother always; a girl once the deed that opens the girls is done.
static func character_open(id: String) -> bool:
	var lock := str(GameData.character(id).get("lock", ""))
	return lock == "" or is_open(lock)


static func is_done(deed: String) -> bool:
	return Records.deeds.has(deed)


## Writes down deed [param id] the first time it is done, in a real game.
## Returns what it opens (empty if it was done before, or this is no real
## game).
static func achieve(id: String) -> Array:
	if not recording or Records.deeds.has(id) or not deeds().has(id):
		return []
	Records.deeds.append(id)
	this_run.append(id)
	Records.save()
	return (deeds()[id].get("opens", []) as Array).duplicate()


## What [param opened] (ids from [method achieve]) are called, for a line:
## items by their names, "@evil" and "@girls" by what they are.
static func names(opened: Array) -> Array[String]:
	var out: Array[String] = []
	for id: String in opened:
		match id:
			"@evil":
				out.append("злой режим")
			"@girls":
				out.append("Роза и Ромашка")
			_:
				out.append(str(GameData.items().get(id, {}).get("name", id)))
	return out
