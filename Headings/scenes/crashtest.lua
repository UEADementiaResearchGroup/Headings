local composer=require "composer"
local scene=composer.newScene()

local compass=require "ui.compass"

local display=display
local Runtime=Runtime
local timer=timer
local math=math
local table=table

setfenv(1,scene)

function goToNextScene()
  composer.removeScene("scenes.crashtest")
  timer.performWithDelay(1, function()
    composer.gotoScene("scenes.crashtest")
  end)
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local comp=compass.create()
  self.view:insert(comp)
  -- comp:translate(display.contentCenterX, display.contentCenterY)
  -- display.newRect(
  --   comp,0,0, 
  --   333, 444)
  local button=display.newRoundedRect(
    self.view, 
    display.contentCenterX, 
    display.contentHeight-100, 
    display.contentWidth-40, 
    160, 60)
  button:setFillColor(17/255,112/255,240/255)
  local buttonLabel=display.newText({
    parent=self.view,
    text="Next",
    x=button.x,
    y=button.y,
    fontSize=140
  })
  
  local listener
  local headingListener
  listener=function()
    button:removeEventListener("tap", listener)
    Runtime:removeEventListener("heading", headingListener)
    display.setDefault("background", 0.4)
  
    goToNextScene()
  end
  button:addEventListener("tap", listener)
  button.isVisible=false
  buttonLabel.isVisible=false
  local offset
  comp.isVisible=false
  local angle=math.random(360)
  headingListener=function (event)
    comp.isVisible=true
    comp.rotation=-event.geographic
    local r = angle-event.geographic
    r = (r + 180) % 360 - 180
    display.remove(offset)

    button.isVisible=false
    buttonLabel.isVisible=false
    if r*r<100 then
      button.isVisible=true
      buttonLabel.isVisible=true
      return
    end

    if r*r>0 then
      local verticies={}
      local compassRadius=333
      for i=0,r,r>0 and 1 or -1 do
        local t=math.rad(angle-i-90)
        verticies[#verticies+1]=math.cos(t)*compassRadius
        verticies[#verticies+1]=math.sin(t)*compassRadius
        verticies[#verticies+1]=0
        verticies[#verticies+1]=0
      end
      table.remove(verticies)
      table.remove(verticies)
      offset=display.newMesh({
        mode="strip",
        parent=comp,
        vertices=verticies
      })
    end
    if offset then
      offset:translate(offset.path:getVertexOffset())
      offset:setFillColor(1,0,0,0.3)
    end    
  end
  Runtime:addEventListener("heading", headingListener)
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