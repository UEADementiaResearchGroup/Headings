local composer=require "composer"
local scene=composer.newScene()

local display=display

setfenv(1, scene)

function scene:show(event)
	if event.phase=="did" then
		return
	end
	local button=display.newRoundedRect(self.view, display.contentCenterX, display.contentHeight-100, display.contentWidth-40, 160, 60)
	button:setFillColor(17/255,112/255,240/255)
	local buttonLabel=display.newText({
		parent=self.view,
		text="Next",
		x=button.x,
		y=button.y,
		font="BebasNeue Bold.otf",
		fontSize=140
	})

	local test=event.params.testNumber
	local total=event.params.totalTests
	button:addEventListener("tap", function()
		if test==total then
			composer.gotoScene("scenes.summary")
			return
		end
		composer.gotoScene("scenes.orientuser",{
			params={
				mode="reset",
				orientation=composer.getVariable("reference point")
			},
		})
	end)

	local instructLabel
	if test<total then
		instructLabel=("Test %d complete\nOut of %d"):format(test,total)
	else
		instructLabel="Task Complete"
	end
	display.newText({
		parent=self.view,
		text=instructLabel,
		x=display.contentCenterX,
		y=display.contentCenterY,
		font="BebasNeue Bold.otf",
		fontSize=80,
		width=display.contentWidth-30,
		align="center"
	})
end
scene:addEventListener("show")

function scene:hide(event)
	if not self.view or event.phase=="will" then
		return
	end
	for i=self.view.numChildren,1,-1 do
		self.view[i]:removeSelf()
	end
end
scene:addEventListener("hide")

return scene