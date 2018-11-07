local M={}
angles=M

local math=math

setfenv(1,M)

function normaliseAngle(angle)
  return angle-math.pi*2*math.floor((angle+math.pi)/(math.pi*2))
end

return M