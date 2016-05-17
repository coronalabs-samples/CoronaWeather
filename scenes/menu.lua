--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- menu.lua --  Android devices tend to use menus that slide in when tappng on an hamburger icon
--              instead of iOS where a tabBar controller manages changing scenes. In the UI setup
--              a button has been added that when tapped will cause this sceen to slide in from the
--              left to give the user an opportunity to change scenes. 
--
--              There is one gotcha though. The Location selection scene has a native.newTextField()
--              visible and the menu wants to slide behind it. We have to hide that text field before
--              showing the menu.
--

-- system includes
local composer = require( "composer" )
local scene = composer.newScene()
local widget = require( "widget" )

-- our includes
local utility = require( "libs.utility" )
local myData = require( "classes.mydata" )

-- function to hide the menu
local function closeMenu( event )
    if event.phase == "ended" then
        composer.hideOverlay( false, "fromLeft", 500 )
    end
    return true
end

-- function to change scenes to the current conditions scene
local function goConditions( event )
    if event.phase == "ended" then
        composer.gotoScene( "currentConditions", { time=500, effect="slideRight" } )
    end
    return true
end

-- function to change scenes to the forecast scene
local function goForecast( event )
    if event.phase == "ended" then
        composer.gotoScene( "forecast", { time=500, effect="slideRight" } )
    end
    return true
end

-- funciton to change to the location entry scene
local function goLocations( event )
    if event.phase == "ended" then
        composer.gotoScene( "locations", { time=500, effect="slideRight" } )
    end
    return true
end

-- go to the app settings scene
local function goSettings( event )
    if event.phase == "ended" then
        composer.gotoScene( "appsettings", { time=500, effect="slideRight" } )
    end
    return true
end

-- This function will make a single text button with an icon and return it as it's own group.
-- We will be making several of these, no need to repeat ourselves (DRY)
local function makeMenuItem(text, iconFile, width, height, font, fontSize, handler)
    -- we will use a groupt to contain the text and icon as one item.
    local buttonGroup = display.newGroup()
    -- create the icon
    local icon = display.newImageRect( iconFile, width, height )
    buttonGroup:insert( icon )
    icon.x = 20
    icon.y = 15
    -- create the text
    local buttonText = display.newText( text, icon.x + 20, icon.y, font, fontSize)
    buttonText:setFillColor( 0 )
    buttonText.anchorX = 0
    buttonGroup:insert( buttonText )
    -- Add a touch handler to the group.
    buttonGroup:addEventListener( "touch", handler )

    -- return the group back to the caller
    return buttonGroup
end

--
-- Start the composer event handlers
--
function scene:create( event )
    local sceneGroup = self.view
        
    --
    -- setup a page background, really not that important though composer
    -- crashes out if there isn't a display object in the view.
    --
    -- create a semi-transparent background for the whole screen.
    local background = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    background:setFillColor( 0, 0, 0, 0.66 )
    sceneGroup:insert( background )
    -- allow touches on the background to also close the menu.
    background:addEventListener( "touch", closeMenu )

    -- make a white backgrounded menu background that is 40% of the width of the screen. 
    -- Positioning it at 20% of the width will anchor it to the left side.
    local menuBackground = display.newRect(display.actualContentWidth * 0.2, display.contentCenterY, display.actualContentWidth * 0.4, display.actualContentHeight )
    menuBackground:setFillColor( 1, 1, 1, 1)
    sceneGroup:insert( menuBackground )

    -- make the buttons
    local currentConditionsButton = makeMenuItem( "Current Conditions", "images/temperature.png", 24, 24, myData.font, 12, goConditions )
    sceneGroup:insert( currentConditionsButton )
    currentConditionsButton.anchorX = 0
    currentConditionsButton.x = 0
    currentConditionsButton.y = 70

    -- each button is positioned relative to the one before it. That way if you need to resposition one, the rest follow
    local forecastButton = makeMenuItem( "Forecast", "images/forecast.png", 24, 24, myData.font, 12, goForecast )
    sceneGroup:insert( forecastButton )
    forecastButton.anchorX = 0
    forecastButton.x = 0
    forecastButton.y = currentConditionsButton.y + 35

    local locationButton = makeMenuItem( "Locations", "images/locations.png", 24, 24, myData.font, 12, goLocations )
    sceneGroup:insert( locationButton )
    locationButton.anchorX = 0
    locationButton.x = 0
    locationButton.y = forecastButton.y + 35

    local settingsButton = makeMenuItem( "Settings", "images/android_settings.png", 24, 24, myData.font, 12, goSettings )
    sceneGroup:insert( settingsButton )
    settingsButton.anchorX = 0
    settingsButton.x = 0
    settingsButton.y = locationButton.y + 35


end

function scene:show( event )
    local sceneGroup = self.view

    --
    -- If my parent scene is the location scene, the text field is on top of everything, so we need to hide it to show the menu
    --
    -- The location scene has a function declared named scene.hideTextField() that simply sets the visibility of the
    -- native.newTextField() to invisible and another to show it. In this case, event.parent is the parent scene of this
    -- overlay. If we see that there is a defined function to hide the text field. If we ever add text fields to other scenes
    -- we can just add the function hideTextField() to that scene's object and this will take care of hiding it.
    if event.phase == "will" then
        if event.parent.hideTextField then
            event.parent.hideTextField()
        end
    end
end

function scene:hide( event )
    local sceneGroup = self.view

    --
    -- If my parent scene is the location scene, the text field is on top of everything, so we need to show it again after we close the menu
    --    
    if event.phase == "did" then
        if event.parent.showTextField then
            event.parent.showTextField()
        end
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
