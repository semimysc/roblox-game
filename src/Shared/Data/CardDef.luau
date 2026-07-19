-- Shared.Data.CardDef
-- The card/character definition schema. This is the DATA authors write (and
-- later, what Comfy-pilot / placeholders generate). The runtime Combatant is
-- built FROM a CardDef.
--
-- DESIGN (from game design):
--   * A card is either a LEADER (no token — sits on field, never in reserve)
--     or a TOKEN card (lives in the 3-token reserve ring).
--   * Token cards have a tokenType (their role/identity within a token).
--   * Recall TYPE is distinct from token: it's the behavior when the card
--     leaves (clockwise / specified / conditional), separate from WHICH token
--     it belongs to.
--   * Abilities cost ABILITY POINTS from a per-character bar (auto-play uses
--     them on condition or automatically).
--   * Stats follow the declarative StatBlock model (see Stats.luau).

export type Element = "Physical" | "Fire" | "Ice" | "Lightning" | "Wind" | "Quantum" | "Imaginary" | "Void"

export type RecallType =
	"clockwise" -- default: next card from clockwise neighbor token
	| "specified" -- recall.token.replacesWith names the exact card
	| "conditional" -- a condition decides (handled by ability/passive override)

export type AbilityPointBar = {
	max: number, -- total ability points
	regenPerTurn: number, -- points regained each of the card's turns
}

export type Ability = {
	id: string,
	name: string,
	cost: number, -- ability points consumed
	-- "auto"   = used automatically when affordable + condition met
	-- "cond"   = used only when `trigger` returns true
	-- "manual" = (reserved) player/AI triggers explicitly
	cast: "auto" | "cond" | "manual",
	trigger: ((ctx: any) -> boolean)?, -- for "cond"/"auto"
	-- What it does: a list of effect descriptors (data, resolved by engine).
	effects: { [string]: any },
}

export type CardDef = {
	id: string,
	name: string,
	kind: "leader" | "token",
	-- For token cards: their role within a token (data only; the ring uses
	-- originToken for placement). For leaders this is nil.
	tokenType: string?,
	element: Element,
	-- Base stats (StatBlock inputs).
	stats: {
		hp: number,
		atk: number,
		def: number,
		spd: number,
		critRate: number?,
		critDmg: number?,
	},
	powerLevel: number, -- drives log10 combat scaling
	-- Token placement (originToken). Leaders ignore this.
	originToken: number?,
	-- Recall behavior (distinct from token membership).
	recall: {
		type: RecallType,
		replacesWith: string?, -- for "specified"
		returnsTo: "origin" | number,
	},
	-- Per-character ability-point bar.
	abilityBar: AbilityPointBar,
	passive: { id: string, effects: { [string]: any } }?,
	ultimate: { id: string, cost: number, effects: { [string]: any } },
	abilities: { Ability },
}

return {} -- types-only module; CardDef is consumed by Combatant/Battle
