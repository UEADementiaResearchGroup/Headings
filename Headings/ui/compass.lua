local M={}
compass=M

local display=display
local math=math

setfenv(1,M)

function create(x,y)
	local compass=display.newGroup()
	local radius=display.contentWidth/2
	local bg=display.newCircle(compass,0,0, radius)
	bg:setFillColor(0.85)

	local ew=display.newLine(compass,-bg.width/2,0,bg.width/2,0)
	local ns=display.newLine(compass,0,-bg.height/2,0,bg.height/2)

	ns.strokeWidth=18
	ew.strokeWidth=18
	ns:setStrokeColor(0.4)
	ew:setStrokeColor(0.4)

	compass:translate(x or display.contentCenterX, (y or display.contentCenterY)+bg.height/2)

	for deg=0, 360, 5 do
		local rad=math.rad(deg)
		local cr=math.cos(rad)
		local sr=math.sin(rad)
		local x1=cr*radius
		local y1=sr*radius
		local length=deg%20==0 and 30 or 10
		local x2=cr*(radius-length)
		local y2=sr*(radius-length)
		local line=display.newLine(compass,x1,y1,x2,y2)
		line:setStrokeColor(0.2)
		line.strokeWidth=10
	end

	return compass
end
return M