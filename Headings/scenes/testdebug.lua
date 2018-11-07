local composer=require "composer"
local scene=composer.newScene()

local testrotations=require "testrotations"
local timer=timer
local display=display

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local y=50
  local test=1
  while true do
    local r=testrotations.getOrientationRotation(test,1)
    if not r then
      break
    end
    local t=display.newText({
      parent=self.view,
      x=50,
      y=y,
      text=("%d,%.2f"):format(test,r),
      fontSize=40,
      align="left"
    })
    t.anchorX=0
    test=test+1
    y=y+t.height+10
  end

  timer.performWithDelay(500, function() 
    composer.removeScene("scenes.testdebug")
    composer.showOverlay("scenes.testdebug")
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