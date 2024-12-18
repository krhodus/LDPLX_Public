--[[
Falcon Pi Player Monitor
Created by K. Rhodus
kevin@lightshownetwork.com

Version History:
1.0 - Initial Build


]]--

-----------------------------------------------------------------------------------------------------------------------------------------
--      Setup Script      --
----------------------------------------------------------------------------------------------------------------------------------------

json = require("rapidjson")

--Tables 
StatusState = { OK = 0, COMPROMISED = 1, FAULT = 2, NOTPRESENT = 3, MISSING = 4, INITIALIZING = 5 }
fppdstatus = {}
multisync = {}
Modes = {player = 6, remote = 8}
Controls.SetMode.Choices = {"player", "remote"}
playlists = {}


--Timers
Tick = Timer.New()
RebootTimeout = false



-----------------------------------------------------------------------------------------------------------------------------------------
--      Universal Tools     --
-----------------------------------------------------------------------------------------------------------------------------------------

function univHTTPEventHandler(tbl, code, d, e)
  if code == nil then code = "0" end
  print( string.format("Response Code: %i\t\tErrors: %s\rData: %s",code, e or "None", d))
end

function rebootFPPD()
  print ("Rebooting FPPD")
  HttpClient.Download { Url = Controls.IPAddress.String.."/api/system/fppd/restart", Timeout = 30, EventHandler = univHTTPEventHandler }
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Download Player Info     --
-----------------------------------------------------------------------------------------------------------------------------------------

--FPPD Status
function downloadfppdftn(tbl, code, data, err, headers)
  if code == 200 then    --Proper HTTP response
    Tick:Start(30)
    Controls.Status.Value = 0   --Set Status value
    BadResponse = 0
    local fppdstatus = json.decode(data)
    --
    print(json.encode(fppdstatus, {pretty = true}))
    
    if fppdstatus.fppd == "Not Running" then 
      Controls.FPPDRunning.Boolean = false
      Controls.FPPDRunning.Color = "#80FF0000"
      if not FPPDTimer:IsRunning() then
        FPPDTimer:Start(120)
        Controls.Status.String = "FPPD Not Running - Countdown Timer Started"
      end
    else
      FPPDTimer:Stop()
      --Mode/FPPD Status
      Controls.Mode.String = fppdstatus.mode_name
      Controls.SetMode.String = fppdstatus.mode_name
      Controls.FPPstatus.String = fppdstatus.status_name
      Controls.FPPDRunning.Boolean = fppdstatus.fppd == "running"
      Controls.FPPDRunning.Color = "#4080FF00"
      --Currently Playing Section
      Controls.Status.String = fppdstatus.mode_name .." "..fppdstatus.status_name
      Controls.MediaName.String = fppdstatus.current_song
      Controls.SequenceName.String = fppdstatus.current_sequence
      --Controls.Time.Position = fppdstatus.seconds_played / (fppdstatus.seconds_played + fppdstatus.seconds_remaining)
      Controls.ElapsedTime.String = fppdstatus.time_elapsed
      --Sechedule Section
      if fppdstatus.mode_name == "player" then
        downloadplaylists()
        Controls.CurrentPlaylist.String = fppdstatus.current_playlist.playlist
        Controls.Playlists.String = fppdstatus.current_playlist.playlist
        if fppdstatus.scheduler.status ~= "idle" and fppdstatus.scheduler.status ~= "manual" then       --- More testing for Playlist Scheduling testing needed
          Controls.ScheduledStartTime.String = fppdstatus.scheduler.currentPlaylist.scheduledStartTimeStr
          Controls.ActualStartTime.String = fppdstatus.scheduler.currentPlaylist.actualStartTimeStr
          Controls.CurrentStopTime.String = fppdstatus.scheduler.currentPlaylist.actualEndTimeStr
          Controls.NextPlaylist.String = fppdstatus.scheduler.nextPlaylist.playlistName
          Controls.NextStartTime.String = fppdstatus.scheduler.nextPlaylist.scheduledStartTimeStr
        else
          Controls.ScheduledStartTime.String = ""
          Controls.ActualStartTime.String = ""
          Controls.CurrentStopTime.String = ""
          Controls.NextPlaylist.String = ""
          Controls.NextStartTime.String = ""
        end
      
       --]]
      end
      
      --MultiSync Feedback
      Controls.SendMultiSync.Boolean = fppdstatus.multisync 
      --Volume Feedback
      Controls.Volume.Value = fppdstatus.volume
      
      --Player Information
      Controls.FPP_Version.String = fppdstatus.advancedView.Version
      Controls.FPP_Hostname.String = fppdstatus.advancedView.HostName
      Controls.FPP_Description.String = fppdstatus.advancedView.HostDescription
      Controls.FPP_OSVersion.String = fppdstatus.advancedView.OSVersion
      Controls.FPP_GitVersion.String = fppdstatus.advancedView.LocalGitVersion
      Controls.FPP_HostType.String = fppdstatus.advancedView.Variant
      Controls.FPP_Memory.Position = fppdstatus.advancedView.Utilization.Memory / 100
      Controls.FPP_RootDisk.Position = fppdstatus.advancedView.Utilization.Disk.Root.Free / fppdstatus.advancedView.Utilization.Disk.Root.Total
      Controls.FPP_MediaDisk.Position = fppdstatus.advancedView.Utilization.Disk.Media.Free / fppdstatus.advancedView.Utilization.Disk.Media.Total
      Controls.UpgradeAvailable.Boolean = fppdstatus.advancedView.LocalGitVersion ~= fppdstatus.advancedView.RemoteGitVersion
      Controls.Upgrade.IsDisabled = fppdstatus.advancedView.LocalGitVersion == fppdstatus.advancedView.RemoteGitVersion
      
    end
      --End of Status Parsing
  else
    BadResponse = BadResponse + 1
    Controls.Status.String = "No/Bad Response - Starting Countdown"
    
    if BadResponse >= 3 then  
      if RebootTimeout == false then 
        Controls.Status.Value = 6   --Set Status value
        Controls.FPPDRunning.Boolean = false
        Controls.FPPDRunning.Color = "#80FF0000"
        Tick:Start(120)
      end
    end
  end
end


function downloadfppd()
  --print ("Downloading FPPD Status from: " .. address)
  HttpClient.Download { Url = Controls.IPAddress.String.. "/api/system/status", Timeout = 360, EventHandler = downloadfppdftn }
end


pollplayer = function()
  if #Controls.IPAddress.String>0 then
    downloadfppd()
  end
end

Tick.EventHandler = pollplayer

Controls.IPAddress.EventHandler = pollplayer

FPPDTimer = Timer.New()

FPPDTimer.EventHandler = function()
  FPPDTimer:Stop()
  Controls.Status.Value = 2
  Controls.Status.String = "FPPD Not Running"
end

BadResponse = 0
-----------------------------------------------------------------------------------------------------------------------------------------
--      Set Test Mode     --
-----------------------------------------------------------------------------------------------------------------------------------------

--TestMode Values Table
testmodetbl={
  channelSet="1-8388608",
  channelSetType="channelRange",
  colorPattern="FF000000FF000000FF",
  cycleMS=1000,
  enabled=1,
  mode="RGBCycle",
  subMode="RGBCycle-RGBA"
}

testcolor = {mode="RGBFill",
  color1=Controls.TestColor[1].Value,
  color2=Controls.TestColor[2].Value,
  color3=Controls.TestColor[3].Value,
  enabled=1,
  channelSet="1-8388608",
  channelSetType="channelRange"
 }

function testupload(data)
  HttpClient.Upload {
    Url = Controls.IPAddress.String.."/api/testmode",
    Method = "POST", 
    Data = json.encode(data),
    Headers = {
      ["Content-Type"] = "application/json",
    },
    EventHandler = univHTTPEventHandler -- The function to call upon response
  }
end

Controls.TestMode.EventHandler = function(ctl)
  testmodetbl.enabled = ctl.Value
  testupload(testmodetbl)
end
  
  
for idx,ctl in ipairs(Controls.TestColor) do
  ctl.EventHandler = function()
    testcolor["color"..idx] = ctl.Value
    testupload(testcolor)
    Controls.TestMode.Boolean= true
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Player Mode *NEEDS UPDATED**    --
----------------------------------------------------------------------------------------------------------------------------------------

Controls.SetMode.EventHandler = function(mode)
  local setmode = 0
  for idx,ctl in pairs(Modes) do
    if idx == mode.String then
      setmode = ctl
      print(temp)
      break
    end
  end
  
  RebootTimeout = true
  url = Controls.IPAddress.String.."/fppxml.php?command=setFPPDmode&mode="..setmode
  playermodeupload(url)
  rebootFPPD()
  Timer.CallAfter(function() RebootTimeout = false end, 10)
end

function playermodeupload(url)
  HttpClient.Upload {
    Url = url,
    Method = "POST", 
    Data = "",
    Headers = {
      ["Content-Type"] = "application/json",
    },
    EventHandler = univHTTPEventHandler
  }
end


-----------------------------------------------------------------------------------------------------------------------------------------
--      Playlist Functions     --
----------------------------------------------------------------------------------------------------------------------------------------

--Get Playlists
function downloadplaylistsftn(tbl, code, data, err, headers)
  if code == 200 then
    playlists = json.decode(data)
    Controls.Playlists.Choices = playlists
    Controls.NotificationPlaylist.Choices = playlists
    --print(json.encode(playlists, {pretty = true}))
  end
end

function downloadplaylists()
  HttpClient.Download { Url = "http://"..Controls.IPAddress.String.. "/api/playlists", Timeout = 30, EventHandler = downloadplaylistsftn }
end


Controls.Play.EventHandler = function()
  local temp = {
                command= "Start Playlist At Item",
                args = {Controls.Playlists.String, 0,true,false}
              }
  
  HttpClient.Upload {
    Url = Controls.IPAddress.String.."/api/command",
    Method = "POST", 
    Data = json.encode(temp),
    Headers = {
      ["Content-Type"] = "application/json"
    },
    EventHandler = univHTTPEventHandler
  }
  
end


Controls.Stop.EventHandler = function()
  HttpClient.Download { Url = "http://"..Controls.IPAddress.String.. "/api/playlists/stop", Timeout = 30, EventHandler = univHTTPEventHandler }
end

-----------------------------------------------------------------------------------------------------------------------------------------
--      MultiSync Enabled     --
----------------------------------------------------------------------------------------------------------------------------------------

Controls.SendMultiSync.EventHandler = function(ctl)
  HttpClient.Upload {
    Url = Controls.IPAddress.String.."/api/settings/MultiSyncEnabled/",
    Method = "PUT", 
    Data = ctl.Value,
    Headers = {
      ["Content-Type"] = "application/json"
    },
    EventHandler = univHTTPEventHandler
  }
    HttpClient.Download { Url = "http://"..Controls.IPAddress.String.. "/api/system/fppd/restart?quick=1", Timeout = 30, EventHandler = univHTTPEventHandler }

end

-----------------------------------------------------------------------------------------------------------------------------------------
--      Volume     --
----------------------------------------------------------------------------------------------------------------------------------------

Controls.Volume.EventHandler = function(ctl)
  local temp = {volume= ctl.Value}
  
  HttpClient.Upload {
    Url = Controls.IPAddress.String.."/api/system/volume/",
    Method = "POST", 
    Data = json.encode(temp),
    Headers = {
      ["Content-Type"] = "application/json"
    },
    EventHandler = univHTTPEventHandler
  }
end


-----------------------------------------------------------------------------------------------------------------------------------------
--      Backup Controller     --
----------------------------------------------------------------------------------------------------------------------------------------
function Backup() 
  HttpClient.Upload {
    Url = Controls.IPAddress.String.."/api/backups/configuration",
    Method = "POST", 
    Data = "Q-SYS Automated Backup - "..os.date("%Y-%m-%d %H:%M:%S"),
    Headers = {
      ["Content-Type"] = "application/json"
    },
    EventHandler = BackupEH
  }
end

function BackupEH(tbl, code, d, e)
  if code == nil then code = "0" end
  --print( string.format("Response Code: %i\t\tErrors: %s\rData: %s",code, e or "None", d))
  print(d)

  local temp = json.decode(d)

  if temp ~= nil then 
    if temp.success == true then 
      path = string.sub(temp.backup_file_path, 32, -1)
      print(path)
      HttpClient.Download { Url = "http://"..Controls.IPAddress.String.. "/api/backups/configuration/JsonBackups/"..path, Timeout = 30, EventHandler = DLBackupEH }
    end
  end
end

function DLBackupEH(tbl, code, d, e)
  if code == nil then code = "0" end
  --print( string.format("Response Code: %i\t\tErrors: %s\rData: %s",code, e or "None", d))
  print(d)

  local temp = {
    Command = "Commit",
    Args = {
      Filename = Controls.FPP_Hostname.String,
      CommitMsg = "Q-SYS Automated Backup - "..os.date("%Y-%m-%d %H:%M:%S"),
      Content = d
    }
  }

  Timer.CallAfter(function() Notifications.Publish("ShowMonGit", temp) end, #Controls.IPAddress.String*math.random(10))
  
end

Controls.BackupController.EventHandler = Backup

function GitNotEH (name, data)
  print(json.encode(data))
  if data.Command == "Commit" and data.Results ~= nil then
    if data.Results.Filename == Controls.FPP_Hostname.String then
      Controls.LastBackupDate.String = data.Results.Code
    end
  end
end

--GitNotification = Notifications.Subscribe("ShowMonGit", GitNotEH)

-----------------------------------------------------------------------------------------------------------------------------------------
--      FPP Update     --
----------------------------------------------------------------------------------------------------------------------------------------

Controls.Upgrade.EventHandler = function()
  Controls.Upgrade.IsDisabled = true
  HttpClient.Download { Url = "http://"..Controls.IPAddress.String.. "/manualUpdate.php", Timeout = 30, EventHandler = univHTTPEventHandler }
end


-----------------------------------------------------------------------------------------------------------------------------------------
--      Notifications      --
----------------------------------------------------------------------------------------------------------------------------------------

function IncomingNotification (name, data)
  print("**Incoming Notification- "..name.." - "..data.." **")
  if data == "Test On" then
    Controls.TestMode.Boolean = true
    testmodetbl.enabled = 1
    testupload(testmodetbl)
  elseif data == "Test Off" then
    Controls.TestMode.Boolean = false
    testmodetbl.enabled = 0
    testupload() 
  elseif data == "Show Start" then
    if Controls.Mode.String == "player" then
      local temp = {command= "Start Playlist At Item",args = {Controls.NotificationPlaylist.String, 0,true,false}}
      HttpClient.Upload {Url = Controls.IPAddress.String.."/api/command",Method = "POST", Data = json.encode(temp),Headers = {["Content-Type"] = "application/json"},EventHandler = univHTTPEventHandler}
    end
  elseif data == "Show Stop" then
    if Controls.Mode.String == "player" then
      HttpClient.Download { Url = "http://"..Controls.IPAddress.String.. "/api/playlists/stop", Timeout = 30, EventHandler = univHTTPEventHandler }
    end
  elseif data == "Reset Mode" then
    RebootTimeout = true 
    if Controls.SendMultiSync.Boolean then
      playermodeupload(Controls.IPAddress.String.."/fppxml.php?command=setFPPDmode&mode=6")
    else
      playermodeupload(Controls.IPAddress.String.."/fppxml.php?command=setFPPDmode&mode=8")
    end
    rebootFPPD()
    Timer.CallAfter(function() RebootTimeout = false end, 10)
  elseif data == "Brightness Low" then
    --Future Brightness Control
  elseif data == "Update" then
    HttpClient.Download { Url = "http://"..Controls.IPAddress.String.. "/manualUpdate.php", Timeout = 30, EventHandler = univHTTPEventHandler }
  elseif data == "Backup" then 
    Backup()
  end
end

FPPNotify = Notifications.Subscribe("FPPNotify", IncomingNotification)


-----------------------------------------------------------------------------------------------------------------------------------------
--      Startup Functions     --
----------------------------------------------------------------------------------------------------------------------------------------

pollplayer()
