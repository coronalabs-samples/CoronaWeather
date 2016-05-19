--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- main.lua -- main entry point
--
-- The main source of data is Forecast.io's RESTful API. You will need to register with them and get your
-- own API key.
-- Location data comes from geonames.com and their text file was stripped down to the minimum values and 
-- inserted into an SQLite3 database. Location data is huge and not practical to download. Geocoding API's
-- require network access and are usually rate limited.

-- system includes
local composer = require( "composer" )
--composer.recycleOnSceneChange = true

local widget = require( "widget" )

--
-- widgetExtras -- holds some custom built widgets from Corona SDK tutorials
--
local widgetExtras = require( "libs.widget-extras" )
--
-- utility - various handy add on functions
--
local utility = require( "libs.utility" )
--
-- myData -- an emtpy table that can be required in multiple modules/scenes
--           to allow easy passing of data between modules
local myData = require( "classes.mydata" )
--
-- theme -- a data table of colors and font attributes to quickly change
--          how the app looks
--
local theme = require( "classes.theme" )
--
-- functions to setup the navigation bar at the top and the tabBar at the bottom
local UI = require( "classes.ui" )

--
-- Store our API keys for scenes that need them
--
myData.forecastIOkey = "5e07c45fcc74c5997d832a4ee792031e"
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
--Runtime:setCheckGlobals( true )
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
--
-- In production you would also have a version number stored and if you find an older version
-- you can include code to update the users settings with the new required features.
-- But we will keep it simple for now.
if myData.settings == nil then
	myData.settings = {}
    myData.settings.firstTime = true
    myData.settings.theme = "light"
    if "Android" == myData.platform then
        myData.settings.theme = "dark"
    end
    myData.settings.tempUnits = "fahrenheit" -- fahrenheit or celsius
    myData.settings.distanceUnits = "miles" -- miles or kilometers
    myData.settings.locations = {   { name = "Current Location", latitude = 0, longitude = 0, selected = true, noDelete = true },
                                    { name = "Cary, NC", latitude = 35.7789, longitude = -78.8003, postalCode = "27519", selected = false },
                                    { name = "Palo Alto, CA", latitude = 37.4419, longitude = -122.1430, postalCode = "94303", selected = false },
                                    { name = "Austin, TX", latitude = 30.2672, longitude = -97.7431, postalCode = "78701", selected = false }
                                }
	utility.saveTable(myData.settings, "settings.json")
end

-- Set the theme to the user's choice or a reasonable first run default
theme.setTheme( myData.settings.theme )
-- Setup a reasonable default GPS location. The forecastIO API uses lat, long
if #myData.settings.locations > 0 then
    myData.currentLocation = nil
    for i = 1, #myData.settings.locations do
        if myData.settings.locations[i].selected then
            myData.currentLocation = myData.settings.locations[i].name
            myData.latitude = myData.settings.locations[i].latitude
            myData.longitude = myData.settings.locations[i].longitude
        end
    end
    -- if we get here and myData.currentLocation is still nil, there wasn't a selected entry in the list
    -- The first items should be "Current Location", so grab that default data
    if myData.currentLocation == nil then
        myData.currentLocation = myData.settings.locations[1].name
        myData.latitude = myData.settings.locations[1].latitude
        myData.longitude = myData.settings.locations[1].longitude
    end
else
    -- No data at all? Gotta start somewhere. PA seems like a nice place.
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
-- Enable location services to populate a default location
--
local locationServicesHandler = function( event )
    -- Check for error (user may have turned off location services)
    if ( event.errorCode ) then
        --native.showAlert( "GPS Location Error", event.errorMessage, {"OK"} )
        print( "Location error: " .. tostring( event.errorMessage ) )
    else
        myData.settings.locations[1].latitude = event.latitude
        myData.settings.locations[1].longitude = event.longitude
    end
end

Runtime:addEventListener( "location", locationServicesHandler )

--
-- Other system events
--
-- There really are not any scenes to go back to, 
local function onKeyEvent( event )

    local phase = event.phase
    local keyName = event.keyName
    print( event.phase, event.keyName )

    if ( "back" == keyName and "up" == phase ) then
        local currentScene = composer.getSceneName( "overlay" )
        if currentScene then
            composer.hideOverlay( "slideRight", 250 )
        else
            native.requestExit()
        end
        -- we handled the key event, return true
        return true
    end
    -- we did not handle the key event, let the system know it has to deal with it
    return false
end

-- add the key callback
-- For now, we only need this for Android. If this gets setup for other platforms, then
-- we can add keyboard short cuts for Windows and OS X and controller support for Apple
-- and Android TV
if "Android" == myData.platform then
    Runtime:addEventListener( "key", onKeyEvent )
end

--
-- handle system events
--
-- If we get suspended or exited, make sure to safe our data
-- This is a redundant protection because we should be saving our data every time
-- we update it except for location changes and using the GPS to determine location
--
-- On start up or resume, just to the current Conditions page.
--
local function systemEvents(event)
    print("systemEvent " .. event.type)
    if event.type == "applicationSuspend" then
        utility.saveTable( myData.settings, "settings.json" )
        if myData.db then
            myData.db:close()
        end
    elseif event.type == "applicationResume" then
        UI.showWeather()
    elseif event.type == "applicationExit" then
        utility.saveTable( myData.settings, "settings.json" )
    elseif event.type == "applicationStart" then
        if myData.settings.firstTime then
            myData.settings.firstTime = false
            utility.saveTable(myData.settings, "settings.json")
            UI.showLocations()
        else
            UI.showWeather()
        end
    end
    return true
end
Runtime:addEventListener("system", systemEvents)
