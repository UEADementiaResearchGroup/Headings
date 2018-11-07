local M={}
accelerometerdata=M

local Runtime=Runtime
local system=system
local tostring=tostring
local os=os
local assert=assert

local fastcsv=require "fastcsv"

setfenv(1,M)
-- luacheck: allow defined, module

local logging=false
function start(participantID, trial)
	assert(not logging,"Already logging Accelerometer Data!")
	logging=true
	system.setAccelerometerInterval(100)

	local startMillis=system.getTimer()
	local filename=("accelerometer_data_%s_trial_%s_on_%s_%s.csv"):format(participantID,tostring(trial),os.date("%d-%m-%Y"),os.date("%H-%M-%S"))
	local path=system.pathForFile(filename, system.DocumentsDirectory)
	local addLine,stop=fastcsv.create(path,{
		"Participant",
		"Trial",
		"Date",
		"Time",
		"Milliseconds Since Trial Start",
		"X Gravity",
		"Y Gravity",
		"Z Gravity",
		"X Gravity Raw",
		"Y Gravity Raw",
		"Z Gravity Raw",
		"Delta Time"
	})
	local function logData(event)
		addLine({
			participantID,
			trial,
			os.date("%d/%m/%Y"),
			os.date("%H:%M:%S"),
			system.getTimer()-startMillis,
			event.xGravity,
			event.yGravity,
			event.zGravity,
			event.xRaw,
			event.yRaw,
			event.zRaw,
			event.deltaTime
		})
	end

	Runtime:addEventListener("accelerometer", logData)

	return filename,function()
		logging=false
		system.setAccelerometerInterval(10)
		Runtime:removeEventListener("accelerometer",logData)
		stop()
	end
end

return M