local composer=require "composer"
local scene=composer.newScene()

local compass=require "ui.compass"
local testrotations=require "testrotations"
local angles=require "angles"

local display=display
local Runtime=Runtime
local math=math
local table=table
local print=print
local timer=timer
local tonumber=tonumber
local system=system

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end
  local comp=compass.create()
  self.view:insert(comp)

  local compassRadius=comp.height/2
  local turns=display.newText({
    parent=self.view,
    text="0",
    x=display.contentCenterX,
    y=15,
    font="BebasNeue Bold.otf",
    fontSize=80,
    width=display.contentWidth-30,
    align="center"
  })
  turns.anchorY=0

  local changedDir=display.newText({
    parent=self.view,
    text="No turn",
    x=display.contentCenterX,
    y=turns.y+turns.height,
    font="BebasNeue Bold.otf",
    fontSize=80,
    width=display.contentWidth-30,
    align="center"
  })
  changedDir.anchorY=0

  local y=changedDir.y+changedDir.height
  local axis={"x","y","z"}
  local gyroscope={}
  local accelerometer={}
  for i=1,#axis do
    local x=(i-1)*display.contentWidth/#axis-display.contentWidth/#axis/2
    gyroscope[axis[i]]=display.newText({
      parent=self.view,
      text="0",
      x=x,
      y=y,
      font="BebasNeue Bold.otf",
      fontSize=80,
      width=display.contentWidth-30,
      align="right"
    })
    local ga=gyroscope[axis[i]]
    gyroscope[axis[i]].anchorY=0

    accelerometer[axis[i]]=display.newText({
      parent=self.view,
      text="0",
      x=x,
      y=ga.y+ga.height,
      font="BebasNeue Bold.otf",
      fontSize=80,
      width=display.contentWidth-30,
      align="right"
    })
    accelerometer[axis[i]].anchorY=0
  end

  local error=display.newText({
    parent=self.view,
    text="",
    x=display.contentCenterX,
    y=turns.y+turns.height*4,
    font="BebasNeue Bold.otf",
    fontSize=80,
    width=display.contentWidth-30,
    align="center"
  })
  error.anchorY=0
  local listener
  local updateCompass

  local offset
  comp.isVisible=false

  local lastGeographic
  local lastDg=0
  local rotationAccumulator=0
  local directionChanged=false

  local function sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
  end

  local startOrientation
  updateCompass=function (event)
    comp.isVisible=true
    comp.rotation=-event.geographic
    startOrientation=(startOrientation or event.geographic)
    local dg=event.geographic-(lastGeographic or event.geographic)
    if dg*dg>300*300 then
      error.text=dg
      if dg<0 then
        dg=360+dg
      else
        dg=-(360-dg)
      end
    end
    directionChanged=false
    lastDg=dg
    rotationAccumulator=rotationAccumulator+dg
    lastGeographic=event.geographic

    -- error.text=event.geographic-((rotationAccumulator%360)+startOrientation)
    turns.text=rotationAccumulator/360
  end
  Runtime:addEventListener("heading", updateCompass)

  local lastZRotationSign=0
  onGyroscope=function (event)
    for i=1,#axis do
      local ax=axis[i]
      local val=event[ax.."Rotation"]
      gyroscope[ax].text=("%.3f"):format(val)
      gyroscope[ax]:setFillColor(val<0 and 1 or 0, val>0 and 1 or 0,0)
    end
    local zRotationSign=sign(event.zRotation)
    if zRotationSign~=lastZRotationSign then
      changedDir.text="Changed!"
      directionChanged=true
    else
      changedDir.text="Same"
    end
    lastZRotationSign=zRotationSign
  end
  Runtime:addEventListener("gyroscope", onGyroscope)

  onAccelerometer=function (event)
    for i=1,#axis do
      local ax=axis[i]
      local val=event[ax.."Gravity"]
      accelerometer[ax].text=("%.3f"):format(val)
      accelerometer[ax]:setFillColor(val<0 and 1 or 0, val>0 and 1 or 0,0)
    end
  end
  Runtime:addEventListener("accelerometer", onAccelerometer)
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