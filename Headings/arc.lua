local M={}
arc=M

local display=display
local table=table
local math=math
local print=print

setfenv(1,M)
-- luacheck: allow defined, module

function newArc(start,rotation,radius)
  if rotation*rotation<1 then
    return
  end

  local stop=start+rotation
  if start>stop then
    start,stop=stop,start
  end

  local verticies={}
  for i=start,stop do
    local t=math.rad(i)
    verticies[#verticies+1]=math.cos(t)*radius
    verticies[#verticies+1]=math.sin(t)*radius
    verticies[#verticies+1]=0
    verticies[#verticies+1]=0
  end
  table.remove(verticies)
  table.remove(verticies)

  return display.newMesh({
    mode="strip",
    vertices=verticies
  })
end

return M