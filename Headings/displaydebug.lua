local M={}
displaydebug=M

local display=display
local Runtime=Runtime
local system=system

setfenv(1,M)
-- luacheck: allow defined, module

local displayStr="Display Objects: %d"
local displayText=display.newText({
	text=displayStr:format(0),
	align="left",
	fontSize=40,
})
displayText.anchorX=0
displayText.anchorY=0
displayText:translate(50, 50)

local memStr="Texutre Memory Used: %d"
local memText=display.newText({
	text=memStr:format(0),
	align="left",
	fontSize=40,
})
memText.anchorX=0
memText.anchorY=0
memText:translate(50, 100)

function countChildren(group)
	local total=group.numChildren
	for i=1, group.numChildren do
		if group[i].numChildren then
			total=total+countChildren(group[i])
		end
	end

	return total
end
Runtime:addEventListener("enterFrame", function()
	local stage=display.getCurrentStage()
	displayText.text=displayStr:format(countChildren(stage))
	memText.text=memStr:format(system.getInfo("textureMemoryUsed")/1000)
end)

return M