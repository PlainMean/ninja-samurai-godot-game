class_name Element
extends RefCounted
## Directed advantages only; no resistance or inferred inverse matchup.
enum Type { NONE, FIRE, WATER, EARTH, WIND }
enum Matchup { NEUTRAL, EFFECTIVE }

static func label(value: Type) -> String:
	return Type.keys()[value]

static func resolve(attacker: Type, defender: Type) -> Matchup:
	if (attacker == Type.WATER and defender == Type.FIRE
		or attacker == Type.FIRE and defender == Type.EARTH
		or attacker == Type.EARTH and defender == Type.WIND
		or attacker == Type.WIND and defender == Type.WATER):
		return Matchup.EFFECTIVE
	return Matchup.NEUTRAL

static func damage_for(attacker: Type, defender: Type) -> int:
	return 2 if resolve(attacker, defender) == Matchup.EFFECTIVE else 1

static func weakness(defender: Type) -> Type:
	for attacker in [Type.FIRE, Type.WATER, Type.EARTH, Type.WIND]:
		if resolve(attacker, defender) == Matchup.EFFECTIVE: return attacker
	return Type.NONE
