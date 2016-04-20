--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- main.lua -- main entry point
--
local composer = require( "composer" )
local widget = require( "widget" )

--
-- widgetExtras -- holds some custom built widgets from Corona SDK tutorials
--
local widgetExtras = require( "widget-extras" )
--
-- utility - various handy add on functions
--
local utility = require( "utility" )
--
-- myData -- an emtpy table that can be required in multiple modules/scenes
--           to allow easy passing of data between modules
local myData = require( "mydata" )
--
-- theme -- a data table of colors and font attributes to quickly change
--          how the app looks
--
local theme = require( "theme" )
local UI = require( "ui" )

--
-- any globals will show up as warnings in the console log. Need a global? Use myData!
--
Runtime:setCheckGlobals( true )

--
-- Store our API keys for scenes that need them
--
myData.forecastIOkey = "5e07c45fcc74c5997d832a4ee792031e"
myData.mapquestKey = "66w5YMUHLoYIETPddFEAyUAghVHMPXNL"
myData.mapquestSecret = "yWGInvQLF72wjtcx"
myData.bingMapKey = "AlNVpu8Z01qBfva8DhkrUg0WdxzdB3eeOdoO5TxHXRAmovpl5M_qQsda-zqqdzq8"
-- Keep the weather API from updating too often, initialize to 0
myData.lastRefresh = 0 -- force a download the first time.
-- Once we detect our device/platform record it here when device decisions need to be made
myData.platform = "iOS"

--
-- Detect the device we are on
-- This is important because we are going to present a different UI based on the device. 
-- iOS devices will have a tabBar controller at the bottom. Android will have a hamburger that will slide in
-- a menu for instance.
if "simulator" == system.getInfo("environment") and "iP" ~= string.sub( system.getInfo("model"), 1, 2 ) then
    myData.platform = "Android"
elseif "device" == system.getInfo("environment") and "Android" == system.getInfo("platformName" ) then
    myData.platform = "Android"
end

display.setStatusBar( display.DefaultStatusBar )

if "Android" == myData.platform then
    -- Select the right widget theme for Android
    widget.setTheme( "widget_theme_android_holo_dark" )
end
--
-- Load saved in settings
-- Function to load and save tables is in the utility.lua file
--
myData.settings = utility.loadTable("settings.json")
-- If we fail to load the table, this must be a first run, or an install after a delete
-- so setup up reasonable defaults
if myData.settings == nil then
	myData.settings = {}
    myData.settings.theme = "light"
    if "Android" == myData.platform then
        myData.settings.theme = "dark"
    end
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

-- Set the theme to the user's choice or a reasonable first run default
theme.setTheme( myData.settings.theme )
-- Setup a reasonable default GPS location. The forecastIO API uses lat, long
if #myData.settings.locations > 0 then
    for i = 1, #myData.settings.locations do
        myData.currentLocation = nil
        if myData.settings.locations[i].selected then
            myData.currentLocation = myData.settings.locations[i].name
            myData.latitude = myData.settings.locations[i].latitude
            myData.longitude = myData.settings.locations[i].longitude
        end
        if myData.currentLocation == nil then
            myData.currentLocation = myData.settings.locations[1].name
            myData.latitude = myData.settings.locations[1].latitude
            myData.longitude = myData.settings.locations[1].longitude
        end
    end
else
    myData.currentLocation = "Palo Alto, CA"
    myData.latitude = 37.4419
    myData.longitude = -122.1430
end
--
-- Set up the navBar controller's hamburger icon
-- The navBar controller needs a button object and a handler function
-- for it. If the menu is showing, hide it, if its hidden show it.
--
UI.createNavBar()
if myData.platform == "iOS" then
    UI.createTabBar()
end

--
-- Set up the tabBar controller
-- since the app supports themeing, we will need access to the tabBar to try and 
-- change colors
--

--
-- Other system events
--
local function onKeyEvent( event )

    local phase = event.phase
    local keyName = event.keyName
    print( event.phase, event.keyName )

    if ( "back" == keyName and "up" == phase ) then
        native.requestExit()
        return true
    end
    return false
end

--add the key callback
if "Android" == myData.platform then
    Runtime:addEventListener( "key", onKeyEvent )
end

--
-- handle system events
--
local function systemEvents(event)
    print("systemEvent " .. event.type)
    if event.type == "applicationSuspend" then
        utility.saveTable( myData.settings, "settings.json" )
    elseif event.type == "applicationResume" then
        UI.showWeather()
    elseif event.type == "applicationExit" then
        utility.saveTable( myData.settings, "settings.json" )
    elseif event.type == "applicationStart" then
        UI.showWeather()
    end
    return true
end
Runtime:addEventListener("system", systemEvents)
