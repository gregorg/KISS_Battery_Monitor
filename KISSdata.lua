local versionInfo = "KISS Telemetry Data - v1.3.1"
local settingsFile = '/SCRIPTS/TELEMETRY/KISSuser.dat'

local blnMenuMode = 0
local intMenu = 0 -- used for menu screens

-- mahTarget is used to set our target mah consumption and mahAlertPerc is used for division of alerts
local mahTarget = 900
local mahAlertPerc = 10

local userData = {}
    userData.mahTarget = 0


-- OpenTX 2.0 - Percent Unit = 8 // OpenTx 2.1 - Percent Unit = 13
-- see: https://opentx.gitbooks.io/opentx-lua-reference-guide/content/general/playNumber.html
local percentUnit = 13

local lastMahAlert = 0


----------------------------------------------------------------
-- Custom Functions
----------------------------------------------------------------
local function getTelemetryId(name)
 field = getFieldInfo(name)
 if getFieldInfo(name) then return field.id end
  return -1
end

local data = {}
  data.fuelUsed = getTelemetryId("Fuel")


-------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------
-- Rounding Function
local function round(val, decimal)
    local exp = decimal and 10^decimal or 1
    return math.ceil(val * exp - 0.5) / exp
end

--MahAlert and Logging of last Value Played
local function playMahPerc(percVal)
  playNumber(percVal,percentUnit)
  lastMahAlert = percVal  -- Set our lastMahAlert
end

local function playCritical(percVal)
  playFile("batcrit.wav")
  lastMahAlert = percVal  -- Set our lastMahAlert
end





local function playAlerts()

    percVal = 0
    curMah = getValue(data.fuelUsed)

    if curMah ~= 0 then
      percVal =  round(((curMah/mahTarget) * 100),0)

      if percVal ~= lastMahAlert then
        -- Alert the user we are in critical alert
        if percVal > 100 then
          playCritical(percVal)
        elseif percVal > 90 and percVal < 100 then
          playMahPerc(percVal)
        elseif percVal % mahAlertPerc == 0 then
          playMahPerc(percVal)
        end
      end
    end

end

local function drawAlerts()

  percVal = 0
  curMah = getValue(data.fuelUsed)
  percVal =  round(((curMah/mahTarget) * 100),0)

  lcd.drawText(5, 10, "USED: "..curMah.."mah" , MIDSIZE)
  lcd.drawText(90, 30, percVal.." %" , MIDSIZE)

end


local function doMahAlert()
  playAlerts()
  drawAlerts()
end

local function draw()
  drawAlerts()
end


local function readUserMah()
  fileIO = io.open(settingsFile,'r')
  if fileIO ~= nil then
    local tmpStr = io.read(fileIO, 10)
    tmpStr =   userData.mahTarget
  end  
end


local function saveUserMah(mah)
  fileIO = io.open(settingsFile,'w')
  if fileIO ~= nil then
    io.write(fileIO,mah)
    io.close(fileIO)
  end
end





----------------------------------------------------------------
--
----------------------------------------------------------------
local function init_func()

  -- load our settings file data
  userMah = readUserMah()

  doMahAlert()
end
--------------------------------


----------------------------------------------------------------
--  Should handle any flow needed when the screen is NOT visible
----------------------------------------------------------------
local function bg_func()
  playAlerts()
end
--------------------------------


----------------------------------------------------------------
--  Should handle any flow needed when the screen is visible
--  All screen updating should be done by as little (one) function
--  outside of this run_func
----------------------------------------------------------------
local function run_func(event)

-- Menu Mode
  if blnMenuMode == 1 then
    -- We are in menu mode

    if intMenu == 0 then    -- FIRST SCREEN
      if event == 32 then
          intMenu = 1
      end

      -- Respond to user KeyPresses for mahSetup
      if event == EVT_PLUS_FIRST then
        mahAlertPerc = mahAlertPerc + 1
      end

      -- Long Presses
      if event == 68 then
        mahAlertPerc = mahAlertPerc + 1
      end

      if event == EVT_MINUS_FIRST then
        mahAlertPerc = mahAlertPerc - 1
      end

      -- Long Presses
      if event == 69 then
        mahAlertPerc = mahAlertPerc - 1
      end

      lcd.clear()

      lcd.drawScreenTitle(versionInfo,2,3)
      lcd.drawText(35,10, "Set Percentage Notification")
      lcd.drawText(70,20,"Every "..mahAlertPerc.." %",MIDSIZE)
      lcd.drawText(66, 35, "Use +/- to change",SMLSIZE)

      lcd.drawText(60, 55, "Press [MENU] to return",SMLSIZE)

    elseif intMenu == 1 then   -- SECOND SCREEN

      lcd.clear()





      result = popupInput('Set target mAh using [+/-]  '..userData.mahTarget,event,userData.mahTarget,0,10000)
      if result == "OK" then
          saveUserMah(userData.mahTarget)
          lcd.clear()
          blnMenuMode = 0
      elseif result == "CANCEL" then
          lcd.clear()
          blnMenuMode = 0
      else
        userData.mahTarget = result
        lcd.drawScreenTitle(versionInfo,3,3)
      end



      -- Second Screen
      if event == 32 then
        --Take us out of menu mode
        blnMenuMode = 0
      end
    end
  else    -- MAIN SCREEN
    -- we are not in menu mode
    if event == 32 then
      -- Put us in menu mode
        blnMenuMode = 1
        intMenu = 0
    end

    -- Respond to user KeyPresses for mahSetup
      if event == EVT_PLUS_FIRST then
        mahTarget = mahTarget + 1
      end

      if event == 68 then
        mahTarget = mahTarget + 1
      end

      if event == EVT_MINUS_FIRST then
        mahTarget = mahTarget - 1
      end

      if event == 69 then
        mahTarget = mahTarget - 1
      end


    --Update our screen
      lcd.clear()

      lcd.drawScreenTitle(versionInfo,1,3)

      lcd.drawGauge(6, 25, 70, 20, percVal, 100)
      lcd.drawText(130, 10, "Target mAh : ",MIDSIZE)
      lcd.drawText(160, 25, mahTarget,MIDSIZE)
      lcd.drawText(130, 40, "Use +/- to change",SMLSIZE)

      lcd.drawText(30, 55, "Press [MENU] for more options",SMLSIZE)

      draw()
      doMahAlert()

  end
  -- End Menu
end
--------------------------------

return {run=run_func, background=bg_func, init=init_func  }
