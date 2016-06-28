--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- forecast.lua -- Generate a 7 day forecast for the currently selected location

--
local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local utility = require( "libs.utility" )
local myData = require( "classes.mydata" )
local wx = require( "classes.weather" )
local theme = require( "classes.theme" )
local UI = require( "classes.ui" )

local sceneBackground
local forecastTableView
local forecastHeaderBackground
local dayText
local hiloText
local skyText
local precipText
local humidityText
local windText


function string.upperCaseFirstLetter( self )
	print("stringUCFL", self)
	local first = string.upper( string.sub( self, 1, 1))
	local rest = string.sub( self, 2)
	return first .. rest
end

local function onForecastRowRender( event )
	local row = event.row
	local params = event.row.params

	-- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
	local rowHeight = row.contentHeight
	local rowWidth = row.contentWidth
	--
	-- Get a date from Unix Time so we can display the parts
	--
	local weekDay = os.date( "%a", params.time )
	local monthName = os.date( "%b", params.time )
	local monthDay = os.date( "%d", params.time )

	local rowBackground = display.newRect(0, 0, rowWidth, rowHeight)
	rowBackground:setFillColor( unpack( theme.rowBackgroundColor ) )
	rowBackground.anchorX = 0
	rowBackground.anchorY = 0
	row:insert( rowBackground )

	local weekDayText = display.newText( weekDay, 30, 5, theme.fontBold, 16 )
	row:insert( weekDayText ) 
	weekDayText:setFillColor( unpack( theme.textColor ) )
	weekDayText.anchorY = 0

	local dateText = display.newText( monthName .. " " .. monthDay, 30, 25, theme.font, 12 )
	dateText.anchorY = 0
	dateText:setFillColor( unpack( theme.textColor ) )
	row:insert( dateText )

	local highText = display.newText( params.high .. "º", 75, 5, theme.font, 16 )
	highText:setFillColor( unpack( theme.textColor ) )
	highText.anchorY = 0
	row:insert( highText )

	local lowText = display.newText( params.low .. "º", 75, 25, theme.font, 14 )
	lowText:setFillColor( 0.5 )
	lowText.anchorY = 0
	row:insert( lowText )

	local icon = display.newImageRect( "images/" .. params.icon .. ".png", 40, 40 )
	icon.x = 120
	icon.y = 25
	row:insert( icon )

	local precipChanceText = display.newText( params.precipChance .."% " .. string.upperCaseFirstLetter( params.precipType ), 150, 25, theme.font, 14 )
	precipChanceText:setFillColor( unpack( theme.textColor ) )
	precipChanceText.anchorX = 0
	row:insert( precipChanceText )

	local humidityText = display.newText( params.humidity .. "%", 240, 25, theme.font, 14)
	humidityText:setFillColor( unpack( theme.textColor ) )
	row:insert( humidityText )

	local windSpeedPrefix = "mph"
	if myData.settings.distanceUnits == "kilometers" then
		windSpeedPrefix = "kph"
	end

	local windSpeedText = display.newText( params.windSpeed .. " " .. windSpeedPrefix, 300, 5, theme.font, 14 )
	windSpeedText:setFillColor( unpack( theme.textColor ) )
	windSpeedText.anchorY = 0
	row:insert( windSpeedText )

	local bearingIndex = math.floor( ( params.windBearing % 360 ) / 22.5 ) + 1
	print(params.windBearing, bearingIndex, wx.bearingLabels[ bearingIndex ])

	local windBearingText = display.newText( wx.bearingLabels[ bearingIndex ], 300, 25, theme.font, 14)
	windBearingText:setFillColor( unpack( theme.textColor ) )
	windBearingText.anchorY = 0
	row:insert( windBearingText )
end

local function displayForecast()
	local response = myData.currentWeatherData
	--print( json.prettify( response ) )

	if not response then
		native.showAlert("Oops!", "Forcast information currently not avaialble!", { "Okay" } )
	end
	local daily = response.daily
	local forecast = {}

	forecastTableView:deleteAllRows()

	local isCategory = false
	local rowHeight = 50
	local rowColor = { default={ 1, 1, 1 }, over={ 1, 0.5, 0, 0.2 } }
	local lineColor = { 0.95, 0.95, 0.95 }
	if "Android" == myData.platform then
		rowColor = { default={ 0.2, 0.2, 0.2 }, over={ 0.3, 0.3, 0.3 } }
		lineColor = { 0, 0, 0 }
	end

	for i = 2, 8 do
		forecast[i] = {}
		forecast[i].high = math.floor( wx.convertTemperature( tonumber( daily.data[i].temperatureMax ), myData.settings.tempUnits )  + 0.5 )
		forecast[i].low = math.floor( wx.convertTemperature( tonumber( daily.data[i].temperatureMin ), myData.settings.tempUnits )  + 0.5 )
		forecast[i].fHigh = math.floor( wx.convertTemperature( tonumber( daily.data[i].temperatureMax ), "fahrenheit" )  + 0.5 ) -- for graphing purposes
		forecast[i].fLow = math.floor( wx.convertTemperature( tonumber( daily.data[i].temperatureMin ), "fahrenheit" )  + 0.5 )  -- for graphing purposes
		forecast[i].icon = daily.data[i].icon
		forecast[i].precipChance = math.floor( daily.data[i].precipProbability * 100 + 0.5 )
		if daily.data[i].precipType then
			forecast[i].precipType = daily.data[i].precipType
		else
			forecast[i].precipType = ""
		end
		forecast[i].time = daily.data[i].time
		forecast[i].summary = daily.data[i].summary
		forecast[i].windSpeed = math.floor( wx.convertDistance( tonumber( daily.data[i].windSpeed ), myData.settings.distanceUnits ) + 0.5 )
		forecast[i].windBearing = tonumber( daily.data[i].windBearing )
		forecast[i].humidity = math.floor( tonumber( daily.data[i].humidity ) * 100 )
		forecastTableView:insertRow({
			isCategory = isCategory,
			rowHeight = rowHeight,
			rowColor = rowColor,
			lineColor = lineColor,
			params = {
				high = forecast[i].high,
				fHigh = forecast[i].fHigh,
				low = forecast[i].low,
				fLow = forecast[i].fLow,
				icon = forecast[i].icon,
				precipChance = forecast[i].precipChance,
				precipType = forecast[i].precipType,
				time = forecast[i].time,
				summary = forecast[i].summary,
				windSpeed = forecast[i].windSpeed,
				windBearing = forecast[i].windBearing,
				humidity = forecast[i].humidity,
				id = i
			},
		})

	end

end

local function forecastListener( event )
	return true
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
	local statusBarPad = display.topStatusBarContentHeight

	sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
	sceneGroup:insert( sceneBackground )

	forecastHeaderBackground = display.newRect( display.contentCenterX, 100 + statusBarPad, display.contentWidth - 40, 50)
	sceneGroup:insert( forecastHeaderBackground )

	dayText = display.newText( "Date", 50, forecastHeaderBackground.y, theme.font, 14 )
	sceneGroup:insert( dayText )

	hiloText = display.newText( "Hi/Lo", 95, forecastHeaderBackground.y, theme.font, 14 )
	sceneGroup:insert( hiloText )

	skyText = display.newText( "Skies", 140, forecastHeaderBackground.y, theme.font, 14 )
	sceneGroup:insert( skyText )

	precipText = display.newText( "Precip", 190, forecastHeaderBackground.y, theme.font, 14 )
	sceneGroup:insert( precipText )

	humidityText = display.newText( "Humidity", 260, forecastHeaderBackground.y, theme.font, 14 )
	sceneGroup:insert( humidityText )

	if display.contentWidth > 320 then
		windText = display.newText( "Wind", 320, forecastHeaderBackground.y, theme.font, 14 )
		windText:setFillColor( unpack( theme.textColor ) )
		sceneGroup:insert( windText )
	end

	local tableViewHeight = 350 -- 7 * 50
	local availableHeight = display.contentHeight - 125 - statusBarPad
	if myData.platform == "iOS" then
		availableHeight = availableHeight - 50 -- compensate for the tabBar at the bottom
	end
	if tableViewHeight > availableHeight then
		tableViewHeight = availableHeight
	end 

	forecastTableView = widget.newTableView({
		left = 20,
		top = 130 + statusBarPad,
		height = tableViewHeight,
		width = display.contentWidth - 40,
		onRowRender = onForecastRowRender,
		-- onRowTouch = onForecastRowTouch,
		backgroundColor = theme.backgroundColor,
		listener = forecastListener
	})
	sceneGroup:insert( forecastTableView )
end

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		UI.navBar:setLabel( myData.settings.locations[1].name )
		for i = 1, #myData.settings.locations do
			if myData.settings.locations[i].selected then
				UI.navBar:setLabel( myData.settings.locations[i].name )
				break
			end
		end

		sceneBackground:setFillColor( unpack( theme.backgroundColor ) )
		forecastHeaderBackground:setFillColor( unpack( theme.rowBackgroundColor ) )
		dayText:setFillColor( unpack( theme.textColor ) )
		hiloText:setFillColor( unpack( theme.textColor ) )
		skyText:setFillColor( unpack( theme.textColor ) )
		precipText:setFillColor( unpack( theme.textColor ) )
		humidityText:setFillColor( unpack( theme.textColor ) )
		if display.contentWidth > 320 then
			windText:setFillColor( unpack( theme.textColor ) )
		end

		local now = os.time()
		if now > myData.lastRefresh + (15 * 60) then
			wx.fetchWeather( displayForecast )
		else
			displayForecast()
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
