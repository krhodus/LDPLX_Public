--[[
UNMS Proxy Monitor
Created by K. Rhodus
kevin@lightshownetwork.com

Version History:
1.0 - Initial Build

]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Setup Script     --
----------------------------------------------------------------------------------------------------------------------------------------

json = require("rapidjson")

UNMSdata = {}
devices = {}


tick = Timer.New()

tick.EventHandler = function()
  UNMS()
end

--[[ Nevermind, Monitoring Proxies can't work without a status pin :(

Components = {}

--Find Monitoring Proxies

for _,ctl in pairs(Component.GetComponents()) do
  for a,b in pairs(ctl) do
    if a =="Type" then
      if b=="monitoring_proxy" then
        table.insert(Components,ctl.Name)
      end
    end
  end
end
for _,ctl in ipairs(Controls.Proxy) do
  ctl.Choices = Components
end
--]]

-----------------------------------------------------------------------------------------------------------------------------------------
--      Download from UNMS    --
-----------------------------------------------------------------------------------------------------------------------------------------

--Multisync Status
function UNMSftn(tbl, code, data, err, headers)
  if code == 200 then
  
  tick:Start(30)
  
  UNMSdata = json.decode(data)
  --print(json.encode(UNMSdata, {pretty = true}))
  
  devices = {}      --Build devices table
  for idx,ctl in ipairs(UNMSdata) do     
    table.insert(devices, ctl.identification.displayName)
  end
  table.sort(devices)

  for idx,ctl in ipairs(Controls.Device) do
    ctl.Choices = devices
  end
  
  update()
  end
end

function UNMS()
  local address = (Controls.IPAddress.String.. "/nms/api/v2.1/devices")
  print("Downloading UNMS Data from: " .. address)
  HttpClient.Download { Url = address, Headers = { ["Content-Type"] = "application/json" , ["x-auth-token"] = Controls.token.String} , Timeout = 30, EventHandler = UNMSftn }
end


UNMS()



-----------------------------------------------------------------------------------------------------------------------------------------
--      Update Devices    --
-----------------------------------------------------------------------------------------------------------------------------------------


update = function()

  for idx,ctl in ipairs(Controls.Device) do
  
    for i,v in ipairs(UNMSdata) do
      if v.identification.displayName == ctl.String then
        if v.overview.status == "active" then
          Controls.Status[idx].Value = 0
            if  type(v.overview.signal) == "function"  then
              Controls.Status[idx].String = ""
            else
                signal = tostring("Signal: "..v.overview.signal) .. " db"
                if type(v.overview.uplinkCapacity) ~= "function" then 
                  uplink = tostring("Up: "..math.floor(v.overview.uplinkCapacity * 0.000001).. "Mb")
                else 
                  uplink = ""
                end
                if type(v.overview.downlinkCapacity) ~= "function" then 
                  downlink = tostring("Down: "..math.floor(v.overview.downlinkCapacity * 0.000001).. "Mb")
                else
                  downlink = ""
                end
              Controls.Status[idx].String = signal.. " - "..uplink.." - "..downlink
            end

        else
          Controls.Status[idx].Value = 6
        end
      break
      end
    end
  end
end


-----------------------------------------------------------------------------------------------------------------------------------------
--      Associate Devices    --
-----------------------------------------------------------------------------------------------------------------------------------------


for idx, ctl in ipairs(Controls.Device) do
  ctl.EventHandler = function()
    update()
  end
end







