local M={}
heading=M

local Runtime=Runtime
local assert=assert
local pairs=pairs

setfenv(1,M)
-- luacheck: allow defined, module

local listeners={}

function addListener(key,func)
  assert(not listeners[key],("heading: %s already has listener assigned"):format(key))
  listeners[key]=func
end

function removeListener(key)
  assert(listeners[key],("heading: %s has no listener assigned"):format(key))
  listeners[key]=nil
end

Runtime:addEventListener("heading", function(event)
  for _, listener in pairs(listeners) do
    listener(event)
  end
end)

return M