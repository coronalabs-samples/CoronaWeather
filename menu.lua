local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local utility = require( "utility" )

local myData = require( "mydata" )

local params

local function closeMenu( event )
    if event.phase == "ended" then
        composer.hideOverlay( false, "fromLeft", 500 )
    end
    return true
end

local function goConditions( event )
    if event.phase == "ended" then
        composer.gotoScene( "currentConditions", { time=500, effect="slideRight" } )
    end
    return true
end

local function goForecast( event )
    if event.phase == "ended" then
        composer.gotoScene( "forecast", { time=500, effect="slideRight" } )
    end
    return true
end

local function goLocations( event )
    if event.phase == "ended" then
        composer.gotoScene( "locations", { time=500, effect="slideRight" } )
    end
    return true
end

local function goSettings( event )
    if event.phase == "ended" then
        composer.gotoScene( "appsettings", { time=500, effect="slideRight" } )
    end
    return true
end

local function makeMenuItem(text, iconFile, width, height, font, fontSize, handler)
    local buttonGroup = display.newGroup()
    local icon = display.newImageRect( iconFile, width, height )
    buttonGroup:insert( icon )
    icon.x = 20
    icon.y = 15
    local buttonText = display.newText( text, icon.x + 20, icon.y, font, fontSize)
    buttonText:setFillColor( 0 )
    buttonText.anchorX = 0
    buttonGroup:insert( buttonText )
    buttonGroup:addEventListener( "touch", handler )
    return buttonGroup
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
    local background = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    background:setFillColor( 0, 0, 0, 0.66 )
    sceneGroup:insert( background )
    background:addEventListener( "touch", closeMenu )

    local menuBackground = display.newRect(display.actualContentWidth * 0.2, display.contentCenterY, display.actualContentWidth * 0.4, display.actualContentHeight )
    menuBackground:setFillColor( 1, 1, 1, 1)
    sceneGroup:insert( menuBackground )

    local currentConditionsButton = makeMenuItem( "Current Conditions", "images/temperature.png", 24, 24, myData.font, 12, goConditions )
    sceneGroup:insert( currentConditionsButton )
    currentConditionsButton.anchorX = 0
    currentConditionsButton.x = 0
    currentConditionsButton.y = 70

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

    params = event.params
    --
    -- If my parent scene is the location scene, the text field is on top of everything, so we need to hide it to show the menu
    --
    for k, v in pairs(event.parent) do
        print(k, ":", v)
    end
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
