--[[
FPP Player Failover
Created by K. Rhodus
kevin@lightshownetwork.cpm

Version History:
1.0 - Initial Build

]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
Lockout = false
Players = {Component.New("Prod-Pri"), Component.New("Prod-Sec")}  --Move to Controls

-----------------------------------------------------------------------------------------------------------------------------------------
--      Failover Timer      --
----------------------------------------------------------------------------------------------------------------------------------------
FailOver = Timer.New()

FailOver.EventHandler = function()
  FailOver:Stop()
  Lockout = false
  print("PRIMARY FAILURE - Starting Secondary")
  Players[1].SendMultiSync.Boolean = false
  Players[2].SendMultiSync.Boolean = true 
  Controls.Player[1].Boolean = false 
  Controls.Player[2].Boolean = true
  Timer.CallAfter(function() Players[2].Volume.Value = 89 end, 20)
  Timer.CallAfter(function() Players[2].Volume.Value = 90 end, 21)
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Manual Select Buttons      --
----------------------------------------------------------------------------------------------------------------------------------------
for idx,ctl in ipairs(Controls.Player) do
  ctl.EventHandler = function()
    for i,v in ipairs(Controls.Player) do
      v.Boolean = i==idx
      Players[i].SendMultiSync.Boolean = i==idx

      if v.Boolean then 
        Timer.CallAfter(function() Players[i].Volume.Value = 89 end, 20)  --Reset player volume as they drift over time but don't report back in API
        Timer.CallAfter(function() Players[i].Volume.Value = 90 end, 21)
      end
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Player 1 Status Monitoring      --
----------------------------------------------------------------------------------------------------------------------------------------
Players[1].Status.EventHandler = function(ctl)
  if Lockout == false and Controls.FailoverEnable.Boolean then 
    if Controls.AfterHours.Boolean or Controls.ShowHours.Boolean then 
      if Controls.Player[1].Boolean then 
        if ctl.String ~= "OK - player playing" then
          print("Primary Player Not Playing - Starting 30s Countdown")
          FailOver:Start(60)
          Lockout = true
        else 
          FailOver:Stop()
        end
      else 
        FailOver:Stop()
      end
      else
        FailOver:Stop()
    end
  else
    FailOver:Stop()
  end
end
