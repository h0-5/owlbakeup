-- owlbakeup Fix #61 - security shim (see meta.xml)
-- The Owl client (job core etc.) calls:
--     exports.security:triggerServerEvent(eventName, element, ...)
-- This shim forwards verbatim; the receiving server resource owns all
-- validation (same trust model as every other owlbakeup server rebuild).
-- NOTE: the builtin is captured BEFORE the global shadowing, otherwise
-- the export would recurse into itself forever.

local _triggerServerEvent = triggerServerEvent

function triggerServerEvent(eventName, element, ...)
	return _triggerServerEvent(eventName, element, ...)
end
