local composer=require "composer"
local scene=composer.newScene()

local data=require "data"
local widget=require "widget"
local emailzip=require "emailzip"
local jsonreader=require "jsonreader"
local display=display
local system=system
local table=table

setfenv(1, scene)

local function formatRotationsArray(rotations)
  local niceRotations={}
  for i=1,#rotations do
    niceRotations[i]=("%d°"):format(rotations[i])
  end
  return table.concat(niceRotations,", ")
end

function scene:show(event)
  if event.phase=="did" then
    return
  end
  data.writeToFile(composer.getVariable("id"))

  local emailButton=display.newRoundedRect(self.view,
    display.contentCenterX,
    display.contentHeight-100,
    display.contentWidth-40,
    160,
    60)
  emailButton.isVisible=false
  local zipFile
  zipFile=data.zipData(composer.getVariable("id"),function(event)
    if event.isError then
      native.showAlert("Warning", "Unable to compress data, it will not be possible to e-mail it. Please check space available on device",{"Ok"})
      return
    end

    emailButton.isVisible=true
    emailButton:setFillColor(17/255,112/255,240/255)
    local label=display.newText({
      parent=self.view,
      text="E-mail Data",
      x=emailButton.x,
      y=emailButton.y,
      font="BebasNeue Bold.otf",
      fontSize=100
    })

    local emailListener
    emailListener=function()
      label.text="New Test"
      emailButton:removeEventListener("tap",emailListener)
      emailButton:addEventListener("tap",function()
        data.reset()
        composer.gotoScene("scenes.setup")
      end)

      emailzip.send(composer.getVariable("id"),zipFile)
    end
    emailButton:addEventListener("tap",emailListener)
  end)

  local title=display.newText({
    parent=self.view,
    text="Summary",
    font="BebasNeue Bold.otf",
    x=display.contentCenterX,
    y=20,
    fontSize=80
  })
  title.anchorY=0

  local top=title.y+title.height+20
  local height=display.contentHeight-top-emailButton.contentHeight-60

  local scroll=widget.newScrollView({
    top=top,
    left=0,
    width=display.contentWidth,
    height=height,
    horizontalScrollDisabled=true,
    hideBackground=true,
  })
  local y=30
  self.view:insert(scroll)

  local path=system.pathForFile("tests.json",system.DocumentsDirectory)
  local tests=jsonreader.load(path)
  for row in data.getIterator() do
    local error=row.referenceAngle-row.submittedAngle
    local rotations=formatRotationsArray(tests[row.trial])
    local str=("%3d.\n     Target: %4.1d°\n     Result: %4.1d°\n     Error:%4.1d°\n     Rotations: %s"):format(
    row.trial,
    row.referenceAngle,
    row.submittedAngle,
    error,
    rotations)
    local text=display.newText({
      text=str,
      x=scroll.width/2,
      y=y,
      font="BebasNeue Bold.otf",
      fontSize=80,
      width=display.contentWidth-30,
      align="left"
    })
    text.anchorY=0
    scroll:insert(text)

    local bg=display.newRect(
      scroll.width/2,
      text.y+text.height/2,
      scroll.width,
      text.contentHeight)
    bg:setFillColor(row.trial%2==0 and 0.5 or 0.4)
    scroll:insert(bg)
    bg:toBack()

    y=y+text.height
  end
  scroll:setScrollHeight(y)
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