--[[
Energy Consumption Calculator
Created by K. Rhodus
kevin@lightshownetwork.cpm

Version History:
1.0 - Initial Build

]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
json = require("rapidjson")


-----------------------------------------------------------------------------------------------------------------------------------------
--      Get Energy Rates      --
----------------------------------------------------------------------------------------------------------------------------------------
function done(tbl, code, data, err, headers)
  --print(code)
  --print(data)
  if code == 200 then 
    local temp = json.decode(data)
    --print(json.encode(temp, {pretty=true}))
    Controls.PowerRate.String = temp.outputs.residential
    UpdatePowerConsumption()
  end
end

HttpClient.Download { Url = "https://developer.nrel.gov/api/utility_rates/v3.json?api_key="..Controls.APIKey.String.."&lat="..Controls.Latitude.String.."&lon="..Controls.Longitude.String, Headers = { ["Content-Type"] = "application/json" } , Timeout = 30, EventHandler = done }

--Maybe build in a timer if rates really change that much


-----------------------------------------------------------------------------------------------------------------------------------------
--      Calculate Total Consumption      --
----------------------------------------------------------------------------------------------------------------------------------------
function UpdatePowerConsumption()
  local totalConsumption = 0
  for idx,ctl in ipairs(Controls.powerInput) do
    if ctl.String ~= "" then 
      totalConsumption = tonumber(ctl.String) + totalConsumption
    end
  end

  Controls.TotalConsumption.String = totalConsumption
  if Controls.PowerRate.String ~= "" then 
    TotalCost = totalConsumption * tonumber(Controls.PowerRate.String)
    Controls.TotalCost.String = string.format("$%.2f", TotalCost)
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Build EventHandlers      --
----------------------------------------------------------------------------------------------------------------------------------------
for idx,ctl in ipairs(Controls.powerInput) do
  ctl.EventHandler = UpdatePowerConsumption
end
