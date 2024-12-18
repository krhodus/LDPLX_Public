--[[
ShowHours
Created by K. Rhodus
kevin@lightshownetwork.cpm

Version History:
1.0 - Initial Build

]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
json = require("rapidjson")
UpdateTime = "12:00"  --Move to control
BackupTime = "04:00"  --Move to control

-----------------------------------------------------------------------------------------------------------------------------------------
--      Helper Functions      --
----------------------------------------------------------------------------------------------------------------------------------------
function debugprint(str)
  --print(str)  --Uncomment to print debug statements
end

function convTime(timeString)
    local hour, min = timeString:match("(%d%d):(%d%d)")
    local time = (tonumber(hour)*60)+tonumber(min)
    return time
end
-----------------------------------------------------------------------------------------------------------------------------------------
--      Notification Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
function notRx (name, data)
  --print(name,json.encode(data))
  if data.Command == "Download" and data.Results.Filename == "SHOWHOURS.json" then 
    ShowSchedule = json.decode(data.Results.Content)
    if ShowSchedule ~= nil then 
      debugprint(json.encode(ShowSchedule, {pretty=true}))
      Evaluate()
      CheckTime:Start(60)
      Controls.Status.Value = 0
      Controls.Status.String = "Downloaded Schedule"
    else
      --Throw a falt
      debugprint("Error Downloading Schedule")
      Controls.Status.Value = 2
      Controls.Status.String = "Error Downloading Schedule"
    end
  end
end

ShowMonGit = Notifications.Subscribe("ShowMonGit", notRx) --Move Notification name to control

-----------------------------------------------------------------------------------------------------------------------------------------
--      Get Schedule      --
----------------------------------------------------------------------------------------------------------------------------------------
function GetSchedule()
  debugprint("Get Schedule")
  local temp = {
                  Command = "Pull",
                  Args = 
                    {
                      Filename = "SHOWHOURS.json"
                    }
                }
  Notifications.Publish("ShowMonGit", temp)
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Evaluate TOD vs Schedule      --
----------------------------------------------------------------------------------------------------------------------------------------
function Evaluate ()

  local time = os.date("%H:%M")
  local day = tonumber(os.date("%w"))+1

  local curTime = convTime(time)
  local startTime = convTime(ShowSchedule[day].StartShow)
  local ShowStop = convTime(ShowSchedule[day].ShowStop)
  local TXStop = convTime(ShowSchedule[day].TXStop)
  local AM_Off = convTime(ShowSchedule[day].AM_Off)
  local bkTime = convTime(BackupTime)
  local upTime = convTime(UpdateTime)

  
  if curTime < AM_Off then 
    debugprint("OVERNIGHT - NO FM")
    Controls.AfterHours.Boolean = true
    Controls.FM_Power.Boolean = false
    Controls.ShowHours.Boolean = false
    Controls.Status.String = "After Show - FM TX Off"
  elseif curTime >= startTime and curTime <= ShowStop then
    debugprint("ShowTime")
    Controls.AfterHours.Boolean = false
    Controls.FM_Power.Boolean = true
    Controls.ShowHours.Boolean = true
    Controls.Status.String = "ShowTime"
  elseif curTime > ShowStop and curTime <= TXStop then
    debugprint("FM TX After Show")
    Controls.AfterHours.Boolean = true
    Controls.FM_Power.Boolean = true
    Controls.ShowHours.Boolean = false
    Controls.Status.String = "After Show - FM TX On"
  elseif curTime > TXStop then 
    debugprint("NIGHT - NO FM")
    Controls.AfterHours.Boolean = true
    Controls.FM_Power.Boolean = false
    Controls.ShowHours.Boolean = false
    Controls.Status.String = "After Show - FM TX Off"
  else
    Controls.AfterHours.Boolean = false 
    Controls.FM_Power.Boolean = false
    Controls.ShowHours.Boolean = false
    Controls.Status.String = "Out of Show Hours"
  end

  if curTime == startTime then
    debugprint("TIME MATCH - startTime")
    Timer.CallAfter(function() Notifications.Publish("ShowHours", "SHOW START") end, .1)
    local temp = "LDPLX Daily Report for ".. os.date("%a %b %d").. "\n Show Starts at: "..ShowSchedule[day].StartShow.. "\n Show Stops at: "..ShowSchedule[day].ShowStop.."\n FM Transmitter turns off at: "..ShowSchedule[day].TXStop.."\n Lights turn off at:"..ShowSchedule[day].AM_Off
    Timer.CallAfter(function() Notifications.Publish("ShowAnnc", temp) end, .2)
    debugprint("Sending Show Announcement")
  elseif curTime == ShowStop then
    debugprint("TIME MATCH - ShowStop")
    Timer.CallAfter(function() Notifications.Publish("ShowHours", "AFTER SHOW") end, .1)
  elseif curTime == TXStop then 
    debugprint("TIME MATCH - TXStop")
    Timer.CallAfter(function() Notifications.Publish("ShowHours", "FM OFF") end, .1)
  elseif curTime == upTime then 
    debugprint("TIME MATCH - upTime")
    Timer.CallAfter(function() GetSchedule() end, .1)
  end

  --[[    --Uncomment once Memory Leak is Discovered
  if curTime == bkTime then
    --Notifications.Publish("FPPNotify", "Backup")
    --print("Backing Up Players")
  end
  --]]

  --Time Debug Printing
  debugprint("SHOW TIME CALC")
  debugprint("   -Current Time: "..time .. " - ".. curTime)
  debugprint("   -Start Time: "..ShowSchedule[day].StartShow .. " - ".. startTime)
  debugprint("   -Stop Time: "..ShowSchedule[day].ShowStop .. " - ".. ShowStop)
  debugprint("   -TX Stop Time: "..ShowSchedule[day].TXStop .. " - ".. TXStop)
  debugprint("   -AM Off Time: "..ShowSchedule[day].AM_Off .. " - ".. AM_Off)

end
-----------------------------------------------------------------------------------------------------------------------------------------
--      Update Timer      --
----------------------------------------------------------------------------------------------------------------------------------------

CheckTime = Timer.New()
CheckTime.EventHandler = Evaluate

-----------------------------------------------------------------------------------------------------------------------------------------
--      Startup Functions      --
----------------------------------------------------------------------------------------------------------------------------------------
GetSchedule()
