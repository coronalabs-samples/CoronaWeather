local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local myData = require( "mydata" )
local utility = require( "utility" )

local locationEntryField
local searchTableView = nil
local locationsTableView
local locationChoices = {}

function scene.hideTextField()
	print("hiding text field")
	locationEntryField.alpha = 0
end

function scene.showTextField()
	print("showing text field")
	locationEntryField.alpha = 1
end

local function reloadData()
	--
	locationsTableView:deleteAllRows()

    local isCategory = false
    local rowHeight = 40
    local rowColor = { default={ 1, 1, 1 }, over={ 1, 0.5, 0, 0.2 } }
    local lineColor = { 0.95, 0.95, 0.95 }
    if "Android" == myData.platform then
    	rowColor = { default={ 0.2, 0.2, 0.2 }, over={ 0.3, 0.3, 0.3 } }
    	lineColor = { 0, 0, 0 }
    end

    print(#myData.settings.locations)
    print( json.prettify( myData.settings.locations ))
	for i = 1, #myData.settings.locations do
		print( json.prettify( myData.settings.locations[i] ))
		locationsTableView:insertRow({
            isCategory = isCategory,
            rowHeight = rowHeight,
            rowColor = rowColor,
            lineColor = lineColor,
			params = {
				name = myData.settings.locations[i].name,
				latitude = myData.settings.locations[i].latitude,
				longitude = myData.settings.locations[i].longitude,
				postalCode = myData.settings.locations[i].postalCode,
				selected = myData.settings.locations[i].selected,
				id = i
			},
		})
	end
end

local function onSearchRowTouch( event )
	if event.phase == "tap" then
		local idx = event.row.id
		for i = 1, #myData.settings.locations do
			myData.settings.locations[i].selected = false
		end
		myData.settings.locations[#myData.settings.locations + 1] = { 
			name = locationChoices[idx].name, 
			latitude = locationChoices[idx].latitude, 
			longitude = locationChoices[idx].longitude,
			selected = true
		}
		utility.saveTable( myData.settings, "settings.json" )
		reloadData()
		searchTableView:removeSelf()
		searchTableView = nil
		locationEntryField.text = ""

	end
	return true
end


local function onSearchRowRender( event )
    local row = event.row
    local params = event.row.params

    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    local rowTitle = display.newText( row, params.name, 20, rowHeight * 0.5, myData.font, 16 )
    rowTitle:setFillColor( unpack( myData.textColor ) )
    rowTitle.anchorX = 0
end

local function displayHits( )
	if searchTableView then
		searchTableView:removeSelf()
		searchTableView = nil
	end
	searchTableView = widget.newTableView({
        left = 20,
        top = locationEntryField.y + 15,
        height = #locationChoices * 40,
        width = display.contentWidth - 40,
        onRowRender = onSearchRowRender,
        onRowTouch = onSearchRowTouch,
        listener = searchListener
	})

    local isCategory = false
    local rowHeight = 40
    local rowColor = { default={ 1, 1, 1 }, over={ 1, 0.5, 0, 0.2 } }
    local lineColor = { 0.95, 0.95, 0.95 }
    if "Android" == myData.platform then
    	rowColor = { default={ 0.4, 0.4, 0.4 }, over={ 0.5, 0.5, 0.5 } }
    	lineColor = { 0, 0, 0 }
    end
	for i = 1, #locationChoices do
		searchTableView:insertRow({
            isCategory = isCategory,
            rowHeight = rowHeight,
            rowColor = rowColor,
            lineColor = lineColor,
			params = {
				name = locationChoices[i].name,
				latitude = locationChoices[i].latitude,
				longitude = locationChoices[i].longitude,
				id = i
			},
		})
	end
end

local function geocodeResponse( event )
	print( json.prettify( event.response ) )
	if event.isError then
		-- bad address
	else
		local response = json.decode( event.response )
		local hits = response.resourceSets[1].resources
		for i = 1, #hits do
			locationChoices[i] = {}
			locationChoices[i].name = hits[i].name
			locationChoices[i].latitude = hits[i].point.coordinates[1]
			locationChoices[i].longitude = hits[i].point.coordinates[2]
			locationChoices[i].matches = true
		end
		displayHits( nil )
		--[[
		local response = json.decode( event.response )
		print( json.prettify( response.resourceSets[1].resources) )
		myData.latitude = response.resourceSets[1].resources[1].point.coordinates[1]
		myData.longitude = response.resourceSets[1].resources[1].point.coordinates[2]
		--print(myData.latitude, myData.longitude)
		if myData.settings.location == "home" then
			myData.settings.home.latitude = myData.latitude
			myData.settings.home.longitude = myData.longitude
		elseif myData.settings.location == "away" then
			myData.settings.away.latitude = myData.latitude
			myData.settings.away.longitude = myData.longitude
		end
		utility.saveTable( myData.settings, "settings.json" )
		--utility.print_r(myData)
		--]]
	end
end

local function geocode( address )
	print( address )
	local encodedAddress = utility.urlencode( address )
	local URL = "http://dev.virtualearth.net/REST/v1/Locations/" .. encodedAddress .. "?o=json&key=" .. myData.bingMapKey

	print( URL )
	network.request( URL, "GET", geocodeResponse)
end

local hasFetchedLocationList = false
local function fieldHandler( textField )
	return function( event )
		if ( "began" == event.phase ) then
			-- This is the "keyboard has appeared" event
			-- In some cases you may want to adjust the interface when the keyboard appears.
			hasFetchedLocationList = false
		elseif ( "ended" == event.phase ) then
			-- This event is called when the user stops editing a field: for example, when they touch a different field
			
		elseif ( "editing" == event.phase ) then
			if string.len( textField().text ) > 3 then
				geocode( textField().text )
			end
		elseif ( "submitted" == event.phase ) then
			-- This event occurs when the user presses the "return" key (if available) on the onscreen keyboard
			print( textField().text )
			geocode( textField().text )
			-- Hide keyboard
			native.setKeyboardFocus( nil )
		end
	end
end

local function deleteRow( event )
	--
	locationsTableView:deleteRows( event.target.id )
	table.remove( myData.settings.locations, event.target.id )
	reloadData()
end

local function onLocationRowTouch( event )
	for k, v in pairs( event ) do
		print(k,":",v)
	end
	if event.phase == "swipeLeft" and not event.row.deleteIsShowing then
		-- handle delete row here
		transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x - 50 })
		event.row.deleteIsShowing = true
	elseif event.phase == "swipeRight" and event.row.deleteIsShowing then
		transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x + 50 })	
		event.row.deleteIsShowing = false	
	elseif event.phase == "tap" then
		if event.row.deleteIsShowing then
			transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x + 50 })	
			event.row.deleteIsShowing = false
		end
		local row = event.row
		for i = 1, #myData.settings.locations do
			myData.settings.locations[i].selected = false
		end
		myData.settings.locations[row.id].selected = true
		utility.saveTable( myData.settings, "settings.json" )
		reloadData()
	end
end

local function onLocationRowRender( event )
    -- Get reference to the row group
    local row = event.row
    local params = event.row.params

    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    local rowTitle = display.newText( row, params.name, 20, rowHeight * 0.5, myData.font, 16 )
    rowTitle:setFillColor( unpack( myData.textColor ) )
    rowTitle.anchorX = 0
    if params.selected then
		local checkMark = display.newImageRect( row, "images/checkmark.png", 40, 40 )
		checkMark.x = rowWidth - 40
		checkMark.y = rowTitle.y
    end
    local deleteButton = display.newGroup()
    local deleteButtonBackground = display.newRect( 25, 20 , 50, 40)
    deleteButtonBackground:setFillColor( 0.9, 0, 0 )
    deleteButton:insert( deleteButtonBackground )
    local deleteButtonText = display.newText( "Delete", 25, 20, myData.font, 11 )
    deleteButtonText:setFillColor( 1 )
    deleteButton:insert( deleteButtonText )
    deleteButton:addEventListener( "touch", deleteRow )
    deleteButton.x = rowWidth --+ 25
    deleteButton.y = 0 -- rowHeight --* 0.5
    deleteButton.id = params.id
    row.deleteButton = deleteButton
    row:insert( deleteButton )
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
	myData.navBar:setLabel( "Locations" )
	local background = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
	background:setFillColor( unpack( myData.backgroundColor ) )
	sceneGroup:insert( background )

	local locationLabel = display.newText("Enter location", display.contentCenterX, 70, myData.fontBold, 18 )
	locationLabel:setFillColor( unpack( myData.textColor ) )
	sceneGroup:insert( locationLabel)

	local locationTableViewHeight = display.contentHeight - 190
	if "Android" == myData.platform then
		-- adjust for to tabBar at the bottom on Android
		locationTableViewHeight = locationTableViewHeight + 50 
	end

	locationsTableView = widget.newTableView({
        left = 20,
        top = locationLabel.y + 60,
        height = locationTableViewHeight,
        width = display.contentWidth - 40,
        onRowRender = onLocationRowRender,
        onRowTouch = onLocationRowTouch,
        backgroundColor = myData.backgroundColor,
        listener = locationListener
	})
	sceneGroup:insert( locationsTableView )
end

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then

		reloadData()

	else
		local fieldWidth = display.contentWidth - 40

		locationEntryField = native.newTextField( 20, 100, fieldWidth, 30 )
		locationEntryField:addEventListener( "userInput", fieldHandler( function() return locationEntryField end ) ) 
		sceneGroup:insert( locationEntryField)
		locationEntryField.anchorX = 0
		locationEntryField.placeholder = "Location"		
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	
	if event.phase == "will" then
		locationEntryField:removeSelf();
		locationEntryField = nil

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
