local composer=require "composer"
local scene=composer.newScene()

local data=require "data"
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
    text="Confirm partipant ID:\n"..event.params.id,
    parent=self.view,
    font="BebasNeue Bold.otf",
    fontSize=80,
    width=display.contentWidth-40,
    align="center",
    x=display.contentCenterX,
    y=display.contentCenterY
  })

  local buttonW=(display.contentWidth-60)/2
  local backButton=display.newRoundedRect(
    self.view, 
    display.contentCenterX/2, 
    display.contentHeight-100, 
    buttonW, 
    160, 
    30)
  backButton:setFillColor(17/255,112/255,240/255)
  display.newText({
    parent=self.view,
    text="Back",
    x=backButton.x,
    y=backButton.y,
    font="BebasNeue Bold.otf",
    fontSize=100
  })
  backButton:addEventListener("tap", function()
    composer.gotoScene("scenes.setup") 
  end)

  local forwardButton=display.newRoundedRect(
    self.view, 
    display.contentWidth*3/4, 
    display.contentHeight-100, 
    buttonW, 
    160,
    30)
  forwardButton:setFillColor(17/255,112/255,240/255)
  display.newText({
    parent=self.view,
    text="Use",
    x=forwardButton.x,
    y=forwardButton.y,
    font="BebasNeue Bold.otf",
    fontSize=100
  })
  forwardButton:addEventListener("tap", function()
    data.reset()
    composer.setVariable("id", event.params.id)
    composer.gotoScene("scenes.createtests")
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