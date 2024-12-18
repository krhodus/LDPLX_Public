--[[
Camlytics API
Created by K. Rhodus
kevin@lightshownetwork.com

Version History:
1.0 - Initial Build

]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
json = require("rapidjson")
--Helper Functions

-----------------------------------------------------------------------------------------------------------------------------------------
--      HTTP Call      --
----------------------------------------------------------------------------------------------------------------------------------------
function done(tbl, code, data, err, headers)
  --print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ))
  --print( "\rHTML Data: "..data )
  if code == 200 then 
    local temp = json.decode(data)

    for idx, ctl in ipairs(temp.report.data.series) do
      if ctl.name == "Cars Detected" then
        CarsDetected = ctl.data[1].value
        HistoricalData[ctl.data[1].key] = CarsDetected
        UpdateHistoricalData()
        CalcTotal()
      elseif ctl.name == "Cars Tailgaiting" then
        CarsTailgating = ctl.data[1].value
      end
    end

    Controls.CarCount.String = CarsDetected
    Controls.UCIDisplay.String = os.date("%H:%M").. " - " ..CarsDetected
    Controls.Status.Value = 0
    Controls.Status.String = os.date("%H:%M").. " - " ..CarsDetected
  else
    Controls.Status.Value = 1
    print(string.format( "HTTP response from '%s': Return Code=%i; Error=%s", tbl.Url, code, err or "None" ))
    print( "\rHTML Data: "..data )
  end
end

function Download()
  HttpClient.Download { Url = Controls.URL.String, Headers = { ["Content-Type"] = "application/json" } , Timeout = 30, EventHandler = done }
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Total Count Logic     --
-----------------------------------------------------------------------------------------------------------------------------------------
HistoricalData = {}


function LoadHistorical()
  if Controls.DataStorage.String ~= "" then
    HistoricalData = json.decode(Controls.DataStorage.String)
    CalcTotal()
  end
end

function CalcTotal()
  TotalCars = 0
  for idx,ctl in pairs(HistoricalData) do
    TotalCars = TotalCars + ctl
  end
  Controls.TotalSeasonCount.String = TotalCars
end

function UpdateHistoricalData ()
  Controls.DataStorage.String = json.encode(HistoricalData)
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Timer     --
-----------------------------------------------------------------------------------------------------------------------------------------

updateTimer = Timer.New()

updateTimer.EventHandler = function()           --Rework to integrate with ShowHours
  local min =  string.sub(os.date("%M"), -1,-1)
  if min == "0" or min == "5" then
    if tonumber(os.date("%H")) >= 16 then
      Download()
    end
  end
end



-----------------------------------------------------------------------------------------------------------------------------------------
--    Script Start       --
-----------------------------------------------------------------------------------------------------------------------------------------
LoadHistorical()
Download()
updateTimer:Start(60)

