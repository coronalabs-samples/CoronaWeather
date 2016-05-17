--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- appsettings.lua -- let the user have some control over the app behavior
--

-- System modules
local composer = require( "composer" )
local scene = composer.newScene()
local widget = require( "widget" )
local json = require( "json" )

-- Our modules
local myData = require( "classes.mydata" )
local utility = require( "libs.utility" )
local theme = require( "classes.theme" )
local UI = require( "classes.ui" )

-- Because we want to be able to theme everything, forward declare just about everything
local fahrenheitButton 		-- Fahrenheit selected 
local celsiusButton 		-- Celsius selected
local milesButton 			-- Miles selcted
local kilometersButton 		-- Kilometers selected
local inchesButton 			-- Inches of Mercury for pressure selected
local millbarsButton 		-- Millibars of pressure selected
local lightButton 			-- Light theme selected
local darkButton 			-- Dark theme selected
local sceneBackground
local tempratureLabel
local fahrenheitText
local celsiusText
local distanceLabel
local milesText
local kiloText
local pressureLabel
local inchesText
local millibarText
local themeLabel
local lightText
local darkText
local forecastIoText
local cityText
local credits1
local credits2

-- URL handlers for our various vendors and artists used
local function gotoGeoNames( event )
	system.openURL( "http://www.geonames.org/" )
	return true
end

local function gotoForecastIO( event )
	system.openURL( "https://forecast.io/" )
	return true
end

local function gotoMerlin( event )
	system.openURL( "http://merlinthered.deviantart.com/" )
	return true
end

local function gotoD3stroy( event )
	system.openURL( "http://d3stroy.deviantart.com/" )
	return true
end

-- Function to update the theme of this scene both after being changed and on scene show...
local function updateTheme()
	sceneBackground:setFillColor( unpack( theme.backgroundColor ) )
	tempratureLabel:setFillColor( unpack( theme.textColor ) )
	fahrenheitText:setFillColor( unpack( theme.textColor ) )
	celsiusText:setFillColor( unpack( theme.textColor ) )
	distanceLabel:setFillColor( unpack( theme.textColor ) )
	milesText:setFillColor( unpack( theme.textColor ) )
	kiloText:setFillColor( unpack( theme.textColor ) )
	pressureLabel:setFillColor( unpack( theme.textColor ) )
	inchesText:setFillColor( unpack( theme.textColor ) )
	millibarText:setFillColor( unpack( theme.textColor ) )
	themeLabel:setFillColor( unpack( theme.textColor ) )
	lightText:setFillColor( unpack( theme.textColor ) )
	darkText:setFillColor( unpack( theme.textColor ) )
	forecastIoText:setFillColor( unpack( theme.textColor ) )
	cityText:setFillColor( unpack( theme.textColor ) )
	credits1:setFillColor( unpack( theme.textColor ) )
	credits2:setFillColor( unpack( theme.textColor ) )
end

-- when we change the theme, we need to update all our objects, re-create the navBar and tabBar
local function resetTheme()
	updateTheme()
	UI.createNavBar()
	UI.navBar:setLabel( "Settings" )
	UI.createTabBar()
end

-- Handle press events for the buttons
-- most of these is just a matter of checking which radio button is selcted and updating the
-- setting in the user's saved settings table. If it's a theme change, reset the theme too.
local function onRadioButtonPress( event )
    local switch = event.target
    print( "Switch with ID '"..switch.id.."' is on: "..tostring(switch.isOn) )
    myData.lastRefresh = 0 -- force refresh
    if switch.id == "fahrenheit" then
    	myData.settings.tempUnits = "fahrenheit"
    elseif switch.id == "celsius" then
    	myData.settings.tempUnits = "celsius"
    elseif switch.id == "miles" then
    	myData.settings.distanceUnits = "miles"
    elseif switch.id == "kilometers" then
    	myData.settings.distanceUnits = "kilometers"
    elseif switch.id == "inches" then
    	myData.settings.pressureUnits = "inches"
    elseif switch.id == "millibars" then
    	myData.settings.pressureUnits = "millibars"
    elseif switch.id == "theme_light" then
    	theme.setTheme( "light")
    	myData.settings.theme = "light"
    	resetTheme()
    elseif switch.id == "theme_dark" then
    	theme.setTheme( "dark" )
    	myData.settings.theme = "dark"
		resetTheme()
    end
    -- save everything
    utility.saveTable( myData.settings, "settings.json" )
end

--
-- Start the composer event handlers
--
function scene:create( event )
	local sceneGroup = self.view

	sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
	sceneGroup:insert( sceneBackground )

	-- create a scrollView to put all of this in since we will exceed the height of most screens.
	-- Make it the full height of the screen less 50 px for the navBar and 50px of padding
	-- then adjust for the tabBar on iOS

	local scrollViewHeight = display.actualContentHeight - 100

    if "iOS" == myData.platform then
        scrollViewHeight = scrollViewHeight - 50
    end
    -- Create the widget
    local scrollView = widget.newScrollView
    {
        top = 80,
        left = 0,
        width = display.actualContentWidth,
        height = scrollViewHeight,
        scrollWidth = display.actualContentWidth,
        scrollHeight = 800,
        hideBackground = true,
    }
    sceneGroup:insert( scrollView )

    -- create all of the display objects and insert them into the scrollView. The scrollView
    -- is inserted into the scene's view group.

	tempratureLabel = display.newText( "Temperature Settings", display.contentCenterX, 10, theme.fontBold)
	scrollView:insert( tempratureLabel )

	-- Create a group for the radio button set
	-- radio buttons in a group will only allow one to be selected. 
	-- put each button in its group, then put the group into the scrollView
	local tempRadioGroup = display.newGroup()
	scrollView:insert( tempRadioGroup )

	-- Create two associated radio buttons (inserted into the same display group)
	fahrenheitButton = widget.newSwitch
	{
		left = 20,
		top = tempratureLabel.y + 30,
		style = "radio",
		id = "fahrenheit",
		onPress = onRadioButtonPress
	}
	tempRadioGroup:insert( fahrenheitButton )

	fahrenheitText = display.newText( "Fahrenheit", 60, fahrenheitButton.y, theme.font, 18 )
	fahrenheitText.anchorX = 0
	scrollView:insert( fahrenheitText )

	celsiusButton = widget.newSwitch
	{
		left = 20,
		top = fahrenheitButton.y + 30,
		style = "radio",
		id = "celsius",
		onPress = onRadioButtonPress
	}
	tempRadioGroup:insert( celsiusButton )

	celsiusText = display.newText( "Celsius", 60, celsiusButton.y, theme.font, 18 )
	celsiusText.anchorX = 0
	scrollView:insert( celsiusText )

	distanceLabel = display.newText( "Distance Settings", display.contentCenterX, celsiusButton.y + 45, theme.fontBold)
	scrollView:insert( distanceLabel )

	local unitsRadioGroup = display.newGroup()
	scrollView:insert( unitsRadioGroup )

	milesButton = widget.newSwitch
	{
		left = 20,
		top = distanceLabel.y + 30,
		style = "radio",
		id = "miles",
		onPress = onRadioButtonPress
	}
	unitsRadioGroup:insert( milesButton )

	milesText = display.newText( "Miles", 60, milesButton.y, theme.font, 18 )
	milesText.anchorX = 0
	scrollView:insert( milesText )

	kilometersButton = widget.newSwitch
	{
		left = 20,
		top = milesButton.y + 30,
		style = "radio",
		id = "kilometers",
		onPress = onRadioButtonPress
	}
	unitsRadioGroup:insert( kilometersButton )

	kiloText = display.newText( "Kilometers", 60, kilometersButton.y, theme.font, 18 )
	kiloText.anchorX = 0
	scrollView:insert( kiloText )

	pressureLabel = display.newText( "Pressure Settings", display.contentCenterX, kilometersButton.y + 45, theme.fontBold)
	scrollView:insert( pressureLabel )

	local pressureRadioGroup = display.newGroup()
	scrollView:insert( pressureRadioGroup )

	inchesButton = widget.newSwitch
	{
		left = 20,
		top = pressureLabel.y + 30,
		style = "radio",
		id = "inches",
		onPress = onRadioButtonPress
	}
	pressureRadioGroup:insert( inchesButton )

	inchesText = display.newText( "Inches of Mercury", 60, inchesButton.y, theme.font, 18 )
	inchesText.anchorX = 0
	scrollView:insert( inchesText )

	millbarsButton = widget.newSwitch
	{
		left = 20,
		top = inchesButton.y + 30,
		style = "radio",
		id = "millibars",
		onPress = onRadioButtonPress
	}
	pressureRadioGroup:insert( millbarsButton )

	millibarText = display.newText( "Millibars", 60, millbarsButton.y, theme.font, 18 )
	millibarText.anchorX = 0
	scrollView:insert( millibarText )

	themeLabel = display.newText( "Theme", display.contentCenterX, millbarsButton.y + 45, theme.fontBold)
	scrollView:insert( themeLabel )

	local themeRadioGroup = display.newGroup()
	scrollView:insert( themeRadioGroup )

	lightButton = widget.newSwitch
	{
		left = 20,
		top = themeLabel.y + 30,
		style = "radio",
		id = "theme_light",
		onPress = onRadioButtonPress
	}
	themeRadioGroup:insert( lightButton )

	lightText = display.newText( "Light", 60, lightButton.y, theme.font, 18 )
	lightText.anchorX = 0
	scrollView:insert( lightText )

	darkButton = widget.newSwitch
	{
		left = 20,
		top = lightButton.y + 30,
		style = "radio",
		id = "theme_dark",
		onPress = onRadioButtonPress
	}
	themeRadioGroup:insert( darkButton )

	darkText = display.newText( "Dark", 60, darkButton.y, theme.font, 18 )
	darkText.anchorX = 0
	scrollView:insert( darkText )
	forecastIoText = display.newText("Weather data powered by Forecast", 10, darkText.y + 60, theme.font, 14)
	scrollView:insert(forecastIoText)
	forecastIoText.anchorX = 0
	forecastIoText:addEventListener( "tap", gotoForecastIO )

	cityText = display.newText("City database courtsey GeoNames.org", 10, forecastIoText.y + 20, theme.font, 14)
	scrollView:insert( cityText )
	cityText.anchorX = 0
	cityText:addEventListener( "tap", gotoGeoNames )

	credits1 = display.newText("Some artwork courtesy MerlinTheRed (http://merlinthered.deviantart.com/)", 10, cityText.y + 36, display.actualContentWidth - 20, 0, theme.font, 14)
	scrollView:insert( credits1 )
	credits1.anchorX = 0 
	credits1:addEventListener( "tap", gotoMerlin )

	credits2 = display.newText("Some artwork courtesy d3stroy (http://d3stroy.deviantart.com/)", 10, credits1.y + 36, display.actualContentWidth - 20, 0, theme.font, 14)
	scrollView:insert( credits2 )
	credits2.anchorX = 0
	credits2.anchorY = 0
	credits2:addEventListener( "tap", gotoD3stroy )
end

function scene:show( event )
	local sceneGroup = self.view

	-- before we show the scene, update the theme (only want to write those setFillColor()'s once.)
	-- Also look at the user's current settings and make sure the right radio buttons are set.
	if event.phase == "will" then
		updateTheme()
		if myData.settings.tempUnits == "fahrenheit" then
			fahrenheitButton:setState( { isOn = true } )
		else
			celsiusButton:setState( { isOn = true } )
		end
		if myData.settings.distanceUnits == "miles" then
			milesButton:setState( { isOn = true } )
		else
			kilometersButton:setState( { isOn = true } )
		end
		if myData.settings.pressureUnits == "inches" then
			inchesButton:setState( { isOn = true } )
		else
			millbarsButton:setState( { isOn = true } )
		end
		if myData.settings.theme == "light" then
			lightButton:setState( { isOn = true } )
		else
			darkButton:setState( { isOn = true } )
		end
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	-- nothing to do here
	if event.phase == "will" then

	end

end

function scene:destroy( event )
	local sceneGroup = self.view
	-- nothing to do here
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
return scene
