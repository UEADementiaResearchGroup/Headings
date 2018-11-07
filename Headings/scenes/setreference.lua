local composer=require "composer"
local scene=composer.newScene()

local compass=require "ui.compass"
local heading=require "heading"

local transition=transition
local display=display
setfenv(1,scene)

function scene:show(event)
	if event.phase=="did" then
		return
	end
	display.setDefault("background", 0.0,0.5,0.0)
	local comp=compass.create()
	self.view:insert(comp)

  display.newText({
    parent=self.view,
    text="Shake to Start",
    x=comp.x,
    y=comp.y,
    font="BebasNeue Bold.otf",
    fontSize=200,
    width=display.contentWidth-30,
    align="center"
  })
  comp:toFront()

	local tri=display.newRect(self.view, display.contentCenterX, comp.y-comp.height/2-50, 100, 100)
	tri:setFillColor(0,1,0)
	tri.path.x2=50
	tri.path.x3=-50

	local instruct=display.newText({
		parent=self.view,
		text="Set Reference Point",
		x=display.contentCenterX,
		y=tri.y-tri.height/2,
		font="BebasNeue Bold.otf",
		fontSize=80
	})
	instruct.anchorY=1

	local button=display.newRoundedRect(self.view,
		display.contentCenterX,
		display.contentHeight-100,
		display.contentWidth-40,
		160,
		60)
	button:setFillColor(17/255,112/255,240/255)
	local buttonLabel=display.newText({
		parent=self.view,
		text="Set",
		x=button.x,
		y=button.y,
		font="BebasNeue Bold.otf",
		fontSize=140
	})
	button.isVisible=false
	buttonLabel.isVisible=false
	comp.alpha=0
	local function updateCompass(compEvent)
		button.isVisible=true
		buttonLabel.isVisible=true
		comp.rotation=-compEvent.magnetic
		if not comp.transition then
			comp.transition=transition.to(comp, {alpha=1})
		end
	end

	local tapListener
	tapListener=function()
		heading.removeListener("setreference", updateCompass)
		button:removeEventListener("tap", tapListener)
		display.setDefault("background", 0.4)
		composer.setVariable("reference point", -comp.rotation)
		composer.gotoScene("scenes.orientuser",{
			params={
				mode="reset",
				orientation=composer.getVariable("reference point")
			}
		})
	end
	button:addEventListener("tap", tapListener)

	heading.addListener("setreference", updateCompass)
end
scene:addEventListener("show")

function scene:hide(event)
	if event.phase=="will" then
		return
	end
	for i=self.view.numChildren,1,-1 do
		self.view[i]:removeSelf()
	end
end
scene:addEventListener("hide")

return scene