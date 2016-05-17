--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- ui.lua -- User Interface module. We need access to our navBar and tabBar's in other modules
-- to be able to change their skin.
--

local composer = require( "composer" )
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

local UI = {} -- create the base object for the UI

--
-- Set up the navBar controller's hamburger icon
-- The navBar controller needs a button object and a handler function
-- for it. If the menu is showing, hide it, if its hidden show it.
--
local function leftButtonEvent( event )
    if event.phase == "ended" then
        local currScene = composer.getSceneName( "overlay" )
        if currScene then
            composer.hideOverlay( "fromRight", 500 )
        else
            composer.showOverlay( "scenes.menu", { isModal=true, time=500, effect="fromLeft" } )
        end
    end
    return true
end

function UI.createNavBar()
    if UI.navBar then
        UI.navBar:removeSelf()
        UI.navBar = nil
    end

    local leftButton = {
        width = 25,
        height = 25,
        defaultFile = "images/hamburger-" .. theme.name .. ".png",
        overFile = "images/hamburger-" .. theme.name .. ".png",
        onEvent = leftButtonEvent,
    }
    if myData.platform == "iOS" then
        leftButton = nil
    end

    if theme.name == "light" then
        display.setStatusBar( display.DefaultStatusBar )
    else
        display.setStatusBar( display.TranslucentStatusBar )
    end

    UI.navBar = widget.newNavigationBar({
        isTransluscent = false,
        backgroundColor = theme.navBarBackgroundColor,
        title = myData.currentLocation, 
        titleColor = theme.navBarTextColor,
        font = theme.fontBold,
        height = 50,
        includeStatusBar = true,
        leftButton = leftButton
    })
end


function UI.showWeather()
    if UI.tabBar then
        UI.tabBar:setSelected(1)
    end
    composer.gotoScene("scenes.currentConditions", {time=250, effect="crossFade"})
    --composer.gotoScene("radar", {time=250, effect="crossFade"})
    return true
end

function UI.showForecast()
    if UI.tabBar then
        UI.tabBar:setSelected(2)
    end
    composer.gotoScene("scenes.forecast", {time=250, effect="crossFade"})
    return true
end

function UI.showLocations()
    if UI.tabBar then
        UI.tabBar:setSelected(3)
    end
    composer.gotoScene("scenes.locations", {time=250, effect="crossFade"})
    return true
end

function UI.showSettings( event )
    if UI.tabBar then
        UI.tabBar:setSelected(4)
    end
    composer.gotoScene("scenes.appsettings", {time=250, effect="crossFade"})
    return true
end

local options =  {
    frames =
    {
        { x = 0,  y = 0, width = 10, height = 50 },
        { x = 10, y = 0, width = 10, height = 50 },
        { x = 20, y = 0, width = 10, height = 50 },
        { x = 30, y = 0, width = 10, height = 50 }
    },
    sheetContentWidth = 40,
    sheetContentHeight = 50
}

function UI.createTabBar()
    --
    -- Set up the tabBar controller
    -- since the app supports themeing, we will need access to the tabBar to try and 
    -- change colors
    --
    if UI.tabBar then
        UI.tabBar:removeSelf()
        UI.tabBar = nil
    end

    if myData.platform == "iOS" then

        local tabButtons = {
            {
                label = "Current Weather",
                defaultFile = "images/weather_default.png",
                overFile = "images/weather_selected.png",
                labelColor = { 
                    default = { 0.5, 0.5, 0.5 }, 
                    over = { 0.08, 0.49, 0.98 }
                },
                width = 32,
                height = 32,
                onPress = UI.showWeather,
                selected = true,
                id = "weather"
            },
            {
                label = "Forecast",
                defaultFile = "images/forecast.png",
                overFile = "images/forecast_selected.png",
                labelColor = { 
                    default = { 0.5, 0.5, 0.5 }, 
                    over = { 0.08, 0.49, 0.98 }
                },
                width = 32,
                height = 32,
                onPress = UI.showForecast,
                id = "forecast"
            },
            {
                label = "Locations",
                defaultFile = "images/locations.png",
                overFile = "images/locations_selected.png",
                labelColor = { 
                    default = { 0.5, 0.5, 0.5 }, 
                    over = { 0.08, 0.49, 0.98 }
                },
                width = 32,
                height = 32,
                onPress = UI.showLocations,
                id = "location"
            },

            {
                label = "Settings",
                defaultFile = "images/settings_default.png",
                overFile = "images/settings_selected.png",
                labelColor = { 
                    default = { 0.5, 0.5, 0.5 }, 
                    over = { 0.08, 0.49, 0.98 }
                },
                width = 32,
                height = 32,
                onPress = UI.showSettings,
                id = "settings"
            },
        }

        local tabBarImageSheet
        if theme.name == "light" then
            tabBarImageSheet = graphics.newImageSheet( "images/tabbarbg-light.png", options )
        else
            tabBarImageSheet = graphics.newImageSheet( "images/tabbarbg-dark.png", options )
        end
        print( theme.name )
        UI.tabBar = widget.newTabBar{
            top =  display.contentHeight - 50,
            left = 0,
            width = display.contentWidth,    
            buttons = tabButtons,
            sheet = tabBarImageSheet,
            backgroundFrame = 1,
            tabSelectedLeftFrame = 2,
            tabSelectedMiddleFrame = 3,
            tabSelectedRightFrame = 4,
            tabSelectedFrameWidth = 10,
            tabSelectedFrameHeight = 50,
            height = 50,
        }
    end
end

return UI
