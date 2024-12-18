--[[
Pushover - Transmitter
Created by K. Rhodus
kevin@ldplights.com

Version History:
1.0 - Initial Build

]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Script Setup      --
----------------------------------------------------------------------------------------------------------------------------------------
json = require("rapidjson")

Controls.priority.Choices = {-2,-1,0,1,2}

Controls.sound.Choices = {"","pushover","bike","bugle","cashregister","classical","cosmic","falling","gamelan","incoming","intermission","magic","mechanical","pianobar","siren","spacealarm","tugboat","alien","climb","persistent","echo","updown","vibrate","none","custom"}

Controls.Status.Value = 0

-----------------------------------------------------------------------------------------------------------------------------------------
--      Register / Validate Device      --
----------------------------------------------------------------------------------------------------------------------------------------

Controls.Validate.EventHandler = function()
  local message = {}

  if Controls.device.String ~= "" then 
    message["device"]= Controls.device.String
  end

  if Controls.Token.String ~= "" then 
    message["token"]= Controls.Token.String
  else 
    Controls.Status.Value = 1
    Controls.Status.String = "Missing Application Token"
  end

  if Controls.UserAPI.String ~= "" then 
    message["user"]= Controls.UserAPI.String
  else 
    Controls.Status.Value = 1
    Controls.Status.String = "Missing User API Key"
  end

  print(json.encode(message))
  
  if #Controls.Token.String >1 and # Controls.UserAPI.String >1 then 
    HttpClient.Upload {
        Url = "https://api.pushover.net/1/users/validate.json",
        Method = "POST",
        Data = json.encode(message),
        Headers = {
          ["Content-Type"] = "application/json",
        },
        EventHandler = ValidateReturn -- The function to call upon response
      }
  end
end 

function ValidateReturn(tbl, code, d, e)
  print( string.format("Response Code: %i\t\tErrors: %s\rData: %s",code, e or "None", d))

  local response = json.decode(d)

  if response.status == 1 then
    Controls.ValidUser.Boolean = true
  else
    Controls.ValidUser.Boolean = false
  end

  Controls.AvailableDevices.String = table.concat(response.devices, ",")
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Send Message     --
-----------------------------------------------------------------------------------------------------------------------------------------
Controls.Send.EventHandler = function()
  local message = {}

  if Controls.device.String ~= "" then 
    message["device"]= Controls.device.String
  end

  if Controls.priority.String ~= "" then 
    message["priority"]= Controls.priority.String
  end

  if Controls.sound.String ~= "" then 
    if Controls.sound.String == "custom" then
      message["sound"]= Controls.customSoundName.String
    else
      message["sound"]= Controls.sound.String
    end
  end

  if Controls.title.String ~= "" then 
    message["title"]= Controls.title.String
  end

  if Controls.ttl.String ~= "" then 
    message["ttl"]= Controls.ttl.String
  end

  if Controls.url.String ~= "" then 
    message["url"]= Controls.url.String
  end

  if Controls.urlName.String ~= "" then 
    message["url_title"]= Controls.urlName.String
  end
  
  if Controls.message.String ~= "" then 
    message["message"]= Controls.message.String
  else 
    Controls.Status.Value = 1
    Controls.Status.String = "Message has no Body"
  end

  if Controls.Token.String ~= "" then 
    message["token"]= Controls.Token.String
  else 
    Controls.Status.Value = 1
    Controls.Status.String = "Missing Application Token"
  end

  if Controls.UserAPI.String ~= "" then 
    message["user"]= Controls.UserAPI.String
  else 
    Controls.Status.Value = 1
    Controls.Status.String = "Missing User API Key"
  end

  print(json.encode(message))
  
  if #Controls.Token.String >1 and # Controls.UserAPI.String >1 then 
    HttpClient.Upload {
        Url = "https://api.pushover.net/1/messages.json",
        Method = "POST",
        Data = json.encode(message),
        Headers = {
          ["Content-Type"] = "application/json",
        },
        EventHandler = MessageReturn -- The function to call upon response
      }
  end
end 

function MessageReturn(tbl, code, d, e)
  print( string.format("Response Code: %i\t\tErrors: %s\rData: %s",code, e or "None", d))
end
