local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )

local myData = require( "classes.mydata" )
local utility = require( "libs.utility" )
local wx = require( "classes.weather" )
local theme = require( "classes.theme" )
local UI = require( "classes.ui" )

local sceneBackground
local temperatureContainer
local weatherContainer
local conditionsContainer
local almanacContainer

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
local containerWidth = 160
local containerHeight = 200
local tabletPadding = 0
local severeWeatherButtonGroup
local forecastURL 
local currentConditionsURL

-- handle events comming to the hourly conditions scrollView
local function hourlyListener( event )
    print(event.phase, event.direction)
    if "moved" == event.phase and nil == event.direction then
        --forecastScrollView:takeFocus( event )
        return true
    end
    return false
end

-- close the alerts bar
local function closeAlerts( event )
    if "ended" == event.phase then
        severeWeatherButtonGroup:removeSelf()
        severeWeatherButtonGroup = nil
    end
    return true
end

-- touch handler for the severe weather alerts bar
local function displayAlerts( event )
    if "ended" == event.phase then
        closeAlerts( event ) -- we can just use this event table to get an ended phase to closeAlerts
        composer.showOverlay( "scenes.showAlerts", { effect = "crossFade", time = 250 })
    end
    return true
end

--
-- This function does most of the actual work. It's called to populate all of the objects created in
-- scene:create()
-- If we have cached weather data then just re-populate everything. If not this will be called by the
-- network.request() to our weather API.
local function displayCurrentConditions( )
    -- Get a local reference to the recent weather data
    local response = myData.currentWeatherData

    -- show an alert if the weather isn't available
    if not response then
        native.showAlert("Oops!", "Forcast information currently not avaialble!", { "Okay" } )
        return false -- no need to try and run the rest of the function if we don't have our forecast.the
    end

    -- the data coming back from our API may have an "alerts" table if there is severe weather
    -- for the location. This block of code will create a simple red bar across the top of the screen
    -- that can be tapped to display the alerts (showAlerts.lua) in an overlay. If the user doesn't
    -- want to see them, they can simply tap the X to close the bar. TODO - it might be useful to track
    -- the time of the alerts and once the user has seen them, don't show them again. But then again, its
    -- severe weather. Knowing is good.

    -- this will use several display groups to create grid blocks so we can easily move them around if we 
    -- need to when time comes to build TV versions of the app.

    -- look for any alerts to display the alerts banner
    local alerts = response.alerts
    if alerts and #alerts > 0 then -- severe weather
        -- we have alerts, make a banner at the top of the display below the navBar to display this
        severeWeatherButtonGroup = display.newGroup()
        forecastScrollView:insert( severeWeatherButtonGroup )
        local severeWeatherButton = display.newRect(display.contentCenterX, 10, display.actualContentWidth, 20 )
        severeWeatherButton:setFillColor( 1, 0.25, 0.25 )
        severeWeatherButton.strokeWidth = 1
        severeWeatherButton:setStrokeColor( 1, 0.5, 0.5 )
        severeWeatherButtonGroup:insert( severeWeatherButton )
        local severeWeatherText = display.newText( "Severe Weather", display.contentCenterX, 10, theme.font, 14 )
        severeWeatherText:setFillColor( 1 )
        severeWeatherButtonGroup:insert( severeWeatherText )
        local closeSevereWeatherButton = display.newText( "×", display.actualContentWidth - 15, 10, theme.font, 14 )
        closeSevereWeatherButton:setFillColor( 1 )
        severeWeatherButtonGroup:insert( closeSevereWeatherButton )
        severeWeatherButtonGroup:addEventListener( "touch", displayAlerts )
        closeSevereWeatherButton:addEventListener( "touch", closeAlerts )
    end

    -- curently is a table of current conditions
    local currently = response.currently
    -- minutely is a table of the minute by minute forecase
    local minutely = response.minutely
    -- daily is a table of day to day forecasts
    local daily = response.daily
    -- hourly is able of hour to hour forecasts
    local hourly = response.hourly

    -- get the current temperature and convert it to our scale
    local temperature = "??"
    if currently.temperature then
        temperature = math.floor( wx.convertTemperature( tonumber( currently.temperature ), myData.settings.tempUnits )  + 0.5 ) 
    end
    temperatureText.text = tostring( temperature ) .. "º"

    -- calculate the forecast high and low. This is not in the currently table, so you have to get today's
    -- forecast information from the first entry in the hourly table
    local lowTemp = math.floor( wx.convertTemperature( tonumber( daily.data[1].temperatureMin ), myData.settings.tempUnits ) + 0.5 )
    local highTemp = math.floor( wx.convertTemperature( tonumber( daily.data[1].temperatureMax ), myData.settings.tempUnits ) + 0.5 )
    highText.text = "High " .. tostring( highTemp ) .. "º"
    lowText.text = "Low " .. tostring( lowTemp ) .. "º"

    -- get the wind speed informaton. Wind speed has a speed and direction
    -- for this app we will simply display a compass direction like NE 5 mph (or kph)
    local windSpeed = math.floor( wx.convertDistance( tonumber( currently.windSpeed ), myData.settings.distanceUnits ) + 0.5 )
    local bearingIndex = nil
    local windDirection
    -- Wind bearing isn't always provided (calm winds)
    if currently.windBearing then
        windDirection = tonumber( currently.windBearing )
        -- convert the wind bearing from degrees to the 16 compass points.
        bearingIndex= math.floor( ( currently.windBearing % 360 ) / 22.5 ) + 1
    end  
    -- default the prefixes to metric
    local windSpeedPrefix = "kph"
    local distancePrefix = "km"
    -- if the user has chosen US/Imperial then reset the values 
    if "miles" == myData.settings.distanceUnits then
        windSpeedPrefix = "mph"
        distancePrefix = "mi"
    end
    -- construct the actual string to display
    if bearingIndex then
        windSpeedText.text = wx.bearingLabels[ bearingIndex ] .. " " .. windSpeed .. " " .. windSpeedPrefix
    else
        windSpeedText.text = windSpeed .. " " .. windSpeedPrefix
    end

    -- atmospheric pressure
    local pressure = tonumber( currently.pressure)
    if myData.settings.pressureUnits == "inches" then
        pressure = math.floor( pressure * 0.0295301 * 100 ) / 100
    end
    local pressurePrefix = " mb"
    if myData.settings.pressureUnits == "inches" then
        pressurePrefix = " in. Hg."
    end
    pressureText.text = pressure .. pressurePrefix

    -- humidity
    local humdity = tonumber( currently.humidity * 100 )
    humidityText.text = humdity .. "% "

    -- visibility, use the same index as wind.
    local visibility = math.floor( wx.convertDistance( tonumber( currently.visibility ), myData.settings.distanceUnits ) + 0.5 )
    visibilityText.text = visibility .. distancePrefix

    -- Wind Chill/Heat Index
    local feelLike = temperature
    if currently.apparentTemperature then 
        feelsLike = math.floor( wx.convertTemperature( tonumber( currently.apparentTemperature ), myData.settings.tempUnits ) + 0.5 )
    end
    feelsLikeText.text = feelsLike .. "º"

    -- Sunrise
    local sunriseTime = response.daily.data[1].sunriseTime
    sunriseText.text = os.date( "%H:%M", sunriseTime )

    -- Sunset
    local sunsetTime = response.daily.data[1].sunsetTime
    sunsetText.text = os.date( "%H:%M", sunsetTime )

    -- Moon phase
    -- Much like we reduce the wind's 360 degree value to the 16 ordinal points on a compass, for 
    -- lunar phase, convert the 0 .. 1 floating point value to the 10 images we have for phases
    local moonPhase = response.daily.data[1].moonPhase
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
    -- generate an image for our moon phase
    local moonImage = display.newImageRect( moonImages[ moonIdx ], 25, 25 )
    moonImage.x = moonTextLabel.x + 25
    moonImage.y = moonTextLabel.y 
    almanacContainer:insert( moonImage )

    -- Dew point
    local dewPoint = math.floor( wx.convertTemperature( tonumber( currently.dewPoint ), myData.settings.tempUnits ) + 0.5 )
    dewPointText.text = dewPoint .. "º"

    -- cloud cover
    local cloudCover = currently.cloudCover
    cloudCoverText.text = tostring( math.floor( cloudCover * 100 + 0.5 ) ) .. "%"

    -- The weather icon. Create a file name from the string from the API.
    local icon = currently.icon
    local weatherIcon = display.newImageRect( "images/" .. currently.icon .. ".png", 128, 128 )
    weatherIcon.x = 80  
    weatherIcon.y = 70
    weatherContainer:insert( weatherIcon )

    --
    -- We can't postiion this text until we have the Icon loaded. We don't create the icon until we're displaying the weather.
    --
    weatherText.text = hourly.data[1].summary
    weatherText.x = weatherIcon.x
    weatherText.y = weatherIcon.y + 70
    weatherText.anchorX = 0.5

    -- 
    -- Currently we are not displaying these items
    -- But they are here in case we need to at some point
    -- 
    local ozone = currently.ozone
    -- set the current rain/snow chance
    local precipType = "??"
    local precipChance =  "??"
    if response.daily.data[1].precipProbability then
        precipChance = tostring( math.floor( tonumber( currently.precipProbability ) * 100 + 0.5 ) ) .. "%"
    end
    local nearestStormDistance = math.floor( wx.convertDistance( tonumber( currently.nearestStormDistance ), myData.settings.distanceUnits ) + 0.5 )
    local nearestStormBearing = currently.nearestStormBearing

    --
    -- This section of code will create a horizontal scrollView that shows the hourly predicted values.
    -- We will create a vertical bar graph showing the temperature. On top of the bar, we will draw the 
    -- value of the temperature. In the bottom portion of the bar and icon for the predicted conditions and
    -- precip chance.

    -- each bar will be xWidth wide
    local xWidth = 32

    -- table to hold the bars
    local temperatureBars = {}

    -- to be able to make each temperature bar, we need to know the minimum and maximum in the data set. 
    -- This first pass loop will scan through and determine those values.
    local maxPeriodTemperature = -999999
    local minPeriodTemperature = 999999
    for i = 1, #hourly.data do
        local periodTemperature = math.floor( wx.convertTemperature( tonumber( hourly.data[ i ].temperature ), "fahrenheit" ) + 0.5 )
        if periodTemperature > maxPeriodTemperature then
            maxPeriodTemperature = periodTemperature
        end
        if periodTemperature < minPeriodTemperature then
            minPeriodTemperature = periodTemperature
        end
    end

    -- now that we know min and max, compute the range
    local temperatureRange = maxPeriodTemperature - minPeriodTemperature

    -- this loop will now go create the display objects
    for i = 1, #hourly.data do
        -- get the temperate for this bar
        local periodTemperature = math.floor( wx.convertTemperature( tonumber( hourly.data[ i ].temperature ), "fahrenheit" ) + 0.5 )
        -- The bar will be X percent of the total temperature range + the minmum. Scale it by 1.25 to get more
        -- height variation
        local barHeight = periodTemperature / (temperatureRange + minPeriodTemperature) * 100 * 1.25

        -- create a rectangle, color it. It will be barHeight high and anchored so they all align on the bottom
        temperatureBars[i] = display.newRect( (i - 1) * xWidth + xWidth * 0.5, 170, xWidth - 2, barHeight)
        hourlyScrollView:insert( temperatureBars[i] )
        temperatureBars[i]:setFillColor( 0.5, 0.75, 1 )
        temperatureBars[i].anchorX = 0.5
        temperatureBars[i].anchorY = 1

        -- now show the user the actual temperature for the period and draw it above each bar.
        local hourlyTempText = display.newText( tostring( math.floor( wx.convertTemperature( tonumber( hourly.data[ i ].temperature ), myData.settings.tempUnits ) + 0.5 ) ) .. "º", temperatureBars[i].x, 130 - temperatureBars[i].height + 38, theme.font, 12 )
        hourlyTempText.anchorX = 0.5
        hourlyTempText.anchorY = 1
        hourlyTempText:setFillColor( unpack( theme.textColor ) )
        hourlyScrollView:insert( hourlyTempText )

        -- using our weather icons, draw a small version near the bottom of the temperature bar
        local icon = display.newImageRect( "images/" .. hourly.data[i].icon .. ".png", 24, 24 )
        icon.x = xWidth * ( i - 1 ) + 12
        icon.y = 145
        hourlyScrollView:insert( icon )
        -- just below the icon, draw the precipitation chance
        local precipChanceText = display.newText( tonumber( math.floor( hourly.data[i].precipProbability * 100 + 0.5) ) .. "%", icon.x, icon.y + 15, theme.font, 12 )
        precipChanceText:setFillColor( 0 )
        hourlyScrollView:insert( precipChanceText )
        -- draw the time for the forcast under each bar, but skip every other one
        if (i - 1) % 2 == 0 then
            local forecastTime = os.date( "%I%p", hourly.data[i].time )
            --
            -- remove the leading 0
            --
            if string.sub(forecastTime, 1, 1) == "0" then
                forecastTime = string.sub( forecastTime, 2 )
            end
            -- create the display object
            local forecastTimeText = display.newText( forecastTime, precipChanceText.x + 4, precipChanceText.y + 20, theme.font, 12 )
            forecastTimeText:setFillColor( unpack( theme.textColor ) )
            hourlyScrollView:insert( forecastTimeText )
        end

        -- It will be helpful to also show the user when a new day starts on the bar chart. Its a new day if 
        -- the hour is 0
        local newDay = tonumber( os.date("%H", hourly.data[i].time ) )

        if newDay == 0 then
            local newDayLine = display.newLine( precipChanceText.x - xWidth * 0.5 + 4, precipChanceText.y + 10, precipChanceText.x - xWidth * 0.5 + 4, precipChanceText.y - 150 )
            newDayLine.strokeWidth = 2
            newDayLine:setStrokeColor( 0.66 )
            hourlyScrollView:insert( newDayLine )
            local monthValue = tonumber( os.date( "%m", hourly.data[i].time ) )
            local dayValue = tonumber( os.date( "%d", hourly.data[i].time ) )
            local weekDayValue = os.date( "%a", hourly.data[i].time )
            local dayText = display.newText( weekDayValue .. "\n" .. monthValue .. "/" .. dayValue, newDayLine.x + 55 , precipChanceText.y - 140, 100, 0, theme.fontBold, 12 )
            hourlyScrollView:insert( dayText )
            dayText:setFillColor( unpack( theme.textColor ) )
        end

    end

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
            -- refresh the weather
            -- bust the cache time
            myData.lastRefresh = 0
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

    -- since we are going to support switching themes, we need to have this forward declared
    sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    sceneGroup:insert( sceneBackground )

    -- A scrollView will hold all the actual display bits
    local scrollViewHeight = display.actualContentHeight - 100
    -- Create the widget
    forecastScrollView = widget.newScrollView
    {
        top = 30 + display.topStatusBarContentHeight,
        left = 0,
        width = display.actualContentWidth,
        height = scrollViewHeight,
        scrollWidth = display.actualContentWidth,
        scrollHeight = 1800,
        hideBackground = true,
        horizontalScrollDisabled = true,
        bottomPadding = 25,
        listener = scrollListener
    }
    sceneGroup:insert( forecastScrollView )


    -- to support multiple layouts, break the display into containers 
    -- we won't have actual values to display yet, but we want to get the objects
    -- created

    --
    -- **** Temperature ****
    --
    -- set a block on the screen to hold the temperature data (current, high, low)
    temperatureContainer = display.newContainer( containerWidth, containerHeight )
    temperatureContainer.anchorX = 0
    temperatureContainer.anchorY = 0
    temperatureContainer.anchorChildren = false

    forecastScrollView:insert( temperatureContainer )
    temperatureText = display.newText("" .. "º", 75, 75, theme.font, 80 )
    temperatureText:setFillColor( 0.33, 0.66, 0.99 )
    temperatureContainer:insert( temperatureText )

    highText = display.newText("", temperatureText.x - 40, temperatureText.y + 70, theme.font, 18)
    temperatureContainer:insert( highText )
    highText.anchorX = 0.5

    lowText = display.newText("", temperatureText.x + 40, temperatureText.y + 70, theme.font, 18)
    temperatureContainer:insert( lowText )
    lowText.anchorX = 0.5

    --
    -- **** Current Weather ****
    --
    -- continer to eventually hold our icon and the description of the weather
    weatherContainer = display.newContainer( containerWidth, containerHeight )
    weatherContainer.anchorX = 0
    weatherContainer.anchorY = 0
    weatherContainer.anchorChildren = false

    forecastScrollView:insert( weatherContainer )
    weatherText = display.newText("", containerWidth * 0.5, 180, theme.font, 18 )
    weatherContainer:insert( weatherText )

    --
    -- **** Other conditions ****
    --

    conditionsContainer = display.newContainer( containerWidth, containerHeight )
    conditionsContainer.anchorX = 0
    conditionsContainer.anchorY = 0
    conditionsContainer.anchorChildren = false
    forecastScrollView:insert( conditionsContainer )

    windSpeedLabel = display.newText( "Winds", 65, 12, theme.font, 14 )
    windSpeedLabel.anchorX = 1
    conditionsContainer:insert( windSpeedLabel )
    windSpeedText = display.newText( "", 70, windSpeedLabel.y , theme.fontBold, 14 )
    windSpeedText.anchorX = 0
    conditionsContainer:insert( windSpeedText )

    visibilityLabel = display.newText( "Visibility", 65, windSpeedText.y + 24, theme.font, 14 )
    visibilityLabel.anchorX = 1
    conditionsContainer:insert( visibilityLabel )
    visibilityText = display.newText( "", 70, visibilityLabel.y, theme.fontBold, 14 )
    visibilityText.anchorX = 0
    conditionsContainer:insert( visibilityText )

    pressureLabel = display.newText( "Pressure", 65, visibilityLabel.y + 24, theme.font, 14 )
    pressureLabel.anchorX = 1
    conditionsContainer:insert( pressureLabel )
    pressureText = display.newText( "", 70, pressureLabel.y, theme.fontBold, 14 )
    pressureText.anchorX = 0
    conditionsContainer:insert( pressureText )

    humidityLabel = display.newText( "Humidity", 65, pressureLabel.y + 24, theme.font, 14 )
    humidityLabel.anchorX = 1
    conditionsContainer:insert( humidityLabel )
    humidityText = display.newText( "", 70, humidityLabel.y, theme.fontBold, 14 )
    humidityText.anchorX = 0
    conditionsContainer:insert( humidityText )

    feelsLikeLabel = display.newText( "Feels like", 65, humidityLabel.y + 24, theme.font, 14 )
    feelsLikeLabel.anchorX = 1
    conditionsContainer:insert( feelsLikeLabel )
    feelsLikeText = display.newText( "", 70, feelsLikeLabel.y, theme.fontBold, 14 )
    feelsLikeText.anchorX = 0
    conditionsContainer:insert( feelsLikeText )

    --
    -- **** Alamanc things ****
    --

    almanacContainer = display.newContainer( containerWidth, containerHeight )
    almanacContainer.anchorX = 0
    almanacContainer.anchorY = 0
    almanacContainer.anchorChildren = false
    forecastScrollView:insert( almanacContainer )
    sunriseTextLabel = display.newText( "Sunrise", 80, 12, theme.font, 14 )    
    sunriseTextLabel.anchorX = 1
    almanacContainer:insert( sunriseTextLabel )
    sunriseText = display.newText( "", 90, sunriseTextLabel.y, theme.fontBold, 14 )
    sunriseText:setFillColor( unpack( theme.textColor ) )
    sunriseText.anchorX = 0
    almanacContainer:insert( sunriseText )

    sunsetTextLabel = display.newText( "Sunset", 80, sunriseText.y + 24, theme.font, 14 )
    sunsetTextLabel.anchorX = 1
    almanacContainer:insert( sunsetTextLabel )
    sunsetText = display.newText( "", 90, sunsetTextLabel.y, theme.fontBold, 14 )
    sunsetText.anchorX = 0
    almanacContainer:insert( sunsetText )

    moonTextLabel = display.newText( "Moon phase", 80, sunsetTextLabel.y + 24, theme.font, 14 )
    moonTextLabel.anchorX = 1
    almanacContainer:insert( moonTextLabel )
    moonText = display.newText( "", 90, moonTextLabel.y, theme.fontBold, 14 )
    moonText.anchorX = 0
    almanacContainer:insert( moonText )

    cloudCoverTextLabel = display.newText( "Cloud Cover", 80, moonTextLabel.y + 24, theme.font, 14 )
    cloudCoverTextLabel.anchorX = 1
    almanacContainer:insert( cloudCoverTextLabel )
    cloudCoverText = display.newText( "", 90, cloudCoverTextLabel.y, theme.fontBold, 14 )
    cloudCoverText.anchorX = 0
    almanacContainer:insert( cloudCoverText )

    dewPointTextLabel = display.newText( "DewPoint", 80, cloudCoverTextLabel.y + 24, theme.font, 14 )
    dewPointTextLabel.anchorX = 1
    almanacContainer:insert( dewPointTextLabel )
    dewPointText = display.newText( "", 90, dewPointTextLabel.y, theme.fontBold, 14 )
    dewPointText.anchorX = 0
    almanacContainer:insert( dewPointText )

    hourlyScrollView = widget.newScrollView
    {
        width = display.actualContentWidth,
        height = 200,
        scrollWidth = display.actualContentWidth * 2,
        scrollHeight = 200,
        hideBackground = true, 
        isBounceEnabled = false,
        verticalScrollDisabled = true,
        listener = hourlyListener
    }
    forecastScrollView:insert( hourlyScrollView )

end

function scene:show( event )
    local sceneGroup = self.view

    local latitude = myData.latitude
    local longitude = myData.longitude

    if event.phase == "will" then
        -- we will do a lot of filling in the blanks and repositioing of items here
        -- based on orientation 

        -- Set the navBar label to the current location's default value
        UI.navBar:setLabel( myData.settings.locations[1].name )
        for i = 1, #myData.settings.locations do
            -- loop over our saved locations looking for one that's mark selected
            -- if we find one display that instead
            if myData.settings.locations[i].selected then
                UI.navBar:setLabel( myData.settings.locations[i].name )
                break
            end
        end

        -- if we are portrait oriented (mobile devices) then organize content
        -- to fit the vertical screen
        if display.actualContentWidth < display.actualContentHeight then -- portrait orientation
            -- if we are on a tablet, we need to spread somethings out a bit
            local tabletPadding = 0
            if display.actualContentWidth >= 600 then -- must be a tablet
                tabletPadding = 30
            end
            local quarterWidth = display.actualContentWidth * 0.25
            temperatureContainer.x = 10
            temperatureContainer.y = 10 + tabletPadding
            weatherContainer.x = quarterWidth * 2
            weatherContainer.y = 10 + tabletPadding
            hourlyScrollView.x = display.contentCenterX
            hourlyScrollView.y = 280 + tabletPadding
            conditionsContainer.x = 10
            conditionsContainer.y = 400 + tabletPadding
            almanacContainer.x = quarterWidth * 2 + 10
            almanacContainer.y = 400 + tabletPadding
        else
            -- If we are landscape draw things differently
            local tabletPadding = 0
            if display.actualContentWidth >= 600 then 
                tabletPadding = 30
            end
            local quarterWidth = display.actualContentWidth * 0.25
            temperatureContainer.x = 10
            temperatureContainer.y = 10 + tabletPadding
            weatherContainer.x = quarterWidth + 10
            weatherContainer.y = 10 + tabletPadding
            hourlyScrollView.x = display.contentCenterX
            hourlyScrollView.y = 280 + tabletPadding
            conditionsContainer.x = quarterWidth * 2 + 10
            conditionsContainer.y = 30 + tabletPadding
            almanacContainer.x = quarterWidth * 3 + 10
            almanacContainer.y = 30 + tabletPadding
        end

        -- apply the theme colors to everything
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

        -- check the time! if the current time is less than 15 minutes from the last
        -- weather update, just display the currently cached weather. If it's been more
        -- than 15 minutes fetch a new forecast. The user can always force a new update
        -- by pulling down on the scrollView
        local now = os.time()
        if now > myData.lastRefresh + (15 * 60) then
            wx.fetchWeather( displayCurrentConditions )
        else
            displayCurrentConditions()
        end
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
