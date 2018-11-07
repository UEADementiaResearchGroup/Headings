local composer=require "composer"
local scene=composer.newScene()

local widget=require "widget"
local display=display
local print=print
local native=native

setfenv(1, scene)

-- First ask for user id
-- Dial in angles

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local label=display.newText({
    text="Enter the participant ID:",
    parent=self.view,
    font="BebasNeue Bold.otf",
    fontSize=80,
    width=display.contentWidth-40,
    align="center"
  })
  local tf=native.newTextField(display.contentCenterX, display.contentCenterY-200, display.contentWidth/2, 120)
  tf.font=native.newFont("BebasNeue Bold.otf",80)
  tf:resizeHeightToFitFont()
  label.x=display.contentCenterX
  label.y=tf.contentBounds.yMin-label.height/2

  tf:addEventListener("userInput", function(event)
    if event.phase == "ended" or event.phase == "submitted" then
      tf:removeSelf()
      composer.gotoScene("scenes.confirmid",{params={id=event.target.text}})
    end
  end)
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