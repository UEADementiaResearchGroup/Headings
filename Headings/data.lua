local M={}
data=M

local gyroscopedata=require "gyroscopedata"
local accelerometerdata=require "accelerometerdata"
local fastcsv=require "fastcsv"
local csv=require "csv"
local zip = require "plugin.zip"
local jsonreader=require "jsonreader"
local heading=require "heading"

local os=os
local tostring=tostring
local system=system
local assert=assert
local print=print
local type=type
local table=table

setfenv(1,M)
-- luacheck: allow defined, module

local rows={}

local function setupHeadingDataLogging(participantID,trial)
	local startMillis=system.getTimer()
	local filename=("heading_data_%s_trial_%s_on_%s_%s.csv"):format(participantID,
		tostring(trial),
		os.date("%d-%m-%Y"),
		os.date("%H-%M-%S"))
	local path=system.pathForFile(filename, system.DocumentsDirectory)
	local addLine,stop=fastcsv.create(path,{
		"Participant",
		"Trial",
		"Date",
		"Time",
		"Milliseconds Since Trial Start",
		"Magnetic",
		"Geographic",
	})
	local function logData(event)
		addLine({
			participantID,
			trial,
			os.date("%d/%m/%Y"),
			os.date("%H:%M:%S"),
			system.getTimer()-startMillis,
			event.magnetic,
			event.geographic,
		})
	end
	return filename,logData,stop
end

function startCollectingTrial(participantID,referenceAngle)
	assert(not rows[#rows] or rows[#rows]["Submitted Orientation"],"Previous data collection not completed!")
	participantID=tostring(participantID)
	local trial=#rows+1
	local gyroscopeFilename,stopRecordingGyroscope=gyroscopedata.start(participantID,trial)
	local accelerometerFilename,stopRecordingAccelerometer=accelerometerdata.start(participantID,trial)
	local headingFile,recordHeadingEvent,flushHeadingDataToFile=setupHeadingDataLogging(participantID,trial)
	local path=system.pathForFile("tests.json",system.DocumentsDirectory)
	local tests=jsonreader.load(path)
	local rotations=tests[trial]
	if type(rotations)~="table" then
		rotations={rotations}
	end

	rows[#rows+1]={
		Participant=participantID,
		Trial=trial,
		Date=os.date("%d/%m/%Y"),
		Time=os.date("%H:%M:%S"),
		["Reference Orientation"]=referenceAngle,
		["Heading File"]=headingFile,
		["Gyroscope File"]=gyroscopeFilename,
		["Accelerometer File"]=accelerometerFilename,
	 	["Rotations (Relative to Reference Orientation)"]=table.concat(rotations," > ")
	}

	local lastHeading=system.getInfo("environment")=="simulator" and -1
	local handleEvent=function(event)
		recordHeadingEvent(event)
		lastHeading=event.magnetic
	end
	heading.addListener("heading", handleEvent)

	return function ()
		heading.removeListener("heading",handleEvent)
		rows[#rows]["Submitted Orientation"]=lastHeading
		stopRecordingGyroscope()
		stopRecordingAccelerometer()
		flushHeadingDataToFile()
	end
end

local mainfile
function writeToFile(participantID)
	local filename=("%s_trials_%s.csv"):format(tostring(participantID),os.date("%d-%m-%Y"))
	mainfile=filename
	local path=system.pathForFile(filename,system.DocumentsDirectory)

	local addRow=csv.create(path,{
		"Participant",
		"Trial",
		"Date",
		"Time",
		"Reference Orientation",
		"Submitted Orientation",
		"Rotations (Relative to Reference Orientation)",
		"Heading File",
		"Gyroscope File",
		"Accelerometer File"
	})
	for i=1,#rows do
		addRow(rows[i])
	end
	return filename
end

local function getFilenames()
	local files={mainfile}
	for i=1, #rows do
		files[#files+1]=rows[i]["Heading File"]
		files[#files+1]=rows[i]["Gyroscope File"]
		files[#files+1]=rows[i]["Accelerometer File"]
	end
	return files
end

function zipData(participantID,onComplete)
	local filename=("%s_%s_headings_data.zip"):format(tostring(participantID),os.date("%d-%m-%Y"))
	zip.compress({
		zipFile=filename,
		zipBaseDir=system.TemporaryDirectory,
		srcFiles=getFilenames(),
		srcBaseDir=system.DocumentsDirectory,
		listener=onComplete,
	})
	return filename
end

function getIterator()
	local i=0
	return function()
		i=i+1
		local d=rows[i]
		if not d then return nil end
		return {
			participant=d.Participant,
			trial=d.Trial,
			referenceAngle=d["Reference Orientation"],
			submittedAngle=d["Submitted Orientation"],
		}
	end,i
end

function reset()
	rows={}
end

return M