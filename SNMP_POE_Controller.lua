--[[
POE Rebooter with PIN Inputs
Created by K. Rhodus
kevin@lightshownetwork.com

Version History:
1.0 - Initial Build

!!Need to add logic to change OID based on model reported back - currently two slightly different versions
of the script exist for v2 and v3
]]--

json = require("rapidjson")

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
--SNMP Session
snmp_session = SNMPSession.New(SNMP.SessionType.v2c)

snmp_session:setHostName(Controls.IPAddress.String)

snmp_session:setCommunity(Controls.Community.String)

snmp_session.ErrorHandler = function(response)
  print(response.Error)
end


--Initalize Controls

Controls.systemDescription.String = ""
Controls.systemUpTime.String = ""
Controls.SystemLocation.String = ""
Controls.SystemName.String = ""

for idx,ctl in ipairs(Controls.POE_Enable) do
  ctl.Boolean = false
end

for idx,ctl in ipairs(Controls.PortStatus) do
  ctl.Boolean = false
end

for idx,ctl in ipairs(Controls.PortUptime) do
  ctl.String = ""
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      OID Setup      --
----------------------------------------------------------------------------------------------------------------------------------------

--Switch Status OIDs
OIDs = {
  ["iso.3.6.1.2.1.1.1.0"] = {Name = "systemDescription", Control = Controls.systemDescription, Type = "String"},
  ["iso.3.6.1.2.1.1.3.0"] = {Name = "systemUptime", Control = Controls.systemUpTime, Type = "String", Status = "Yes"},
  ["iso.3.6.1.2.1.1.5.0"] = {Name = "systemName", Control = Controls.SystemName, Type = "String"},
  ["iso.3.6.1.2.1.1.6.0"] = {Name = "systemLocation", Control = Controls.SystemLocation, Type = "String"}
}

--Build Port OIDs
for i = 1,#Controls.PortStatus do
  OIDs["iso.3.6.1.2.1.2.2.1.8."..i]={Name = "Port "..i.." Status", Control = Controls.PortStatus[i], Type = "String"}
  OIDs["iso.3.6.1.2.1.2.2.1.9."..i]={Name = "Port "..i.." Uptime", Control = Controls.PortUptime[i], Type = "String"}
  OIDs["iso.3.6.1.4.1.4526.11.16.1.1.1.3.1."..i]= {Name = "Port "..i.." POE Enabled", Control = Controls.POE_Enable[i], Type = "Boolean"}
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Switch Status Monioting      --
----------------------------------------------------------------------------------------------------------------------------------------
--Get All OID Status
function GetSwitchStatus()
  for i,v in pairs(OIDs) do
    snmp_session:getRequest(i, SwitchStatusCallBack)
  end
end

--OID Callback Function
function SwitchStatusCallBack(dataout)
  --print("------ NEW RESPONSE --------")
  --print(OIDs[dataout.OID].Name)
  --print("OID: "..dataout.OID)
  --print("VALUE: "..dataout.Value)
  if OIDs[dataout.OID].Type == "String" then
    OIDs[dataout.OID].Control.String = dataout.Value
  elseif OIDs[dataout.OID].Type == "Boolean" then
    OIDs[dataout.OID].Control.Boolean = dataout.Value == "1"
  end
  if OIDs[dataout.OID].Status == "Yes" then
    Controls.Status.Value = 0
    Controls.Status.String = "Uptime: "..dataout.Value
  end
end

--Polling Timer
SwitchStatusPoll = Timer.New()
SwitchStatusPoll.EventHandler = GetSwitchStatus
SwitchStatusPoll:Start(30)


-----------------------------------------------------------------------------------------------------------------------------------------
--      POE Control      --
----------------------------------------------------------------------------------------------------------------------------------------

--Manual Control
for idx,ctl in ipairs(Controls.POE_Enable) do
  ctl.EventHandler = function()
    for i,v in pairs(OIDs) do
      if v.Control == ctl then
        if ctl.Boolean then
          snmp_session:setRequest(i, 1 , SNMP.SNMPDataType.integer32, SwitchStatusCallBack)
        else
          snmp_session:setRequest(i, 2 , SNMP.SNMPDataType.integer32, SwitchStatusCallBack)
        end
      end 
    end 
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      AutoControl      --
----------------------------------------------------------------------------------------------------------------------------------------

--Setup Tables / Discover Components
StatusTimer = {}

--Enable/Disable Logic
for idx,ctl in ipairs(Controls.AutoControl) do
  Controls.AssociatedDeviceStatus[idx].IsDisabled = not ctl.Boolean

  ctl.EventHandler = function()
    Controls.AssociatedDeviceStatus[idx].IsDisabled = not ctl.Boolean
  end
end

--Build EventHandler / Timer Logic

for idx,ctl in ipairs(Controls.AssociatedDeviceStatus) do
  StatusTimer[idx] = Timer.New()    --Build new timer for it

  StatusTimer[idx].EventHandler = function()    --Build tiemr EH
    StatusTimer[idx]:Stop()
    if Controls.AutoControl[idx].Boolean then --Check if AutoControl is Enabled
      if ctl.Value == 2 or ctl.Value == 4 then
        for i,v in pairs(OIDs) do       --Search OID table for corect OID
          if v.Control == Controls.POE_Enable[idx] then   --find match OID then..
            Controls.Status.Value = 1
            Controls.Status.String = "Rebooting Port ".. idx
            snmp_session:setRequest(i, 2 , SNMP.SNMPDataType.integer32, SwitchStatusCallBack)   --flip off port
            Controls.POE_Enable[idx].Boolean = false
            Timer.CallAfter(
              function()
                snmp_session:setRequest(i, 1 , SNMP.SNMPDataType.integer32, SwitchStatusCallBack)   --flip back on port after 10s
                Controls.POE_Enable[idx].Boolean = true
              end, 10)
          end
        end
      end
    end 
  end 

  ctl.EventHandler = function()
    if ctl.Value == 2 or ctl.Value == 4 then
      StatusTimer[idx]:Start(Controls.TimerTime.Value)
    elseif ctl.Value == 0 or ctl.Value == 5 then
      StatusTimer[idx]:Stop()
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Startup Functions     --
-----------------------------------------------------------------------------------------------------------------------------------------
snmp_session:startSession()

Controls.IPAddress.EventHandler = function()
  snmp_session:startSession()
end


GetSwitchStatus()
