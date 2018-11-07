local composer=require "composer"
local scene=composer.newScene()

local compass=require "ui.compass"
local jsonreader=require "jsonreader"
local widget=require "widget"
local arc=require "arc"
local angles=require "angles"
local testrotations=require "testrotations"

local display=display
local Runtime=Runtime
local math=math
local table=table
local print=print
local timer=timer
local system=system
local type=type
local transition=transition

setfenv(1,scene)

function createAnglePicker(testRotations,index,onAngleSelect)
  local group=display.newGroup()
  group.index=index
  local comp=compass.create(0,0)
  group:insert(comp)
  local compassRadius=comp.height/2
  comp.rotation=-90
  
  local previousSavedRotation=testRotations[index]
  local startingRad=math.rad(previousSavedRotation)
  local x=math.cos(startingRad)*compassRadius
  local y=math.sin(startingRad)*compassRadius
  local goal=display.newLine(comp,0,0,x,y)
  goal.strokeWidth=18
  goal:setStrokeColor(0,1,0)

  local prevArc
  local prevRef
  local function drawPrevArc()
    local previousAngle=testrotations.getOrientationBefore(testRotations,group.index)
    if previousAngle then
      local rad=math.rad(previousAngle)
      local x=math.cos(rad)*compassRadius
      local y=math.sin(rad)*compassRadius
      display.remove(prevRef)
      prevRef=display.newLine(comp,0,0,x,y)
      prevRef.strokeWidth=18
      prevRef:setStrokeColor(0.5)
      if true then 
        return
      end

      display.remove(prevArc)
      prevArc=arc.newArc(testRotations[group.index],previousAngle,compassRadius)
      if prevArc then
        comp:insert(prevArc)
        prevArc:translate(prevArc.path:getVertexOffset())
        prevArc:setFillColor(0,0.3)
      end
    end
  end
  drawPrevArc()
  
  local tri=display.newRect(group, 0, comp.y-comp.height/2-50, 100, 100)
  tri:setFillColor(0,1,0)
  tri.path.x2=50
  tri.path.x3=-50

  local arrow=display.newImage(group, "img/arrow.png")
  arrow.isVisible=false
  arrow.anchorY=1
  arrow.x=0
  arrow.y=tri.y

  local direction=display.newText({
    parent=group,
    text="",
    x=0,
    y=arrow.y-arrow.contentHeight/2,
    font="BebasNeue Bold.otf",
    fontSize=60,
    width=display.contentWidth-30,
    align="center"
  })
  direction.alpha=0.8

  local offset
  local degreeLabel
  local targetDegree

  local function drawGoalRotation()
    local startingAngle=testrotations.getOrientationBefore(testRotations,group.index)
    local degreeRotation=testRotations[group.index]

    display.remove(degreeLabel)
    degreeLabel=display.newText({
      parent=group,
      text=("%d°"):format(degreeRotation),
      x=comp.x,
      y=comp.y,
      font="BebasNeue Bold.otf",
      fontSize=160,
      width=display.contentWidth-30,
      align="center"
    })
    degreeLabel:setFillColor(0.2)

    arrow.isVisible=true
    local directionNewText
    if degreeRotation>0 then
      directionNewText="Clockwise Turn"
      arrow.xScale=1
    else
      directionNewText="Anticlockwise Turn"
      arrow.xScale=-1
    end
    direction.text=directionNewText
    
    display.remove(offset)
    offset=arc.newArc(startingAngle,degreeRotation,compassRadius)
    if offset then
      comp:insert(offset)
      offset:translate(offset.path:getVertexOffset())
      offset:setFillColor(1,0,0,0.3)
    end 
  end

  local function updateGoalLine(orientation)
    local gx=math.cos(orientation)*compassRadius
    local gy=math.sin(orientation)*compassRadius
    display.remove(goal)
    goal=display.newLine(comp, 0, 0, gx, gy)
    goal.strokeWidth=18
    goal:setStrokeColor(0,1,0)
  end

  function group:updateStartingAngle()
    drawPrevArc()
    drawGoalRotation()

    local orientation=math.rad(testrotations.getOrientation(testRotations,group.index))
    updateGoalLine(orientation)
  end


  local function handleAngleChange(angle,noObtuse)
    updateGoalLine(angle)

    local targetDegreeRotation = math.deg(angle)-testrotations.getOrientationBefore(testRotations,group.index)
    if noObtuse then
      targetDegreeRotation=math.deg(angles.normaliseAngle(math.rad(targetDegreeRotation)))
    end
    onAngleSelect(group.index,targetDegreeRotation)
  end

  local function sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
  end
  local lastRotation=0
  comp:addEventListener("touch",function(event)
    if event.phase=="ended" then
      return
    end
    local x,y=comp:contentToLocal(event.x, event.y)
    local touchAngle=math.atan2(y, x)
    -- ±π from N
    local startingOrientation=testrotations.getOrientationBefore(testRotations,group.index)
    local rotation=touchAngle-math.rad(startingOrientation)
    rotation=angles.normaliseAngle(rotation)
    -- ±π from orientation
    
    if event.phase=="moved" and (sign(lastRotation)~=sign(rotation) or math.abs(rotation-lastRotation)>math.pi) then
      if math.abs(lastRotation)>math.pi/2 then
        local pi=lastRotation>0 and -math.pi or math.pi
        rotation=-(pi+(pi-rotation))
      end
    end
    lastRotation=rotation
    handleAngleChange(math.rad(startingOrientation)+rotation,event.phase=="began")
    
    return true
  end)


  comp:addEventListener("tap",function(event)
    local x,y=comp:contentToLocal(event.x, event.y)
    local targetAngle=math.atan2(y, x)

    handleAngleChange(targetAngle,true)
    
    return true
  end)
  return group
end

function scene:addDeleteButton(scroll,picker,testRotations,doneButton)
  local buttonWidth=80
  local removeButton=display.newGroup()
  removeButton.anchorX=1
  removeButton.anchorChildren=true
  removeButton:translate(picker.x+picker.contentWidth/2-40,display.contentCenterY)
  local removeButtonBg=display.newRoundedRect(
    removeButton,
    0,
    0,
    buttonWidth, 
    90, 
    20)
  removeButtonBg:setFillColor(240/255,17/255,17/255)
  display.newText({
    parent=removeButton,
    text="X",
    font="BebasNeue Bold.otf",
    fontSize=100
  })
  scroll:insert(removeButton)

  removeButton:addEventListener("tap", function()
    local x=-math.huge
    local view=scroll._collectorGroup
    for i=1, view.numChildren do
      if view[i].x>removeButton.x then
        local sx=view[i].x-display.contentWidth
        x=math.max(x,sx)
        transition.to(view[i],{x=sx})
      end
    end

    table.remove(testRotations,picker.index)
    for i=1, view.numChildren do
      local elem=view[i]
      if elem.index and elem.index>picker.index then
        elem.index=elem.index-1
        elem:updateStartingAngle()
      end
    end

    picker:removeSelf()
    removeButton:removeSelf()
    doneButton.isVisible=view.numChildren>1
    scroll:setScrollWidth(x+display.contentCenterX)
  end)
end

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local path=system.pathForFile("tests.json",system.DocumentsDirectory)
  local tests=jsonreader.load(path) or {}

  local testRotations=tests[event.params.testIndex]
  
  local instructLabel="Touch compass to set the rotation from the starting position\n\nScroll to the side to add extra rotations"
  local instruct=display.newText({
    parent=self.view,
    text=instructLabel,
    x=display.contentCenterX,
    y=15,
    font="BebasNeue Bold.otf",
    fontSize=48,
    width=display.contentWidth-30,
    align="center"
  })
  instruct.anchorY=0

  local scroll=widget.newScrollView({
    verticalScrollDisabled=true,
    left=0,
    top=0,
    width=display.contentWidth,
    height=display.contentHeight,
    hideBackground=true
  })

  self.view:insert(scroll)

  if type(testRotations)~="table" then
    testRotations={testRotations}
  end

  local doneButton=display.newGroup()
  self.view:insert(doneButton)
  doneButton:translate(display.contentCenterX, display.contentHeight-100)
  local button=display.newRoundedRect(doneButton,0,0, display.contentWidth-40, 160, 60)
  button:setFillColor(17/255,112/255,240/255)
  local buttonLabel=display.newText({
    parent=doneButton,
    text="Done",
    x=button.x,
    y=button.y,
    font="BebasNeue Bold.otf",
    fontSize=140
  })
  doneButton.isVisible=#testRotations>0
  
  doneButton:addEventListener("tap", function()
    tests[event.params.testIndex]=testRotations
    jsonreader.store(path,tests)
    composer.gotoScene(event.params.nextScene,{params=event.params.nextParams})
    return true
  end)

  doneButton:addEventListener("touch", function(event)
    return event.phase=="began"
  end)

  function updateRotation(index,angle)
    doneButton.isVisible=true

    testRotations[index]=angle
    for i=1,scroll._collectorGroup.numChildren do
      if scroll._collectorGroup[i].updateStartingAngle then
        scroll._collectorGroup[i]:updateStartingAngle()
      end
    end
  end

  local x=display.contentCenterX
  for i=1, #testRotations do
    local picker=createAnglePicker(testRotations,i,updateRotation)
    picker:translate(x, display.contentCenterY)
    scroll:insert(picker)

    self:addDeleteButton(scroll,picker,testRotations,doneButton)

    x=x+picker.contentWidth
  end

  if #testRotations>0 then
    updateRotation(1,testRotations[1])
  end
  local buttonWidth=250
  local addButton=display.newGroup()
  addButton:translate(x,display.contentCenterY+display.contentWidth/4)
  local addButtonBg=display.newRoundedRect(
    addButton,
    0,
    0,
    buttonWidth, 
    180, 
    60)
  addButtonBg:setFillColor(17/255,112/255,240/255)
  display.newText({
    parent=addButton,
    text="+",
    font="BebasNeue Bold.otf",
    fontSize=280
  })
  scroll:insert(addButton)
  local done=false
  addButton:addEventListener("tap", function()
    if done then
      return
    end
    done=true
    testRotations[#testRotations+1]=0
    local picker=createAnglePicker(testRotations,#testRotations,updateRotation)
    picker:translate(addButton.x, display.contentCenterY)
    scroll:insert(picker)

    self:addDeleteButton(scroll,picker,testRotations,doneButton)
    local ax=addButton.x+display.contentWidth
    scroll:setScrollWidth(ax+display.contentCenterX)
    addButton:toFront()
    transition.to(addButton,{x=ax,onComplete=function() done=false end})
  end)
  scroll:setScrollWidth(x+display.contentCenterX)

  instruct:toFront()
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