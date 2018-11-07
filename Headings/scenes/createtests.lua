local composer=require "composer"
local scene=composer.newScene()

local compass=require "ui.compass"
local jsonreader=require "jsonreader"
local widget=require "widget"
local arc=require "arc"

local display=display
local Runtime=Runtime
local math=math
local table=table
local print=print
local timer=timer
local system=system
local type=type

setfenv(1,scene)

function scene:show(event)
  if event.phase=="did" then
    return
  end

  local path=system.pathForFile("tests.json",system.DocumentsDirectory)
  local tests=jsonreader.load(path) or {}

  local title=display.newText({
    parent=self.view,
    text="Tests",
    font="BebasNeue Bold.otf",
    x=display.contentCenterX,
    y=20,
    fontSize=80
  })
  title.anchorY=0

  local button=display.newRoundedRect(self.view, display.contentCenterX, display.contentHeight-100, display.contentWidth-40, 160, 60)
  button:setFillColor(17/255,112/255,240/255)
  local buttonLabel=display.newText({
    parent=self.view,
    text="Start",
    x=button.x,
    y=button.y,
    font="BebasNeue Bold.otf",
    fontSize=140
  })

  local testsExist=#tests>0
  button.isVisible=testsExist
  buttonLabel.isVisible=testsExist
  button:addEventListener("tap", function()
    composer.setVariable("test number",1)
    composer.setVariable("total tests",#tests)
    composer.gotoScene("scenes.setreference")
  end)

  local top=title.y+title.height+20
  local height=display.contentHeight-top-button.contentHeight-60

  local scroll=widget.newScrollView({
    horizontalScrollDisabled=true,
    left=0,
    top=top,
    width=display.contentWidth,
    height=height,
    hideBackground=true
  })

  self.view:insert(scroll)

  local y=20
  for i=1,#tests do
    local testGroup=display.newGroup()
    scroll:insert(testGroup)
    local rotations=tests[i]
    if type(rotations)~="table" then
      rotations={rotations}
    end

    local comp=compass.create()
    comp:translate(0, -display.contentCenterY-comp.contentHeight/2)
    testGroup:insert(comp)
    local compassRadius=comp.height/2
    comp.rotation=-90

    do 
      local tri=display.newRect(testGroup, display.contentCenterX, comp.y-comp.height/2-50, 100, 100)
      tri:setFillColor(0,1,0)
      tri.path.x2=50
      tri.path.x3=-50

      local x=math.cos(0)*compassRadius
      local y=math.sin(0)*compassRadius
      local reference=display.newLine(comp,0,0,x,y)
      reference.strokeWidth=18
      reference:setStrokeColor(1)
    end
    
    local lastOrientation=0
    for i=1, #rotations do
      local currentAngle=rotations[i]
      local orientation=lastOrientation+currentAngle
      do 
        local rad=math.rad(orientation)
        local x=math.cos(rad)*compassRadius
        local y=math.sin(rad)*compassRadius
        local reference=display.newLine(comp,0,0,x,y)
        reference.strokeWidth=18
        if i<#rotations then
          reference:setStrokeColor(0,i/#rotations,0)
        else 
          reference:setStrokeColor(0,1,0)
        end
      end
      local arc=arc.newArc(lastOrientation,orientation,compassRadius)
      lastOrientation=orientation
      if arc then
        comp:insert(arc)
        arc:translate(arc.path:getVertexOffset())
        arc:setFillColor(0,0.3)
      end
    end
    testGroup:scale(0.2,0.2)
    testGroup.x=20
    testGroup.y=y+testGroup.contentHeight/2
    y=testGroup.y+testGroup.contentHeight/2+20

    local index=i
    local ordinalLabel=display.newText({
      text=index..".",
      x=60,
      y=testGroup.y,
      font="BebasNeue Bold.otf",
      fontSize=80,
      align="right"
    })
    testGroup:translate(80, 0)
    scroll:insert(ordinalLabel)

    local buttonWidth=160
    local editButton=display.newRoundedRect(
      testGroup.x+testGroup.contentWidth+buttonWidth/2+20, 
      testGroup.y, 
      buttonWidth, 
      120, 
      40)
    editButton:setFillColor(17/255,112/255,240/255)
    scroll:insert(editButton)
    local buttonLabel=display.newText({
      text="Edit",
      x=editButton.x,
      y=editButton.y,
      font="BebasNeue Bold.otf",
      fontSize=80
    })
    scroll:insert(buttonLabel)
    editButton:addEventListener("tap", function()
      composer.gotoScene("scenes.pickangle",{
        params={
          testIndex=index,
          nextScene="scenes.createtests"
        }
      })
    end)

    local buttonWidth=80
    local deleteButton=display.newRoundedRect(
      editButton.x+editButton.contentWidth/2+buttonWidth/2+20, 
      testGroup.y, 
      buttonWidth, 
      120, 
      30)
    deleteButton:setFillColor(240/255,17/255,112/255)
    scroll:insert(deleteButton)
    local buttonLabel=display.newText({
      text="X",
      x=deleteButton.x,
      y=deleteButton.y,
      font="BebasNeue Bold.otf",
      fontSize=80
    })
    scroll:insert(buttonLabel)
    deleteButton:addEventListener("tap", function()
      table.remove(tests,index)
      jsonreader.store(path,tests)
      composer.gotoScene("scenes.createtests")
    end)

    local bg=display.newRect(
      scroll.width/2,
      testGroup.y,
      scroll.width,
      testGroup.contentHeight)
    bg:setFillColor(i%2==0 and 0.5 or 0.4)
    scroll:insert(bg)
    bg:toBack()
  end

  local buttonWidth=160
  local addButton=display.newRoundedRect(
    scroll.width/2, 
    y+60+20, 
    buttonWidth, 
    120, 
    40)
  addButton:setFillColor(17/255,112/255,240/255)
  scroll:insert(addButton)
  local buttonLabel=display.newText({
    text="+",
    x=addButton.x,
    y=addButton.y,
    font="BebasNeue Bold.otf",
    fontSize=200
  })
  scroll:insert(buttonLabel)
  addButton:addEventListener("tap", function()
    composer.gotoScene("scenes.pickangle",{
      params={
        testIndex=#tests+1,
        nextScene="scenes.createtests"
      }
    })
  end)

  scroll:setScrollHeight(addButton.y+addButton.contentHeight/2+20)
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