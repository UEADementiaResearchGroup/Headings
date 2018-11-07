local M={}
gyroscopedata=M

local Runtime=Runtime
local system=system
local math=math
local tostring=tostring
local os=os
local assert=assert

local fastcsv=require "fastcsv"

setfenv(1,M)

local logging=false
function start(participantID, trial)
	assert(not logging,"Already Logging Gyroscope data")
	logging=true
	system.setGyroscopeInterval(100)
	local startMillis=system.getTimer()
	local filename=("gyroscope_data_%s_trial_%s_on_%s_%s.csv"):format(participantID,tostring(trial),os.date("%d-%m-%Y"),os.date("%H-%M-%S"))
	local path=system.pathForFile(filename, system.DocumentsDirectory)
	local addLine,stop=fastcsv.create(path,{
		"Participant",
		"Trial",
		"Date",
		"Time",
		"Milliseconds Since Trial Start",
		"X Rotation (Deg)",
		"Y Rotation (Deg)",
		"Z Rotation (Deg)",
	})
	local function logData(event)
		local deltaTime=event.deltaTime
		addLine({
			participantID,
			trial,
			os.date("%d/%m/%Y"),
			os.date("%H:%M:%S"),
			system.getTimer()-startMillis,
			math.deg(event.xRotation*deltaTime),
			math.deg(event.yRotation*deltaTime),
			math.deg(event.zRotation*deltaTime),
		})
	end

	Runtime:addEventListener("gyroscope", logData)

	return filename,function()
		logging=false
		system.setGyroscopeInterval(10)
		Runtime:removeEventListener("gyroscope",logData)
		stop()
	end
end

return M