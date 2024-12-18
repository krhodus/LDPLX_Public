--[[
FM Confidence Monitor
Created by K. Rhodus
kevin@lightshownetwork.cpm

Version History:
1.0 - Initial Build

]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
json = require("rapidjson")
SigPresence = Component.New("FMSigPres")  --Move to control

-----------------------------------------------------------------------------------------------------------------------------------------
--      Timer Setup      --
----------------------------------------------------------------------------------------------------------------------------------------

CheckTimer = Timer.New()

CheckTimer.EventHandler = function()
  
  if Controls.FMPower.Boolean then 
    local overallFlag = false
    --print(json.encode(SigPresFlags, {"pretty=true"}))

    for idx,ctl in ipairs(SigPresFlags) do
      if ctl == true then
        overallFlag = true
      end 

      SigPresFlags[idx] = false
    end

    --print(json.encode(SigPresFlags, {"pretty=true"}))
    print(overallFlag)

    if overallFlag == false then 
      Controls.Status.Value = 1
      Controls.Status.String = "No Show Audio Detected"
    else
      Controls.Status.Value = 0
      Controls.Status.String = "Show Audio Detected"
    end
  else
    Controls.Status.Value = 0
    Controls.Status.String = "Outside of Transmit Hours"
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Signal Presence Flagging      --
----------------------------------------------------------------------------------------------------------------------------------------
SigPresLEDs = {SigPresence["signal.presence.1"], SigPresence["signal.presence.3"]}
SigPresFlags = {}

for idx,ctl in ipairs(SigPresLEDs) do
  table.insert(SigPresFlags, false)

  ctl.EventHandler = function(c)
    if not c.Boolean then 
      SigPresFlags[idx] = true
      print("-- FLAG "..idx.." - NO SIGNAL")
    end 
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Startup      --
----------------------------------------------------------------------------------------------------------------------------------------
Controls.Status.Value = 0

if Controls.FMPower.Boolean then 
  CheckTimer:Start(600)
  Controls.Status.String = "Starting FM Monitoring - Check in 10 Mins"
else
  CheckTimer:Stop()
  Controls.Status.String = "Outside of Transmit Hours"
end


Controls.FMPower.EventHandler = function()
  if Controls.FMPower.Boolean then 
    CheckTimer:Start(600)
    Controls.Status.String = "Starting FM Monitoring - Check in 10 Mins"
  else
    CheckTimer:Stop()
    Controls.Status.String = "Outside of Transmit Hours"
  end
end
