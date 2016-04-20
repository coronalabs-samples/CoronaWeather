local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )

local myData = require( "mydata" )
local utility = require( "utility" )
local wx = require( "weather" )
local theme = require( "theme" )
local UI = require( "ui" )

local sceneBackground
local locationText
local temperatureText
local icon
local rainChanceText
local weatherText
local highText
local lowText
local mercury
local thermometer
local thermometerOverlay
local compassNeedle
local visibilityLabel
local visibilityText
local pressureLabel
local pressureText
local humidityLabel
local humidityText
local feelsLike
local feelsLikeLabel
local feelsLikeText
local sunriseTextLabel
local sunriseText
local sunsetTextLabel
local sunsetText
local moonTextLabel
local moonText
local cloudCoverTextLabel
local cloudCoverText
local dewPointTextLabel
local dewPointText
local windSpeedLabel
local windSpeedText
local hourlyScrollView
local poly
local hourlyDateText = {}
local hourlyTempText = {}
local hourlyPercentText = {}
local hourlyImage = {}
local icons = {}

local tempPoints = {}
local pathPoints = {}
local curve

local forecastTableView
local forecastScrollView

local forecastURL 
local currentConditionsURL

local function iconListener( event )
    utility.print_r( event )
    scene.view:insert( event.target )

end

local function reverseGeocodeResponse( event )
    utility.print_r( event )
    if event.isError then
        -- bad address
    else
        local response = json.decode( event.response )
        utility.print_r(response)
        myData.navBar:setLabel( response.results[1].locations[1].adminArea5 .. ", " .. response.results[1].locations[1].adminArea3 )
    end
end

local function reverseGeocode( latitude, longitude )
    local URL = "http://www.mapquestapi.com/geocoding/v1/reverse?outFormat=json&key=" .. myData.mapquestKey .. "&location=" .. myData.latitude .. "," .. myData.longitude
    print( URL )
    network.request( URL, "GET", reverseGeocodeResponse)
end
    
local function onRowRender( event )

    -- Get reference to the row group
    local row = event.row
    local params = event.row.params

    --utility.print_r( event )

    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    local rowText = params.date .. " " .. params.high .. "/" .. params.low .. " - " .. params.pop .. " - " .. params.conditions
    local rowDate = display.newText( row, params.date, 10, 0, "HelveticaNeue", 16)
    rowDate.anchorX = 0
    rowDate.x = 5
    rowDate.y = rowHeight * 0.5
    rowDate:setFillColor( 0.0 )

    local rowTemps = display.newText( row, params.high .. "/" .. params.low, 0, 0, "HelveticaNeue", 16)
    rowTemps.anchorX = 0
    rowTemps.x = 90
    rowTemps.y = rowHeight * 0.5
    rowTemps:setFillColor( 0.0 )

    local rowPercip = display.newText( row, params.pop, 0, 0, "HelveticaNeue", 18)
    rowPercip.anchorX = 0
    rowPercip.x = 150
    rowPercip.y = rowHeight * 0.5
    rowPercip:setFillColor( 0.0 )

    if myData.settings.showIcons then
        print("params.icon", params.icon)
        local rowConditions = display.newImageRect(row, "images/" .. params.icon .. ".png", 50, 50)
        rowConditions.x = 240
        rowConditions.y = rowHeight * 0.5
    else
        local rowConditions = display.newText( row, params.conditions, 0, 0, display.contentWidth - 205, 0, "HelveticaNeue", 16)
        rowConditions.anchorX = 0
        rowConditions.x = 205
        rowConditions.y = rowHeight * 0.5
        rowConditions:setFillColor( 0.0 )
    end
end
--[[
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
--]]
local function displayCurrentConditions( )
    print("Lat, Lng", myData.latitude, myData.longitude)
    print("last refresh", myData.lastRefresh)
    --utility.print_r( myData )
    local response = myData.currentWeatherData
    --print( json.prettify( response ) )

    if not response then
        native.showAlert("Oops!", "Forcast information currently not avaialble!", { "Okay" } )
    end

    --
    -- Lets get all the weather bits we are interested in
    --
    local currently = response.currently
    print( json.prettify( response ) )
    local minutely = response.minutely
    local daily = response.daily
    local hourly = response.hourly

    local temperature = "??"
    if currently.temperature then
        temperature = math.floor( wx.convertTemperature( tonumber( currently.temperature ), myData.settings.tempUnits )  + 0.5 ) 
    end
    local precipType = "??"
    local precipChance =  "??"
    if response.daily.data[1].precipProbability then
        precipChance = tostring( math.floor( tonumber( currently.precipProbability ) * 100 + 0.5 ) ) .. "%"
    end
    local lowTemp = math.floor( wx.convertTemperature( tonumber( daily.data[1].temperatureMin ), myData.settings.tempUnits ) + 0.5 )
    local highTemp = math.floor( wx.convertTemperature( tonumber( daily.data[1].temperatureMax ), myData.settings.tempUnits ) + 0.5 )
    local windSpeed = math.floor( wx.convertDistance( tonumber( currently.windSpeed ), myData.settings.distanceUnits ) + 0.5 )
    local bearingIndex = nil
    local windDirection
    if currently.windBearing then
        windDirection = tonumber( currently.windBearing )
        bearingIndex= math.floor( ( currently.windBearing % 360 ) / 22.5 ) + 1
    end  
    local pressure = tonumber( currently.pressure)
    if myData.settings.pressureUnits == "inches" then
        pressure = math.floor( pressure * 0.0295301 * 100 ) / 100
    end
    local humdity = tonumber( currently.humidity * 100 )
    local visibility = math.floor( wx.convertDistance( tonumber( currently.visibility ), myData.settings.distanceUnits ) + 0.5 )
    local feelLike = temperature
    if currently.apparentTemperature then 
        feelsLike = math.floor( wx.convertTemperature( tonumber( currently.apparentTemperature ), myData.settings.tempUnits ) + 0.5 )
    end
    local sunriseTime = response.daily.data[1].sunriseTime
    local sunsetTime = response.daily.data[1].sunsetTime
    local moonPhase = response.daily.data[1].moonPhase
    local nearestStormDistance = math.floor( wx.convertDistance( tonumber( currently.nearestStormDistance ), myData.settings.distanceUnits ) + 0.5 )
    local nearestStormBearing = currently.nearestStormBearing
    local icon = currently.icon
    local dewPoint = math.floor( wx.convertTemperature( tonumber( currently.dewPoint ), myData.settings.tempUnits ) + 0.5 )
    local cloudCover = currently.cloudCover
    local ozone = currently.ozone

    highText.text = "High " .. tostring( highTemp ) .. "º"
    lowText.text = "Low " .. tostring( lowTemp ) .. "º"

    temperatureText.text = tostring( temperature ) .. "º"
    --compassNeedle.rotation = windDirection
    local windSpeedPrefix = "kph"
    local distancePrefix = "km"
    if myData.settings.distanceUnits == "miles" then
        windSpeedPrefix = "mph"
        distancePrefix = "mi"
    end
    if bearingIndex then
        windSpeedText.text = wx.bearingLabels[ bearingIndex ] .. " " .. windSpeed .. " " .. windSpeedPrefix
    else
        windSpeedText.text = windSpeed .. " " .. windSpeedPrefix
    end
    local pressurePrefix = " mb"
    if myData.settings.pressureUnits == "inches" then
        pressurePrefix = " in. Hg."
    end
    pressureText.text = pressure .. pressurePrefix
    humidityText.text = humdity .. "% "
    visibilityText.text = visibility .. distancePrefix
    feelsLikeText.text = feelsLike .. "º"

    local weatherIcon = display.newImageRect( "images/" .. currently.icon .. ".png", 128, 128 )
    weatherIcon.x = display.contentWidth - 74  
    weatherIcon.y = temperatureText.y + 10
    forecastScrollView:insert( weatherIcon )

    --
    -- We can't postiion this text until we have the Icon loaded. We don't create the icon until we're displaying the weather.
    --
    weatherText.text = hourly.data[1].summary
    weatherText.x = weatherIcon.x
    weatherText.y = weatherIcon.y + 70
    weatherText.anchorX = 0.5

    dewPointText.text = dewPoint
    
    sunriseText.text = os.date( "%H:%M", sunriseTime )
    sunsetText.text = os.date( "%H:%M", sunsetTime )
    -- moonText.text = moonPhase
    cloudCoverText.text = tostring( math.floor( cloudCover * 100 + 0.5 ) ) .. "%"

    local moonImages = { 
        "images/new_moon.png", 
        "images/waxing_crescent.png", 
        "images/first_quarter.png", 
        "images/waxing_gibbous.png",
        "images/full_moon.png",
        "images/waning_gibbous.png",
        "images/third_quarter.png",
        "images/waning_crescent.png",
        "images/new_moon.png"
    }
    local moonIdx = math.floor( ( moonPhase * 100  ) / 12.5 + 0.5 ) + 1
    local moonImage = display.newImageRect( moonImages[ moonIdx ], 25, 25 )
    moonImage.x = moonTextLabel.x + 25
    moonImage.y = moonTextLabel.y 
    forecastScrollView:insert( moonImage )

    local xWidth = display.actualContentWidth / 9

    local hourlyScrollView = widget.newScrollView
    {
        top = highText.x + 100,
        left = 0,
        width = display.actualContentWidth,
        height = 180,
        scrollWidth = #hourly.data * xWidth,
        scrollHeight = 150,
        backgroundColor = theme.backgroundColor,
        isBounceEnabled = false,
        verticalScrollDisabled = true
    }
    forecastScrollView:insert( hourlyScrollView )

--
-- Because we won't have our graph of the temperatures until we create the polygon later and it's 
-- more efficient to go ahead and create our other display objects now, let's create a group to hold them
-- that we can insert later to assure proper layering
--

    local hourlyIconGroup = display.newGroup()

--    for i = 1, #hourly.data do
--        tempPoints[ #tempPoints + 1 ] = { x = xWidth * ( i - 1 ), y = 35 - hourly.data[ i ].temperature }
--    end

    table.remove( tempPoints )
    tempPoints = nil
    tempPoints = {}
    local maxPeriodTemperature = -999999
    for i = 1, #hourly.data do
        local periodTemperature = math.floor( wx.convertTemperature( tonumber( hourly.data[ i ].temperature ), "fahrenheit" ) + 0.5 )
        tempPoints[ #tempPoints + 1 ] = xWidth * ( i - 1 )
        tempPoints[ #tempPoints + 1 ] = 0 - periodTemperature 
        if periodTemperature > maxPeriodTemperature then
            maxPeriodTemperature = periodTemperature
        end
        if i < #hourly.data then -- skip the last temp since there isn't a polygon slice for it
            local hourlyTempText = display.newText( tostring( math.floor( wx.convertTemperature( tonumber( hourly.data[ i ].temperature ), myData.settings.tempUnits ) + 0.5 ) ) .. "º", xWidth * ( i - 1 ) + 3, 120 - periodTemperature - 20, theme.font, 12 )
            hourlyTempText.anchorX = 0
            hourlyTempText.anchorY = 1
            hourlyTempText:setFillColor( unpack( theme.textColor ) )
            hourlyScrollView:insert( hourlyTempText )
            local icon = display.newImageRect( "images/" .. hourly.data[i].icon .. ".png", 24, 24 )
            icon.x = xWidth * ( i - 1 ) + 15
            icon.y = 120
            hourlyIconGroup:insert( icon )
            local precipChanceText = display.newText( tonumber( math.floor( hourly.data[i].precipProbability * 100 + 0.5) ) .. "%", icon.x, icon.y + 20, theme.font, 12 )
            precipChanceText:setFillColor( 0 )
            hourlyIconGroup:insert( precipChanceText )
            if (i - 1) % 2 == 0 then
                local forecastTime = os.date( "%I%p", hourly.data[i].time )
                --
                -- remove the leading 0
                --
                if string.sub(forecastTime, 1, 1) == "0" then
                    forecastTime = string.sub( forecastTime, 2 )
                end
                local forecastTimeText = display.newText( forecastTime, precipChanceText.x, precipChanceText.y + 30, theme.font, 12 )
                forecastTimeText:setFillColor( unpack( theme.textColor ) )
                hourlyIconGroup:insert( forecastTimeText )
            end
        end
    end
    tempPoints[ #tempPoints + 1 ] = tempPoints[ #tempPoints - 1 ]
    tempPoints[ #tempPoints + 1 ] = 50 
    tempPoints[ #tempPoints + 1 ] = 0
    tempPoints[ #tempPoints + 1 ] = 50 

    local topColor = { 0.3916, 0.6172, 1.0 }
    if tonumber( maxPeriodTemperature ) > 75 then
        topColor = { 0, 1, 0 }
    elseif tonumber( maxPeriodTemperature ) > 85 then
        topColor = { 1, 1, 0 }
    elseif tonumber( maxPeriodTemperature ) > 95 then
        topColor = { 1, 0.5, 0 }
    else
        topColor = { 1, 0, 0 }
    end

    local paint = { 0.6, 0.8, 1.0 }
--[[
        type = "gradient",
        color1 = { 0.3916, 0.6172, 1.0 },
        color2 = topColor,
        direction = "up"
    }
--]]
    if poly then
        poly:removeSelf()
        poly = nil
    end
    poly = display.newPolygon( 0, 20, tempPoints )
    --local poly = display.newLine( tempPoints[1].x, tempPoints[1].y, tempPoints[2].x, tempPoints[2].y )
    --for i = 3, #tempPoints do
    --    poly:append( tempPoints[i].x, tempPoints[i].y)
    --end
    hourlyScrollView:insert(poly)
    poly.anchorY = 0
    poly.anchorX = 0
    poly.strokeWidth = 2
    poly:setStrokeColor( 0.8, 0.8, 0.8 )
    poly.fill = paint

    hourlyScrollView:insert( hourlyIconGroup )
    return true
end

-- ScrollView listener
local function scrollListener( event )

    local phase = event.phase
    if ( phase == "began" ) then 
        --print( "Scroll view was touched" )
    elseif ( phase == "moved" ) then 
        --print( "Scroll view was moved" )
    elseif ( phase == "ended" ) then 
        --print( "Scroll view was released" )
    end

    -- In the event a scroll limit is reached...
    if ( event.limitReached ) then
        if ( event.direction == "up" ) then print( "Reached top limit" )
        elseif ( event.direction == "down" ) then print( "Reached bottom limit" )
            -- refresh
            myData.lastRefresh = os.time()
            temperatureText.text = "??º"
            wx.fetchWeather( displayCurrentConditions )
        elseif ( event.direction == "left" ) then print( "Reached left limit" )
        elseif ( event.direction == "right" ) then print( "Reached right limit" )
        end
    end

    return true
end
--
-- Start the composer event handlers
--
function scene:create( event )
    local sceneGroup = self.view

    sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    sceneGroup:insert( sceneBackground )

    local scrollViewHeight = display.actualContentHeight - 100
    -- Create the widget
    forecastScrollView = widget.newScrollView
    {
        top = 50,
        left = 0,
        width = display.actualContentWidth,
        height = scrollViewHeight,
        scrollWidth = display.contentWidth,
        scrollHeight = 800,
        hideBackground = true,
        listener = scrollListener
    }
    sceneGroup:insert( forecastScrollView )
        
    --
    -- setup a page background, really not that important though composer
    -- crashes out if there isn't a display object in the view.
    --

    temperatureText = display.newText("" .. "º", display.contentWidth * 0.33, 70, theme.font, 100 )
    temperatureText:setFillColor( 0.33, 0.66, 0.99 )
    forecastScrollView:insert( temperatureText )


    weatherText = display.newText("", display.contentCenterX, display.contentWidth * 0.667, theme.font, 18 )
    forecastScrollView:insert( weatherText )

    --rainChanceText = display.newText("Rain chance " .. "%", display.contentCenterX, 230, "HelveticaNeue-Thin", 20 )
    --rainChanceText:setFillColor( 0.4, 0.4, 0.4 )
    --sceneGroup:insert( rainChanceText )

    highText = display.newText("", temperatureText.x - 40, temperatureText.y + 80, theme.font, 18)
    forecastScrollView:insert( highText )
    highText.anchorX = 0.5

    lowText = display.newText("", temperatureText.x + 40, temperatureText.y + 80, theme.font, 18)
    forecastScrollView:insert( lowText )
    lowText.anchorX = 0.5

    windSpeedLabel = display.newText( "Winds: ", 60, highText.y + 220, theme.font, 14 )
    windSpeedLabel.anchorX = 1
    forecastScrollView:insert( windSpeedLabel )
    windSpeedText = display.newText( "", 70, windSpeedLabel.y , theme.fontBold, 14 )
    windSpeedText.anchorX = 0
    forecastScrollView:insert( windSpeedText )

    visibilityLabel = display.newText( "Visibility:", 60, windSpeedText.y + 24, theme.font, 14 )
    visibilityLabel.anchorX = 1
    forecastScrollView:insert( visibilityLabel )
    visibilityText = display.newText( "", 70, visibilityLabel.y, theme.fontBold, 14 )
    visibilityText.anchorX = 0
    forecastScrollView:insert( visibilityText )

    pressureLabel = display.newText( "Pressure:", 60, visibilityLabel.y + 24, theme.font, 14 )
    pressureLabel.anchorX = 1
    forecastScrollView:insert( pressureLabel )
    pressureText = display.newText( "", 70, pressureLabel.y, theme.fontBold, 14 )
    pressureText.anchorX = 0
    forecastScrollView:insert( pressureText )

    humidityLabel = display.newText( "Humidity:", 60, pressureLabel.y + 24, theme.font, 14 )
    humidityLabel.anchorX = 1
    forecastScrollView:insert( humidityLabel )
    humidityText = display.newText( "", 70, humidityLabel.y, theme.fontBold, 14 )
    humidityText.anchorX = 0
    forecastScrollView:insert( humidityText )

    feelsLikeLabel = display.newText( "Feels like:", 60, humidityLabel.y + 24, theme.font, 14 )
    feelsLikeLabel.anchorX = 1
    forecastScrollView:insert( feelsLikeLabel )
    feelsLikeText = display.newText( "", 70, feelsLikeLabel.y, theme.fontBold, 14 )
    feelsLikeText.anchorX = 0
    forecastScrollView:insert( feelsLikeText )

    sunriseTextLabel = display.newText( "Sunrise", display.contentWidth - 70, windSpeedLabel.y, theme.font, 14 )
    
    sunriseTextLabel.anchorX = 1
    forecastScrollView:insert( sunriseTextLabel )
    sunriseText = display.newText( "", display.contentWidth - 60, sunriseTextLabel.y, theme.fontBold, 14 )
    sunriseText:setFillColor( unpack( theme.textColor ) )
    sunriseText.anchorX = 0
    forecastScrollView:insert( sunriseText )

    sunsetTextLabel = display.newText( "Sunset", display.contentWidth - 70, visibilityText.y, theme.font, 14 )
    sunsetTextLabel.anchorX = 1
    forecastScrollView:insert( sunsetTextLabel )
    sunsetText = display.newText( "", display.contentWidth - 60, sunsetTextLabel.y, theme.fontBold, 14 )
    
    sunsetText.anchorX = 0
    forecastScrollView:insert( sunsetText )

    moonTextLabel = display.newText( "Moon phase", display.contentWidth - 70, pressureLabel.y, theme.font, 14 )
    moonTextLabel.anchorX = 1
    forecastScrollView:insert( moonTextLabel )
    moonText = display.newText( "", display.contentWidth - 60, moonTextLabel.y, theme.fontBold, 14 )
    moonText.anchorX = 0
    forecastScrollView:insert( moonText )

    cloudCoverTextLabel = display.newText( "Cloud Cover", display.contentWidth - 70, humidityText.y, theme.font, 14 )
    
    cloudCoverTextLabel.anchorX = 1
    forecastScrollView:insert( cloudCoverTextLabel )
    cloudCoverText = display.newText( "", display.contentWidth - 60, cloudCoverTextLabel.y, theme.fontBold, 14 )
    cloudCoverText.anchorX = 0
    forecastScrollView:insert( cloudCoverText )

    dewPointTextLabel = display.newText( "DewPoint", display.contentWidth - 70, feelsLikeLabel.y, theme.font, 14 )
    
    dewPointTextLabel.anchorX = 1
    forecastScrollView:insert( dewPointTextLabel )
    dewPointText = display.newText( "", display.contentWidth - 60, dewPointTextLabel.y, theme.fontBold, 14 )
    dewPointText.anchorX = 0
    forecastScrollView:insert( dewPointText )
end

function scene:show( event )
    local sceneGroup = self.view

    local latitude = myData.latitude
    local longitude = myData.longitude

    if event.phase == "will" then

        UI.navBar:setLabel( myData.settings.locations[1].name )
        for i = 1, #myData.settings.locations do
            if myData.settings.locations[i].selected then
                UI.navBar:setLabel( myData.settings.locations[i].name )
                break
            end
        end

        sceneBackground:setFillColor( unpack( theme.backgroundColor ) )
        weatherText:setFillColor( unpack( theme.textColor ) )
        highText:setFillColor( unpack( theme.textColor ) )
        lowText:setFillColor( unpack( theme.textColor ) )
        windSpeedLabel:setFillColor( unpack( theme.textColor ) )
        windSpeedText:setFillColor( unpack( theme.textColor ) )
        humidityLabel:setFillColor( unpack( theme.textColor ) )
        humidityText:setFillColor( unpack( theme.textColor ) )
        visibilityLabel:setFillColor( unpack( theme.textColor ) )
        visibilityText:setFillColor( unpack( theme.textColor ) )
        feelsLikeLabel:setFillColor( unpack( theme.textColor ) )
        feelsLikeText:setFillColor( unpack( theme.textColor ) )
        sunriseTextLabel:setFillColor( unpack( theme.textColor ) )
        sunsetText:setFillColor( unpack( theme.textColor ) )
        sunsetTextLabel:setFillColor( unpack( theme.textColor ) )
        sunsetText:setFillColor( unpack( theme.textColor ) )
        pressureLabel:setFillColor( unpack( theme.textColor ) )
        pressureText:setFillColor( unpack( theme.textColor ) )
        moonTextLabel:setFillColor( unpack( theme.textColor ) )
        moonText:setFillColor( unpack( theme.textColor ) )
        cloudCoverTextLabel:setFillColor( unpack( theme.textColor ) )
        cloudCoverText:setFillColor( unpack( theme.textColor ) )
        dewPointTextLabel:setFillColor( unpack( theme.textColor ) )
        dewPointText:setFillColor( unpack( theme.textColor ) )

        wx.fetchWeather( displayCurrentConditions )
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
