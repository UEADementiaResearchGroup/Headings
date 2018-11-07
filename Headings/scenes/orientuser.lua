local composer=require "composer"
local scene=composer.newScene()

local compass=require "ui.compass"
local testrotations=require "testrotations"
local angles=require "angles"
local arc=require "arc"
local orientationtracker=require "orientationtracker"

local display=display
local math=math
local transition=transition
local timer=timer

setfenv(1,scene)

local TIMER_INTERVAL = 3000

function scene:goToNextScene()
	local testNumber=composer.getVariable("test number") or 1
	local rotationNumber=composer.getVariable("rotation") or 1

	local orientation,rotation=testrotations.getOrientationRotation(testNumber,rotationNumber)

	composer.setVariable("rotation",rotationNumber+1)
  if rotation then
    self.mode="rotate"
    self.setGoal(orientation+composer.getVariable("reference point"),rotation)
  else
    composer.gotoScene("scenes.test")
  end
end

function scene:startTimer()
  if self.timer then
    return
  end
  local iterations = math.ceil(TIMER_INTERVAL/1000)
  self.timer = timer.performWithDelay(1000, function(event)
    self.instructions.text=iterations - (event.count - 1)
    if event.count > iterations then
      display.setDefault("background", 0.4)
      self:goToNextScene()
      self.instructions.text = ""
    end
  end,
  iterations + 1)
end

function scene:cancelTimer()
  if not self.timer then
    return
  end
  timer.cancel(self.timer)
  self.timer = nil
end

function scene:create()
  local comp=compass.create()
  self.view:insert(comp)
  self.compass=comp

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

  local arrow=display.newImage(self.view, "img/arrow.png")
  arrow.anchorY=1
  arrow.x=display.contentCenterX
  arrow.y=tri.y-tri.height/2
  self.arrow=arrow

  local accumulatorText=display.newText({
    text=0,
    parent=self.view,
    x=comp.x,
    y=comp.y-300,
    font="BebasNeue Bold.otf",
    fontSize=100,
  })

  local degText=display.newText({
    text=0,
    parent=self.view,
    x=comp.x,
    y=comp.y-200,
    font="BebasNeue Bold.otf",
    fontSize=100,
  })

  local oriText=display.newText({
    text=0,
    parent=self.view,
    x=comp.x,
    y=comp.y-100,
    font="BebasNeue Bold.otf",
    fontSize=100,
  })

  accumulatorText.isVisible=false
  degText.isVisible=false
  oriText.isVisible=false
  local instruct=display.newText({
    parent=self.view,
    text="",
    x=display.contentCenterX,
    y=15,
    font="BebasNeue Bold.otf",
    fontSize=80,
    width=display.contentWidth-30,
    align="center"
  })
  instruct.anchorY=0
  self.instructions=instruct

  local direction=display.newText({
    parent=self.view,
    text="",
    x=display.contentCenterX,
    y=instruct.y+instruct.height+15,
    font="BebasNeue Bold.otf",
    fontSize=80,
    width=display.contentWidth-30,
    align="center"
  })
  direction.anchorY=0
  self.direction=direction

  local goal
  local targetOrientation
  local requiredRotation
  function self.setGoal(orientation,rotation)
    display.remove(goal)
    targetOrientation=orientation
    requiredRotation=rotation
    local compassRadius=comp.height/2
    local t=math.rad(targetOrientation)
    local x=math.cos(t)*compassRadius
    local y=math.sin(t)*compassRadius
    goal=display.newLine(comp,0,0,x,y)
    goal.strokeWidth=18
    goal:setStrokeColor(0,1,0)

    orientationtracker.resetAccumulator()
  end

  local offset
  local function updateDisplay(geographic,remainingOrientation,remainingDeg)
    if not comp.insert then
      return
    end

    if not comp.transition then
      comp.transition=transition.to(comp, {alpha=1})
    end
    comp.rotation=-geographic-90

    display.remove(offset)
    -- ±10 error on start and end orientation
    local goodRotation=remainingDeg*remainingDeg<20*20
    local goodOrientation=remainingOrientation*remainingOrientation<10*10
    if goodRotation and goodOrientation then
      self:startTimer()
      self.direction.text=""
      self.arrow.isVisible=false
      return
    end
    self:cancelTimer()
    self.arrow.isVisible=true
    self.instructions.text=self.instructLabel

    local opOrientation=remainingOrientation>0 and (360-remainingOrientation) or (remainingOrientation+360)
    local arcAngle
    if self.mode=="reset" then
      arcAngle=math.abs(remainingOrientation)<math.abs(opOrientation) and remainingOrientation or opOrientation
    else
      arcAngle=remainingDeg
      local normDeg=math.deg(angles.normaliseAngle(math.rad(remainingDeg)))
      local error=math.abs(remainingOrientation-normDeg)<math.abs(opOrientation-normDeg)
      and (remainingOrientation-normDeg) or (opOrientation-normDeg)
      arcAngle=arcAngle+error
    end
    self.arrow.xScale=arcAngle<0 and -1 or 1
    offset=arc.newArc(targetOrientation,-arcAngle,comp.width/2)
    if offset then
      comp:insert(offset)
      offset:translate(offset.path:getVertexOffset())
      offset:setFillColor(1,0,0,0.3)
    end
  end

  local trackRotation=function (event)
    local rotationAccumulator=event.rotationAccumulator
    accumulatorText.text=("%.2f"):format(rotationAccumulator)

    local remainingDeg=self.mode=="reset" and 0 or (requiredRotation-rotationAccumulator)
    local remainingOrientation=math.deg(angles.normaliseAngle(math.rad(targetOrientation-event.geographic)))

    degText.text=("%.2f"):format(remainingDeg)
    oriText.text=("%.2f"):format(remainingOrientation)
    updateDisplay(event.geographic,remainingOrientation,remainingDeg)
  end

  -- take into account offset from expected location into account
  orientationtracker.addListener(trackRotation)
end
scene:addEventListener("create")

function scene:setMode(mode)
  if mode=="reset" then
    display.setDefault("background", 0.0,0.5,0.0)
  else
    display.setDefault("background", 0.4)
  end
  self.mode=mode

  local instructLabel=self.mode=="reset" and "Reorient to reference point" or "Turn Participant"
  self.instructions.text=instructLabel
  self.instructLabel=instructLabel
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local targetOrientation=event.params.orientation
	local requiredRotation=event.params.rotation
  self.setGoal(targetOrientation,requiredRotation)

  self:setMode(event.params.mode)

  local directionNewText
	if not self.mode=="reset" then
		if requiredRotation>0 then
			directionNewText="Turn Clockwise"
			self.arrow.xScale=1
		else
			directionNewText="Turn Anticlockwise"
			self.arrow.xScale=-1
		end
	end
  self.direction.text=directionNewText

  local comp=self.compass
  comp.alpha=0
  comp.transition=nil
end
scene:addEventListener("show")

return scene