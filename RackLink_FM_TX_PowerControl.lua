--[[
FM Transmitter Power Control
Created by K. Rhodus
kevin@lightshownetwork.cpm

Version History:
1.0 - Initial Build

]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
--Named Component
rlink = Component.New(Controls.RackLinkName.String)

Controls.RackLinkName.EventHandler = function()
  rlink = Component.New(Controls.RackLinkName.String)
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Power Mode Evaluation      --
----------------------------------------------------------------------------------------------------------------------------------------
Eval = function()
  if Controls.ShowHours.Boolean then 
    if btns[1].Boolean then 
      print("Powering On Primary TX")
      rlink["OutletPowerOn 1"]:Trigger()
      rlink["OutletPowerOff 2"]:Trigger()
    elseif btns[2].Boolean then
      print("Powering On Secondary TX")
      rlink["OutletPowerOn 2"]:Trigger()
      rlink["OutletPowerOff 1"]:Trigger()
    end
  else
    rlink["OutletPowerOff 1"]:Trigger()
    rlink["OutletPowerOff 2"]:Trigger()
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Manual Buttons      --
----------------------------------------------------------------------------------------------------------------------------------------
btns = {Controls.Primary, Controls.Secondary}

for idx,ctl in ipairs(btns) do
  ctl.EventHandler = function()
    for i,v in ipairs(btns) do
      v.Boolean = i==idx
    end
   Eval()
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Eval on ShowHours      --
----------------------------------------------------------------------------------------------------------------------------------------
Controls.ShowHours.EventHandler = Eval  --rename control to FMPower based on new naming logic
