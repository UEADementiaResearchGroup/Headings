local M={}
fastcsv=M

local table=table
local io=io
local assert=assert

setfenv(1,M)

function create(path,headers)
  local fh=assert(io.open(path,"a+"))
  fh:setvbuf("full")
  headers[#headers+1]="\n"
  local line=table.concat(headers, ", ")
  fh:write(line)

  return function (t)
    t[#t+1]="\n"
    fh:write(table.concat(t, ", "))
  end, function()
    fh:flush()
    fh:close()
  end
end

return M