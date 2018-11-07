display.setStatusBar(display.HiddenStatusBar)
display.setDefault("background", 0.4)
local composer=require "composer"

if false and not native.canShowPopup("mail") then
  native.showAlert("No e-mail detected", "This app relies on a working e-mail client installed on the device to work. This is so that the collected data can be transfered off the device via e-mail. Check that an e-mail account is set up correctly by opening Settings > Accounts &  Passwords. Apple provide free icloud e-mails you can use for this purpose.",{"Ok"})
  return
end
local zip = require "plugin.zip"

require "heading"
composer.gotoScene("scenes.setup")

local function handleLowMemory()
    print( "Memory warning received!" )
end

Runtime:addEventListener( "memoryWarning", handleLowMemory )