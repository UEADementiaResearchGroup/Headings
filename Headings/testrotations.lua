local M={}
testrotations=M

local jsonreader=require "jsonreader"
local system=system
local type=type
local error=error

setfenv(1,M)
-- luacheck: allow defined, module

function getOrientationBefore(testRotations,rotationIndex)
  return getOrientation(testRotations,rotationIndex-1)
end

function getOrientation(testRotations,rotationIndex)
  local orientation=0
  for i=1,rotationIndex do
    orientation=orientation+testRotations[i]
  end
  return orientation
end

function getOrientationRotation(testNumber,rotationNumber)
  local path=system.pathForFile("tests.json",system.DocumentsDirectory)
  local tests,err=jsonreader.load(path)
  if err then
    error(err)
  end

  local rotations=tests[testNumber]
  if not rotations then
    return
  end
  if type(rotations)~="table" then
    rotations={rotations}
  end

  if rotationNumber>#rotations then
    return
  end

  local orientation=getOrientation(rotations,rotationNumber)
  return orientation,rotations[rotationNumber]
end

return M