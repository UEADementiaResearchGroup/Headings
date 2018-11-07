local composer=require "composer"
local scene=composer.newScene()

local display=display
local data=require "data"

setfenv(1, scene)

function scene:create()
	local button=display.newRoundedRect(self.view, 20,20, display.contentWidth-40, display.contentHeight-200, 60)
	button:setFillColor(17/255,112/255,240/255)
	button.anchorX=0
	button.anchorY=0
	display.newText({
		parent=self.view,
		text="Tap to end trial",
		x=button.x+button.width/2,
		y=button.y+button.height/2,
		font="BebasNeue Bold.otf",
		fontSize=140,
		align="center",
		width=button.width-40
	})
	self.button=button

	display.newText({
		parent=self.view,
		text="Participant\nTurns",
		x=display.contentCenterX,
		y=button.y+button.height+100,
		font="BebasNeue Bold.otf",
		fontSize=80,
		align="center"
	})
end
scene:addEventListener("create")

function scene:show(event)
	if event.phase=="will" then
		return
	end

	local stopCollection=data.startCollectingTrial(composer.getVariable("id"),composer.getVariable("reference point"))
	local tapListener
	local called=false
	tapListener=function()
		if called then
			return
		end
		called=true
		self.button:removeEventListener("tap", tapListener)
		stopCollection()
		composer.setVariable("rotation",1)
		local total=composer.getVariable("total tests")
		local test=composer.getVariable("test number") or 1
		composer.gotoScene("scenes.testcomplete",{
			params={testNumber=test,totalTests=total}
		})
		test=test+1
		composer.setVariable("test number",test)
	end
	self.button:addEventListener("tap", tapListener)
end
scene:addEventListener("show")

return scene