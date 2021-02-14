-- LuaScript1
-- Author: LI Kun
-- DateCreated: 2021-2-13 10:43:16 AM
--------------------------------------------------------------

function init()
	print("FQ UI loaded!")
	Events.LocalPlayerTurnBegin.Add(test_function)
end
local i = 0
function test_function()
	print("turn start from UI!")
end

Events.LoadScreenClose.Add(init)
