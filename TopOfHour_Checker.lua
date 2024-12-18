--[[
Top Of Show Hour Pulse
Created by K. Rhodus
kevin@lightshownetwork.cpm

Version History:
1.0 - Initial Build


NOTE: This whole script can go away and get integrated into ShowHours
]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------



CheckTime = Timer.New()

CheckTime.EventHandler = function()
  local min =  os.date("%M")
  if min == "01" then
    print("Top of Hour -- " .. os.date("%H"))
    if tonumber(os.date("%H")) > 16 then
      print("Show Hour")
      if Controls.Enable.Boolean then
        print("Sending Message")
        Controls.Send:Trigger()
      end
    end 
  end
end


CheckTime:Start(60)
