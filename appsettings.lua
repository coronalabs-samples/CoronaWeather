local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local myData = require( "mydata" )
local utility = require( "utility" )
local theme = require( "theme" )
local UI = require( "ui" )

local radioButton1
local radioButton2
local radioButton3
local radioButton4
local radioButton5
local radioButton6
local radioButton7
local radioButton8
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
local bingText
local credits1
local credits2

local function gotoBing( event )
	system.openURL( "https://www.bing.com" )
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
	bingText:setFillColor( unpack( theme.textColor ) )
	credits1:setFillColor( unpack( theme.textColor ) )
	credits2:setFillColor( unpack( theme.textColor ) )
end

local function resetTheme()
	updateTheme()
	UI.createNavBar()
	UI.navBar:setLabel( "Settings" )
	UI.createTabBar()
end

-- Handle press events for the buttons
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
    utility.saveTable( myData.settings, "settings.json" )
end

-- Handle press events for the checkbox
local function onSwitchPress( event )
	local switch = event.target

	print("switch is", switch.isOn)
	if switch.isOn then
		myData.settings.showIcons = true
	else
		myData.settings.showIcons = false
	end
	utility.saveTable(myData.settings, "settings.json")
	print( "Switch with ID '"..switch.id.."' is on: "..tostring(switch.isOn) )
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
	UI.navBar:setLabel( "Settings" )
	sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
	sceneGroup:insert( sceneBackground )

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

	tempratureLabel = display.newText( "Temperature Settings", display.contentCenterX, 10, theme.fontBold)
	scrollView:insert( tempratureLabel )

	-- Create a group for the radio button set
	local tempRadioGroup = display.newGroup()
	scrollView:insert( tempRadioGroup )

	-- Create two associated radio buttons (inserted into the same display group)
	radioButton1 = widget.newSwitch
	{
		left = 20,
		top = tempratureLabel.y + 30,
		style = "radio",
		id = "fahrenheit",
		onPress = onRadioButtonPress
	}
	tempRadioGroup:insert( radioButton1 )

	fahrenheitText = display.newText( "Fahrenheit", 60, radioButton1.y, theme.font, 18 )
	fahrenheitText.anchorX = 0
	scrollView:insert( fahrenheitText )

	radioButton2 = widget.newSwitch
	{
		left = 20,
		top = radioButton1.y + 30,
		style = "radio",
		id = "celsius",
		onPress = onRadioButtonPress
	}
	tempRadioGroup:insert( radioButton2 )

	celsiusText = display.newText( "Celsius", 60, radioButton2.y, theme.font, 18 )
	celsiusText.anchorX = 0
	scrollView:insert( celsiusText )

	distanceLabel = display.newText( "Distance Settings", display.contentCenterX, radioButton2.y + 45, theme.fontBold)
	scrollView:insert( distanceLabel )

	local unitsRadioGroup = display.newGroup()
	scrollView:insert( unitsRadioGroup )

	radioButton3 = widget.newSwitch
	{
		left = 20,
		top = distanceLabel.y + 30,
		style = "radio",
		id = "miles",
		onPress = onRadioButtonPress
	}
	unitsRadioGroup:insert( radioButton3 )

	milesText = display.newText( "Miles", 60, radioButton3.y, theme.font, 18 )
	milesText.anchorX = 0
	scrollView:insert( milesText )

	radioButton4 = widget.newSwitch
	{
		left = 20,
		top = radioButton3.y + 30,
		style = "radio",
		id = "kilometers",
		onPress = onRadioButtonPress
	}
	unitsRadioGroup:insert( radioButton4 )

	kiloText = display.newText( "Kilometers", 60, radioButton4.y, theme.font, 18 )
	kiloText.anchorX = 0
	scrollView:insert( kiloText )

	pressureLabel = display.newText( "Pressure Settings", display.contentCenterX, radioButton4.y + 45, theme.fontBold)
	scrollView:insert( pressureLabel )

	local pressureRadioGroup = display.newGroup()
	scrollView:insert( pressureRadioGroup )

	radioButton5 = widget.newSwitch
	{
		left = 20,
		top = pressureLabel.y + 30,
		style = "radio",
		id = "inches",
		onPress = onRadioButtonPress
	}
	pressureRadioGroup:insert( radioButton5 )

	inchesText = display.newText( "Inches of Mercury", 60, radioButton5.y, theme.font, 18 )
	inchesText.anchorX = 0
	scrollView:insert( inchesText )

	radioButton6 = widget.newSwitch
	{
		left = 20,
		top = radioButton5.y + 30,
		style = "radio",
		id = "millibars",
		onPress = onRadioButtonPress
	}
	pressureRadioGroup:insert( radioButton6 )

	millibarText = display.newText( "Millibars", 60, radioButton6.y, theme.font, 18 )
	millibarText.anchorX = 0
	scrollView:insert( millibarText )

	themeLabel = display.newText( "Theme", display.contentCenterX, radioButton6.y + 45, theme.fontBold)
	scrollView:insert( themeLabel )

	local themeRadioGroup = display.newGroup()
	scrollView:insert( themeRadioGroup )

	radioButton7 = widget.newSwitch
	{
		left = 20,
		top = themeLabel.y + 30,
		style = "radio",
		id = "theme_light",
		onPress = onRadioButtonPress
	}
	themeRadioGroup:insert( radioButton7 )

	lightText = display.newText( "Light", 60, radioButton7.y, theme.font, 18 )
	lightText.anchorX = 0
	scrollView:insert( lightText )

	radioButton8 = widget.newSwitch
	{
		left = 20,
		top = radioButton7.y + 30,
		style = "radio",
		id = "theme_dark",
		onPress = onRadioButtonPress
	}
	themeRadioGroup:insert( radioButton8 )

	darkText = display.newText( "Dark", 60, radioButton8.y, theme.font, 18 )
	darkText.anchorX = 0
	scrollView:insert( darkText )
	forecastIoText = display.newText("Weather data powered by Forecast", 10, darkText.y + 60, theme.font, 16)
	scrollView:insert(forecastIoText)
	forecastIoText.anchorX = 0
	forecastIoText:addEventListener( "tap", gotoForecastIO )

	bingText = display.newText("Geocoding powered by bing!", 10, forecastIoText.y + 20, theme.font, 16)
	scrollView:insert( bingText )
	bingText.anchorX = 0
	bingText:addEventListener( "tap", gotoBing )

	credits1 = display.newText("Some artwork courtesy MerlinTheRed (http://merlinthered.deviantart.com/)", 10, bingText.y + 20, display.actualContentWidth - 20, 0, theme.font, 10)
	scrollView:insert( credits1 )
	credits1.anchorX = 0
	credits1:addEventListener( "tap", gotoMerlin )

	credits2 = display.newText("Some artwork courtesy d3stroy (http://d3stroy.deviantart.com/)", 10, credits1.y + 20, display.actualContentWidth - 20, 0, theme.font, 10)
	scrollView:insert( credits2 )
	credits2.anchorX = 0
	credits2:addEventListener( "tap", gotoD3stroy )
end

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		updateTheme()
		if myData.settings.tempUnits == "fahrenheit" then
			radioButton1:setState( { isOn = true } )
		else
			radioButton2:setState( { isOn = true } )
		end
		if myData.settings.distanceUnits == "miles" then
			radioButton3:setState( { isOn = true } )
		else
			radioButton4:setState( { isOn = true } )
		end
		if myData.settings.pressureUnits == "inches" then
			radioButton5:setState( { isOn = true } )
		else
			radioButton6:setState( { isOn = true } )
		end
		if myData.settings.theme == "light" then
			radioButton7:setState( { isOn = true } )
		else
			radioButton8:setState( { isOn = true } )
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
