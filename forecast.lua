local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local utility = require( "utility" )
local myData = require( "mydata" )

local forecastTableView

local function convertTemperature( baseValue, format )
    local temperature = baseValue
    if format == "fahrenheit" then
        temperature = temperature * 9 / 5 + 32
    end
    return temperature
end

local function convertDistance( baseValue, format )
    local distance = baseValue
    if format == "miles" then
        distance = distance * 0.621371
    end
    return distance
end

function string.upperCaseFirstLetter( self )
    print("stringUCFL", self)
    local first = string.upper( string.sub( self, 1, 1))
    local rest = string.sub( self, 2)
    return first .. rest
end

local function onForecastRowRender( event )
    local row = event.row
    local params = event.row.params

    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth
    --
    -- Get a date from Unix Time so we can display the parts
    --
    local weekDay = os.date( "%a", params.time )
    local monthName = os.date( "%b", params.time )
    local monthDay = os.date( "%d", params.time )

    local weekDayText = display.newText( weekDay, 30, 5, myData.fontBold, 16 )
    row:insert( weekDayText ) 
    weekDayText:setFillColor( unpack( myData.textColor ) )
    weekDayText.anchorY = 0

    local dateText = display.newText( monthName .. " " .. monthDay, 30, 25, myData.font, 12 )
    dateText.anchorY = 0
    dateText:setFillColor( unpack( myData.textColor ) )
    row:insert( dateText )

    local highText = display.newText( params.high .. "º", 75, 5, myData.font, 16 )
    highText:setFillColor( unpack( myData.textColor ) )
    highText.anchorY = 0
    row:insert( highText )

    local lowText = display.newText( params.low .. "º", 75, 25, myData.font, 14 )
    lowText:setFillColor( 0.5 )
    lowText.anchorY = 0
    row:insert( lowText )

    local icon = display.newImageRect( "images/" .. params.icon .. ".png", 40, 40 )
    icon.x = 120
    icon.y = 25
    row:insert( icon )

--[[
    local summaryText = display.newText( params.summary, 135, 25, myData.font, 14 )
    summaryText:setFillColor( unpack( myData.textColor ) )
    summaryText.anchorX = 0
    row:insert( summaryText )
--]]

    local precipChanceText = display.newText( params.precipChance .."% " .. string.upperCaseFirstLetter( params.precipType ), 150, 25, myData.font, 14 )
    precipChanceText:setFillColor( unpack( myData.textColor ) )
    precipChanceText.anchorX = 0
    row:insert( precipChanceText )

    local humidityText = display.newText( params.humidity .. "%", 240, 25, myData.font, 14)
    humidityText:setFillColor( unpack( myData.textColor ) )
    row:insert( humidityText )

    local windSpeedPrefix = "mph"
    if myData.settings.distanceUnits == "kilometers" then
        windSpeedPrefix = "kph"
    end

    local windSpeedText = display.newText( params.windSpeed .. " " .. windSpeedPrefix, 300, 5, myData.font, 14 )
    windSpeedText:setFillColor( unpack( myData.textColor ) )
    windSpeedText.anchorY = 0
    row:insert( windSpeedText )

    local bearingLabels = { "N", "NNE", "NE", "ENE", "E", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N" }
    local bearingIndex = math.floor( ( params.windBearing % 360 ) / 22.5 ) + 1
    print(params.windBearing, bearingIndex, bearingLabels[ bearingIndex ])

    local windBearingText = display.newText( bearingLabels[ bearingIndex ], 300, 25, myData.font, 14)
    windBearingText:setFillColor( unpack( myData.textColor ) )
    windBearingText.anchorY = 0
    row:insert( windBearingText )
end

local function displayForecast()
    local response = myData.currentWeatherData
    --print( json.prettify( response ) )

    if not response then
        native.showAlert("Oops!", "Forcast information currently not avaialble!", { "Okay" } )
    end
    local daily = response.daily
    local forecast = {}

    forecastTableView:deleteAllRows()

    local isCategory = false
    local rowHeight = 50
    local rowColor = { default={ 1, 1, 1 }, over={ 1, 0.5, 0, 0.2 } }
    local lineColor = { 0.95, 0.95, 0.95 }
    if "Android" == myData.platform then
        rowColor = { default={ 0.2, 0.2, 0.2 }, over={ 0.3, 0.3, 0.3 } }
        lineColor = { 0, 0, 0 }
    end

    for i = 1, 7 do
        forecast[i] = {}
        forecast[i].high = math.floor( convertTemperature( tonumber( daily.data[i].temperatureMax ), myData.settings.tempUnits )  + 0.5 )
        forecast[i].low = math.floor( convertTemperature( tonumber( daily.data[i].temperatureMin ), myData.settings.tempUnits )  + 0.5 )
        forecast[i].fHigh = math.floor( convertTemperature( tonumber( daily.data[i].temperatureMax ), "fahrenheit" )  + 0.5 ) -- for graphing purposes
        forecast[i].fLow = math.floor( convertTemperature( tonumber( daily.data[i].temperatureMin ), "fahrenheit" )  + 0.5 )  -- for graphing purposes
        forecast[i].icon = daily.data[i].icon
        forecast[i].precipChance = math.floor( daily.data[i].precipProbability * 100 + 0.5 )
        if daily.data[i].precipType then
            forecast[i].precipType = daily.data[i].precipType
        else
            forecast[i].precipType = ""
        end
        forecast[i].time = daily.data[i].time
        forecast[i].summary = daily.data[i].summary
        forecast[i].windSpeed = math.floor( convertDistance( tonumber( daily.data[i].windSpeed ), myData.settings.distanceUnits ) + 0.5 )
        forecast[i].windBearing = tonumber( daily.data[i].windBearing )
        forecast[i].humidity = math.floor( tonumber( daily.data[i].humidity ) * 100 )
        forecastTableView:insertRow({
            isCategory = isCategory,
            rowHeight = rowHeight,
            rowColor = rowColor,
            lineColor = lineColor,
            params = {
                high = forecast[i].high,
                fHigh = forecast[i].fHigh,
                low = forecast[i].low,
                fLow = forecast[i].fLow,
                icon = forecast[i].icon,
                precipChance = forecast[i].precipChance,
                precipType = forecast[i].precipType,
                time = forecast[i].time,
                summary = forecast[i].summary,
                windSpeed = forecast[i].windSpeed,
                windBearing = forecast[i].windBearing,
                humidity = forecast[i].humidity,
                id = i
            },
        })

    end

end
--
-- Start the composer event handlers
--
function scene:create( event )
    local sceneGroup = self.view

    params = event.params
        
    --
    -- setup a page background, really not that important though composer
    -- crashes out if there isn't a display object in the view.
    --
    myData.navBar:setLabel( "Forecast for " ) --.. myData.currentLocation )
    local background = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
    background:setFillColor( unpack( myData.backgroundColor ) )
    sceneGroup:insert( background )

    local forecastHeaderBackground = display.newRect( display.contentCenterX, 95, display.contentWidth - 40, 50)
    forecastHeaderBackground:setFillColor( 1 )
    if "Android" == myData.platform then
        forecastHeaderBackground:setFillColor( 0.2 )
    end
    sceneGroup:insert( forecastHeaderBackground )

    local dayText = display.newText( "Date", 50, forecastHeaderBackground.y, myData.font, 14 )
    dayText:setFillColor( unpack( myData.textColor ) )
    sceneGroup:insert( dayText )

    local hiloText = display.newText( "Hi/Lo", 95, forecastHeaderBackground.y, myData.font, 14 )
    hiloText:setFillColor( unpack( myData.textColor ) )
    sceneGroup:insert( hiloText )

    local skyText = display.newText( "Skies", 140, forecastHeaderBackground.y, myData.font, 14 )
    skyText:setFillColor( unpack( myData.textColor ) )
    sceneGroup:insert( skyText )

    local precipText = display.newText( "Precip", 190, forecastHeaderBackground.y, myData.font, 14 )
    precipText:setFillColor( unpack( myData.textColor ) )
    sceneGroup:insert( precipText )

    local humidityText = display.newText( "Humidity", 260, forecastHeaderBackground.y, myData.font, 14 )
    humidityText:setFillColor( unpack( myData.textColor ) )
    sceneGroup:insert( humidityText )

    if display.contentWidth > 320 then
        local windText = display.newText( "Wind", 320, forecastHeaderBackground.y, myData.font, 14 )
        windText:setFillColor( unpack( myData.textColor ) )
        sceneGroup:insert( windText )
    end

    local tableViewHeight = 350 -- 7 * 50
    local availableHeight = display.contentHeight - 125
    if myData.platform == "iOS" then
        availableHeight = availableHeight - 50 -- compensate for the tabBar at the bottom
    end
    if tableViewHeight > availableHeight then
        tableViewHeight = availableHeight
    end 

    forecastTableView = widget.newTableView({
        left = 20,
        top = 125,
        height = tableViewHeight,
        width = display.contentWidth - 40,
        onRowRender = onForecastRowRender,
        onRowTouch = onForecastRowTouch,
        backgroundColor = myData.backgroundColor,
        listener = forecastListener
    })
    sceneGroup:insert( forecastTableView )
end

function scene:show( event )
    local sceneGroup = self.view

    params = event.params

    if event.phase == "will" then
        displayForecast()
    end
end

function scene:hide( event )
    local sceneGroup = self.view
    
    if event.phase == "will" then
    end

end

function scene:destroy( event )
    local sceneGroup = self.view
    
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
return scene
