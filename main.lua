local composer = require( "composer" )
local widget = require( "widget" )
local widgetExtras = require( "widget-extras" )
local utility = require( "utility" )
local myData = require( "mydata" )
local device = require( "device" )
local theme = require( "theme" )

display.setStatusBar( display.HiddenStatusBar )

Runtime:setCheckGlobals( true )
math.randomseed( os.time() )

myData.wuAPIkey = "63786a2636b67f31"
myData.forecastIOkey = "5e07c45fcc74c5997d832a4ee792031e"
myData.mapquestKey = "66w5YMUHLoYIETPddFEAyUAghVHMPXNL"
myData.mapquestSecret = "yWGInvQLF72wjtcx"
myData.openWeatherMapAppId = "8e6c844a847a4cbd4fd889039044f704"
myData.bingMapKey = "AlNVpu8Z01qBfva8DhkrUg0WdxzdB3eeOdoO5TxHXRAmovpl5M_qQsda-zqqdzq8"
myData.lastRefresh = 0 -- force a download the first time.
myData.latitude = 35.7789
myData.longitude = -78.8003
myData.platform = "iOS"
myData.gps = {}

if "simulator" == system.getInfo("environment") and "iP" ~= string.sub( system.getInfo("model"), 1, 2 ) then
    myData.platform = "Android"
elseif "device" == system.getInfo("environment") and "Android" == system.getInfo("platformName" ) then
    myData.platform = "Android"
end

if "iOS" == myData.platform then
    display.setStatusBar( display.DefaultStatusBar )
end

if "Android" == myData.platform then
    widget.setTheme( "widget_theme_android_holo_dark" )
    theme.setTheme( "dark" )
    myData.platform = "Android"
end
--
-- Load saved in settings
--
myData.settings = utility.loadTable("settings.json")
if myData.settings == nil then
	myData.settings = {}
	myData.settings.soundOn = true
	myData.settings.musicOn = true
    myData.settings.isPaid = false
    myData.settings.showIcons = false
    myData.settings.theme = "light"
    myData.settings.tempUnits = "fahrenheit" -- fahrenheit or celsius
    myData.settings.distanceUnits = "miles" -- miles or kilometers
    myData.settings.locations = { { name = "Cary, NC", latitude = 35.7789, longitude = -78.8003, postalCode = "27519", selected = true },
                                  { name = "Palo Alto, CA", latitude = 37.4419, longitude = -122.1430, postalCode = "94303", selected = false },
                                  { name = "Austin, TX", latitude = 30.2672, longitude = -97.7431, postalCode = "78701", selected = false }
                                }
    myData.settings.lookUpBy = "city" -- zipcode, latlong, city
	utility.saveTable(myData.settings, "settings.json")
    myData.firstTime = true
end

--
-- Set up the navBar controller
--
local function leftButtonEvent( event )
    if event.phase == "ended" then
        local currScene = composer.getSceneName( "overlay" )
        if currScene then
            composer.hideOverlay( "fromRight", 500 )
        else
            composer.showOverlay( "menu", { isModal=true, time=500, effect="fromLeft" } )
        end
    end
    return true
end

local leftButton = {
    width = 25,
    height = 25,
    defaultFile = "images/hamburger.png",
    overFile = "images/hamburger.png",
    onEvent = leftButtonEvent,
}

local includeStatusBar = false
if "iOS" == myData.platform then
    includeStatusBar = true
end

myData.navBar = widget.newNavigationBar({
    isTransluscent = false,
    backgroundColor = theme.navBarBackgroundColor,
    title = myData.currentLocation, 
    titleColor = theme.navBarTextColor,
    font = theme.fontBold,
    height = 50,
    includeStatusBar = includeStatusBar,
    leftButton = leftButton
})

--
-- Set up the tabBar controller
--
local tabBar

local function showWeather()
    if myData.platform == "iOS" then
        tabBar:setSelected(1)
    end
    composer.gotoScene("currentConditions", {time=250, effect="crossFade"})
    return true
end

local function showForecast()
    tabBar:setSelected(2)
    composer.gotoScene("forecast", {time=250, effect="crossFade"})
    return true
end

local function showLocations()
    tabBar:setSelected(3)
    composer.gotoScene("locations", {time=250, effect="crossFade"})
    return true
end

local function showSettings( event )
    tabBar:setSelected(4)
    composer.gotoScene("appsettings", {time=250, effect="crossFade"})
    return true
end

local tabButtons = {
    {
        label = "Current Weather",
        defaultFile = "images/weather_default.png",
        overFile = "images/weather_selected.png",
        labelColor = { 
            default = { 0.25, 0.25, 0.25 }, 
            over = { 0.08, 0.49, 0.98 }
        },
        width = 32,
        height = 32,
        onPress = showWeather,
        selected = true,
        id = "weather"
    },
    {
        label = "Forecast",
        defaultFile = "images/forecast.png",
        overFile = "images/forecast_selected.png",
        labelColor = { 
            default = { 0.25, 0.25, 0.25 }, 
            over = { 0.08, 0.49, 0.98 }
        },
        width = 32,
        height = 32,
        onPress = showForecast,
        id = "forecast"
    },
    {
        label = "Locations",
        defaultFile = "images/locations.png",
        overFile = "images/locations_selected.png",
        labelColor = { 
            default = { 0.25, 0.25, 0.25 }, 
            over = { 0.08, 0.49, 0.98 }
        },
        width = 32,
        height = 32,
        onPress = showLocations,
        id = "location"
    },

    {
        label = "Settings",
        defaultFile = "images/settings_default.png",
        overFile = "images/settings_selected.png",
        labelColor = { 
            default = { 0.25, 0.25, 0.25 }, 
            over = { 0.08, 0.49, 0.98 }
        },
        width = 32,
        height = 32,
        onPress = showSettings,
        id = "settings"
    },
}

if myData.platform == "iOS" then
    tabBar = widget.newTabBar{
        top =  display.contentHeight - 50,
        left = 0,
        width = display.contentWidth,    
        buttons = tabButtons,
        height = 50,
    }
end

--
-- Other system events
--
local function onKeyEvent( event )

    local phase = event.phase
    local keyName = event.keyName
    print( event.phase, event.keyName )

    if ( "back" == keyName and phase == "up" ) then
        native.requestExit()
        return true
    end
    return false
end

--add the key callback
if device.isAndroid then
    Runtime:addEventListener( "key", onKeyEvent )
end

local locationHandler = function( event )

    -- Check for error (user may have turned off location services)
    if ( event.errorCode ) then
        --native.showAlert( "GPS Location Error", event.errorMessage, {"OK"} )
        print( "Location error: " .. tostring( event.errorMessage ) )
    else
        myData.gps.latitude = event.latitude
        myData.gps.longitude = event.longitude
    end
end

-- Activate location listener


--
-- handle system events
--
local function systemEvents(event)
    print("systemEvent " .. event.type)
    if event.type == "applicationSuspend" then
        Runtime:removeEventListener( "location", locationHandler )
        utility.saveTable( myData.settings, "settings.json" )
    elseif event.type == "applicationResume" then
        Runtime:addEventListener( "location", locationHandler )
        showWeather()
    elseif event.type == "applicationExit" then
        Runtime:removeEventListener( "location", locationHandler )
        utility.saveTable( myData.settings, "settings.json" )
    elseif event.type == "applicationStart" then
        Runtime:addEventListener( "location", locationHandler )
        showWeather()
    end
    return true
end
Runtime:addEventListener("system", systemEvents)
