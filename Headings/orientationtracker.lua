local M={}
orientationtracker=M

local heading=require "heading"

setfenv(1,M)
-- luacheck: allow defined, module

local rotationAccumulator=0
local lastGeographic

local listener

local function track(event)
  local dg=event.geographic-(lastGeographic or event.geographic)
  if dg*dg>300*300 then
    if dg<0 then
      dg=360+dg
    else
      dg=-(360-dg)
    end
  end
  rotationAccumulator=rotationAccumulator+dg
  lastGeographic=event.geographic
  event.rotationAccumulator=rotationAccumulator
  if listener then
    listener(event)
  end
end

heading.addListener("orientationtracker",track)

function resetAccumulator()
  rotationAccumulator=0
end

function addListener(func)
  listener=func
  resetAccumulator()
end

return M