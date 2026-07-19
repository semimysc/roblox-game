-- Shared.Battle.TokenRecall
-- Recall TYPE behaviors — distinct from token MEMBERSHIP.
-- A card's recall.type decides HOW a swap is chosen when it leaves:
--   * "clockwise"  -> default: next card from the clockwise neighbor token
--                     (handled by TokenRing.defaultSwapIn)
--   * "specified"  -> replacesWith names the exact incoming card
--   * "conditional"-> a registered handler decides (ability/passive override)
--
-- This module builds the override descriptor the TokenRing consumes. It is
-- the bridge between a card's declarative recall.type and the swap resolution.
--
-- Pure logic.

local TokenRecall = {}

-- Given a leaving card + the ring, produce an override for TokenRing.
-- Returns { replacesWith = id? } or nil (nil => TokenRing uses its default).
function TokenRecall.resolve(
	recall: {
		type: string,
		replacesWith: string?,
		returnsTo: any,
	},
	ring: any,
	ctx: any?
): { replacesWith: string? }?
	if recall.type == "specified" then
		return { replacesWith = recall.replacesWith }
	elseif recall.type == "conditional" then
		-- A registered conditional handler (set by AutoPlay/ability) may
		-- override. We look it up from ctx if provided.
		if ctx and ctx.conditionalRecall then
			return { replacesWith = ctx.conditionalRecall }
		end
		-- No handler yet -> fall through to default clockwise.
		return nil
	end
	-- "clockwise" (or unknown) -> let TokenRing use its default.
	return nil
end

return TokenRecall
