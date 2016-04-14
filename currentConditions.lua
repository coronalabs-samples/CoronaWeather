local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local myData = require( "mydata" )
local json = require( "json" )
local utility = require( "utility" )
local wx = require( "weather" )

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

local hourlyScroll
local hourlyDateText = {}
local hourlyTempText = {}
local hourlyPercentText = {}
local hourlyImage = {}
local icons = {}

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

    local temperature = "??"
    if currently.temperature then
        temperature = math.floor( wx.convertTemperature( tonumber( currently.temperature ), myData.settings.tempUnits )  + 0.5 ) 
    end
    local precipType = "??"
    local precipChance =  "??"
    if response.daily.data[1].precipProbability then
        precipChance = tostring( math.floor( tonumber( currently.precipProbability ) * 100 + 0.5 ) ) .. "%"
    end
    local lowTemp = math.floor( wx.convertTemperature( tonumber( response.daily.data[1].temperatureMin ), myData.settings.tempUnits ) + 0.5 )
    local highTemp = math.floor( wx.convertTemperature( tonumber( response.daily.data[1].temperatureMax ), myData.settings.tempUnits ) + 0.5 )
    local windSpeed = math.floor( wx.convertDistance( tonumber( currently.windSpeed ), myData.settings.distanceUnits ) + 0.5 )
    local windDirection
    if currently.windBearing then
        windDirection = tonumber( currently.windBearing )
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
    local dewPoint = currently.dewPoint
    local cloudCover = currently.cloudCover
    local ozone = currently.ozone

    highText.text = "High " .. tostring( highTemp ) .. "º"
    lowText.text = "Low " .. tostring( lowTemp ) .. "º"

    mercury.height = highTemp + 12-- lowTemp
    mercury.y = thermometer.y + 52

    local topColor = { 0.3916, 0.6172, 1.0 }
    if tonumber( currently.temperature ) > 10 then
        topColor = { 0, 1, 0 }
    elseif tonumber( currently.temperature ) > 25 then
        topColor = { 1, 1, 0 }
    elseif tonumber( currently.temperature ) > 30 then
        topColor = { 1, 0.5, 0 }
    else
        topColor = { 1, 0, 0 }
    end

    local paint = {
        type = "gradient",
        color1 = { 0.3916, 0.6172, 1.0 },
        color2 = topColor,
        direction = "up"
    }
    mercury.fill = paint

    --
    -- I need the temperature here in Fahrenheit to scale properly to the thermometer
    --
    fLowTemp = lowTemp
    fHighTemp = highTemp
    if "celsius" == myData.settings.tempUnits then
        fLowTemp = math.floor( wx.convertTemperature( tonumber( response.daily.data[1].temperatureMin ), "fahrenheit" ) + 0.5 )
        fHighTemp = math.floor( wx.convertTemperature( tonumber( response.daily.data[1].temperatureMax ), "fahrenheit" ) + 0.5 )
    end
    highText.y = thermometer.y + 50 - fHighTemp
    highText.x = mercury.x + 55
    lowText.y = thermometer.y + 50  - fLowTemp
    lowText.x = mercury.x + 55
    if ( lowText.y - highText.y ) < 20 then
        lowText.y = lowText.y + 10
        highText.y = highText.y - 10
    end

    temperatureText.text = tostring( temperature ) .. "º"
    compassNeedle.rotation = windDirection
    local windSpeedPrefix = "kph"
    local distancePrefix = "km"
    if myData.settings.distanceUnits == "miles" then
        windSpeedPrefix = "mph"
        distancePrefix = "mi"
    end
    windSpeedText.text = windSpeed .. " " .. windSpeedPrefix
    local pressurePrefix = " mb"
    if myData.settings.pressureUnits == "inches" then
        pressurePrefix = " in. Hg."
    end
    pressureText.text = pressure .. pressurePrefix
    humidityText.text = humdity .. "% "
    visibilityText.text = visibility .. distancePrefix
    feelsLikeText.text = feelsLike .. "º"

    local weatherIcon = display.newImage( "images/" .. currently.icon .. ".png")
    weatherIcon.x = mercury.x
    weatherIcon.y = compassNeedle.y
    forecastScrollView:insert( weatherIcon )
    weatherIcon:scale(0.3, 0.3)

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
    moonImage.y = moonTextLabel.y + 50
    scene.view:insert( moonImage )

    return true
end
--[[
local function processCurrentConditionsRequest( event )
    print("processing forecast request")
    --print(json.prettify(event))
    if not event.isError then
        myData.currentWeatherData = json.decode(event.response)
        myData.lastRefresh = os.time()
        displayCurrentConditions()
    end
    return true
end

local function fetchWeather( )

    myData.latitude = myData.settings.locations[1].latitude
    myData.longitude = myData.settings.locations[1].longitude
    for i = 1, #myData.settings.locations do
        if myData.settings.locations[i].selected then
            myData.latitude = myData.settings.locations[i].latitude
            myData.longitude = myData.settings.locations[i].longitude
            break
        end
    end

    local forecastIOURL = "https://api.forecast.io/forecast/" .. myData.forecastIOkey .. "/" .. tostring(myData.latitude) .. "," .. tostring(myData.longitude)
    forecastIOURL = forecastIOURL .. "?units=si"
    print( forecastIOURL )
    local now = os.time()
    print("cache test", now, myData.lastRefresh )
    if now > myData.lastRefresh + (15 * 60) then
        network.request( forecastIOURL, "GET", processCurrentConditionsRequest )
    else
        print("showing cached data")
        displayCurrentConditions( )
    end
end
--]]
-- ScrollView listener
local function scrollListener( event )

    local phase = event.phase
    if ( phase == "began" ) then print( "Scroll view was touched" )
    elseif ( phase == "moved" ) then print( "Scroll view was moved" )
    elseif ( phase == "ended" ) then print( "Scroll view was released" )
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

    params = event.params

    local scrollViewHeight = display.actualContentHeight - 100
    local textColor = 0.0
    local bgColor = { 0.95 }
    if "Android" == myData.platform then
        scrollViewHeight = display.actualContentHeight - 50
        textColor = 1.0
        bgColor = { 0.05 }
    end
    print(myData.platform, bgColor[1])
    -- Create the widget
    forecastScrollView = widget.newScrollView
    {
        top = 50,
        left = 0,
        width = display.actualContentWidth,
        height = scrollViewHeight,
        scrollWidth = display.contentWidth,
        scrollHeight = 800,
        backgroundColor = bgColor,
        listener = scrollListener
    }
    sceneGroup:insert( forecastScrollView )
        
    --
    -- setup a page background, really not that important though composer
    -- crashes out if there isn't a display object in the view.
    --

    myData.navBar:setLabel( myData.currentLocation )

    weatherText = display.newText("", display.contentCenterX, 75, display.contentWidth - 20, 0, myData.font, 18 )
    weatherText:setFillColor( textColor )
    forecastScrollView:insert( weatherText )

    temperatureText = display.newText("" .. "º", display.contentWidth * 0.33, 80, myData.font, 140 )
    temperatureText:setFillColor( 0.33, 0.66, 0.99 )
    forecastScrollView:insert( temperatureText )

    --rainChanceText = display.newText("Rain chance " .. "%", display.contentCenterX, 230, "HelveticaNeue-Thin", 20 )
    --rainChanceText:setFillColor( 0.4, 0.4, 0.4 )
    --sceneGroup:insert( rainChanceText )

    highText = display.newText("", 10, 245, myData.font, 18)
    highText:setFillColor( textColor )
    forecastScrollView:insert( highText )
    highText.anchorX = 0.5

    lowText = display.newText("", display.contentCenterX , 245, myData.font, 18)
    lowText:setFillColor( textColor )
    forecastScrollView:insert( lowText )
    lowText.anchorX = 0.5

    local thermometerFilename = "images/thermometer.png"
    if "Android" == myData.platform then
        thermometerFilename = "images/thermometer_dark.png"
    end

    thermometer = display.newImageRect( thermometerFilename, 45, 142 )
    forecastScrollView:insert( thermometer )
    thermometer.y = temperatureText.y
    thermometer.x = display.contentWidth * 0.75

    mercury = display.newRect( thermometer.x - 11.5, thermometer.y - 110, 8, 100)
    mercury:setFillColor( 1, 0, 0 )
    mercury.anchorY = 1
    forecastScrollView:insert( mercury )

    thermometerOverlay = display.newImageRect( "images/thermometer_overlay.png", 45, 142)
    forecastScrollView:insert( thermometerOverlay )
    thermometerOverlay.x = thermometer.x
    thermometerOverlay.y = thermometer.y

    local compassBackground = display.newImageRect( "images/compass.png", 128, 128 )
    compassBackground.x = temperatureText.x - 15
    compassBackground.y = temperatureText.y + 145
    forecastScrollView:insert( compassBackground )

    compassNeedle = display.newImageRect( "images/compass_pointer.png", 128, 128 )
    compassNeedle.x = compassBackground.x
    compassNeedle.y = compassBackground.y
    forecastScrollView:insert( compassNeedle )

    windSpeedText = display.newText( "", compassBackground.x, compassBackground.y + 80, myData.font, 18 )
    windSpeedText:setFillColor( textColor )
    forecastScrollView:insert( windSpeedText )

    visibilityLabel = display.newText( "Visibility:", 80, windSpeedText.y + 50, myData.font, 14 )
    visibilityLabel:setFillColor( textColor )
    visibilityLabel.anchorX = 1
    forecastScrollView:insert( visibilityLabel )
    visibilityText = display.newText( "", 90, visibilityLabel.y, myData.fontBold, 14 )
    visibilityText:setFillColor( textColor )
    visibilityText.anchorX = 0
    forecastScrollView:insert( visibilityText )

    pressureLabel = display.newText( "Pressure:", 80, visibilityLabel.y + 24, myData.font, 14 )
    pressureLabel:setFillColor( textColor )
    pressureLabel.anchorX = 1
    forecastScrollView:insert( pressureLabel )
    pressureText = display.newText( "", 90, pressureLabel.y, myData.fontBold, 14 )
    pressureText:setFillColor( textColor )
    pressureText.anchorX = 0
    forecastScrollView:insert( pressureText )

    humidityLabel = display.newText( "Humidity:", 80, pressureLabel.y + 24, myData.font, 14 )
    humidityLabel:setFillColor( textColor )
    humidityLabel.anchorX = 1
    forecastScrollView:insert( humidityLabel )
    humidityText = display.newText( "", 90, humidityLabel.y, myData.fontBold, 14 )
    humidityText:setFillColor( textColor )
    humidityText.anchorX = 0
    forecastScrollView:insert( humidityText )

    feelsLikeLabel = display.newText( "Feels like:", 80, humidityLabel.y + 24, myData.font, 14 )
    feelsLikeLabel:setFillColor( textColor )
    feelsLikeLabel.anchorX = 1
    forecastScrollView:insert( feelsLikeLabel )
    feelsLikeText = display.newText( "", 90, feelsLikeLabel.y, myData.fontBold, 14 )
    feelsLikeText:setFillColor( textColor )
    feelsLikeText.anchorX = 0
    forecastScrollView:insert( feelsLikeText )

    sunriseTextLabel = display.newText( "Sunrise", display.contentWidth - 90, visibilityText.y, myData.font, 14 )
    sunriseTextLabel:setFillColor( unpack( myData.textColor ) )
    sunriseTextLabel.anchorX = 1
    forecastScrollView:insert( sunriseTextLabel )
    sunriseText = display.newText( "", display.contentWidth - 80, visibilityText.y, myData.fontBold, 14 )
    sunriseText:setFillColor( unpack( myData.textColor ) )
    sunriseText.anchorX = 0
    forecastScrollView:insert( sunriseText )

    sunsetTextLabel = display.newText( "Sunset", display.contentWidth - 90, pressureText.y, myData.font, 14 )
    sunsetTextLabel:setFillColor( unpack( myData.textColor ) )
    sunsetTextLabel.anchorX = 1
    forecastScrollView:insert( sunsetTextLabel )
    sunsetText = display.newText( "", display.contentWidth - 80, pressureText.y, myData.fontBold, 14 )
    sunsetText:setFillColor( unpack( myData.textColor ) )
    sunsetText.anchorX = 0
    forecastScrollView:insert( sunsetText )

    moonTextLabel = display.newText( "Moon phase", display.contentWidth - 90, humidityText.y, myData.font, 14 )
    moonTextLabel:setFillColor( unpack( myData.textColor ) )
    moonTextLabel.anchorX = 1
    forecastScrollView:insert( moonTextLabel )
    moonText = display.newText( "", display.contentWidth - 80, humidityText.y, myData.fontBold, 14 )
    moonText:setFillColor( unpack( myData.textColor ) )
    moonText.anchorX = 0
    forecastScrollView:insert( moonText )

    cloudCoverTextLabel = display.newText( "Cloud Cover", display.contentWidth - 90, feelsLikeText.y, myData.font, 14 )
    cloudCoverTextLabel:setFillColor( unpack( myData.textColor ) )
    cloudCoverTextLabel.anchorX = 1
    forecastScrollView:insert( cloudCoverTextLabel )
    cloudCoverText = display.newText( "", display.contentWidth - 80, feelsLikeText.y, myData.fontBold, 14 )
    cloudCoverText:setFillColor( unpack( myData.textColor ) )
    cloudCoverText.anchorX = 0
    forecastScrollView:insert( cloudCoverText )

end

function scene:show( event )
    local sceneGroup = self.view

    params = event.params

    local latitude = myData.latitude
    local longitude = myData.longitude

    if event.phase == "will" then

        myData.navBar:setLabel( myData.settings.locations[1].name )
        for i = 1, #myData.settings.locations do
            if myData.settings.locations[i].selected then
                myData.navBar:setLabel( myData.settings.locations[i].name )
            end
        end

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
