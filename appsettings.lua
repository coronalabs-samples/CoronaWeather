local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local myData = require( "mydata" )
local utility = require( "utility" )

local radioButton1
local radioButton2
local radioButton3
local radioButton4

local function gotoBing( event )
	system.openURL( "https://www.bing.com" )
	return true
end

local function gotoForecastIO( event )
	system.openURL( "https://forecast.io/" )
	return true
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
    	myData.settings.dinstanceUnits = "kilometers"
    elseif switch.id == "inches" then
    	myData.settings.pressureUnits = "inches"
    elseif switch.id == "millibars" then
    	myData.settings.pressureUnits = "millibars"
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

	utility.print_r(myData.textColor)
	--
	-- setup a page background, really not that important though composer
	-- crashes out if there isn't a display object in the view.
	--
	myData.navBar:setLabel( "Settings" )

	local tempratureLabel = display.newText( "Temperature Settings", display.contentCenterX, 100, myData.fontBold)
	tempratureLabel:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( tempratureLabel )

	-- Create a group for the radio button set
	local tempRadioGroup = display.newGroup()
	sceneGroup:insert( tempRadioGroup )

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

	local fahrenheitText = display.newText( "Fahrenheit", 60, radioButton1.y, myData.font, 18 )
	fahrenheitText.anchorX = 0
	fahrenheitText:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( fahrenheitText )

	radioButton2 = widget.newSwitch
	{
		left = 20,
		top = radioButton1.y + 30,
		style = "radio",
		id = "celsius",
		onPress = onRadioButtonPress
	}
	tempRadioGroup:insert( radioButton2 )

	local celsiusText = display.newText( "Celsius", 60, radioButton2.y, myData.font, 18 )
	celsiusText.anchorX = 0
	celsiusText:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( celsiusText )

	local distanceLabel = display.newText( "Distance Settings", display.contentCenterX, radioButton2.y + 45, myData.fontBold)
	distanceLabel:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( distanceLabel )

	local unitsRadioGroup = display.newGroup()
	sceneGroup:insert( unitsRadioGroup )

	radioButton3 = widget.newSwitch
	{
		left = 20,
		top = distanceLabel.y + 30,
		style = "radio",
		id = "miles",
		onPress = onRadioButtonPress
	}
	unitsRadioGroup:insert( radioButton3 )

	local milesText = display.newText( "Miles", 60, radioButton3.y, myData.font, 18 )
	milesText.anchorX = 0
	milesText:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( milesText )

	radioButton4 = widget.newSwitch
	{
		left = 20,
		top = radioButton3.y + 30,
		style = "radio",
		id = "kilometers",
		onPress = onRadioButtonPress
	}
	unitsRadioGroup:insert( radioButton4 )

	local kiloText = display.newText( "Kilometers", 60, radioButton4.y, myData.font, 18 )
	kiloText.anchorX = 0
	kiloText:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( kiloText )

	local pressureLabel = display.newText( "Pressure Settings", display.contentCenterX, radioButton4.y + 45, myData.fontBold)
	pressureLabel:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( pressureLabel )

	local pressureRadioGroup = display.newGroup()
	sceneGroup:insert( pressureRadioGroup )

	radioButton5 = widget.newSwitch
	{
		left = 20,
		top = pressureLabel.y + 30,
		style = "radio",
		id = "inches",
		onPress = onRadioButtonPress
	}
	pressureRadioGroup:insert( radioButton5 )

	local inchesText = display.newText( "Inches of Mercury", 60, radioButton5.y, myData.font, 18 )
	inchesText.anchorX = 0
	inchesText:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( inchesText )

	radioButton6 = widget.newSwitch
	{
		left = 20,
		top = radioButton5.y + 30,
		style = "radio",
		id = "millibars",
		onPress = onRadioButtonPress
	}
	pressureRadioGroup:insert( radioButton6 )

	local millibarText = display.newText( "Millibars", 60, radioButton6.y, myData.font, 18 )
	millibarText.anchorX = 0
	millibarText:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( millibarText )

	local forecastIoText = display.newText("Weather data powered by Forecast", display.contentCenterX, display.contentHeight - 100, myData.font, 16)
	sceneGroup:insert(forecastIoText)
	forecastIoText:setFillColor( unpack( myData.textColor ) )
	forecastIoText:addEventListener( "tap", gotoForecastIO )

	local bingText = display.newText("Geocoding powered by bing!", display.contentCenterX, display.contentHeight - 80, myData.font, 16)
	sceneGroup:insert( bingText )
	bingText:setFillColor( unpack( myData.textColor ) )
	bingText:addEventListener( "tap", gotoBing )

end

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
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
