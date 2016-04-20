local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local myData = require( "mydata" )
local utility = require( "utility" )
local theme = require( "theme" )
local UI = require( "ui" )

local locationEntryField
local searchTableView = nil
local locationsTableView
local locationChoices = {}
local sceneBackground

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
    if "dark" == myData.settings.theme then
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
	if event.row then 
		if "tap" == event.phase or "release" == event.phase then
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
	end
	native.setKeyboardFocus( nil )
	return true
end


local function onSearchRowRender( event )
    local row = event.row
    local params = event.row.params

    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    local rowTitle = display.newText( row, params.name, 20, rowHeight * 0.5, myData.font, 16 )
    rowTitle:setFillColor( unpack( theme.textColor ) )
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
		print( event.phase, textField().text )
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
		if event.row then
			transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x - 51 })
			event.row.deleteIsShowing = true
		end
	elseif event.phase == "swipeRight" and event.row.deleteIsShowing then
		if event.row then
			transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x + 51 })	
			event.row.deleteIsShowing = false	
		end
	elseif "tap" == event.phase or "release" == event.phase then
		if event.row then
			if event.row.deleteIsShowing then
				transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x + 51 })	
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
	native.setKeyboardFocus( nil )
end

local function onLocationRowRender( event )
    -- Get reference to the row group
    local row = event.row
    local params = event.row.params

    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    local rowTitle = display.newText( row, params.name, 20, rowHeight * 0.5, myData.font, 16 )
    rowTitle:setFillColor( unpack( theme.textColor ) )
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
    deleteButton.x = rowWidth + 1 --+ 25
    deleteButton.y = 0 -- rowHeight --* 0.5
    deleteButton.id = params.id
    row.deleteButton = deleteButton
    row:insert( deleteButton )
end

local function locationListener( event )
	-- stub out for now
end

local function dismisKeyboard( event )
	if "ended" == event.phase then
		native.setKeyboardFocus( nil )
	end
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
	UI.navBar:setLabel( "Locations" )
    sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    sceneGroup:insert( sceneBackground )
    sceneBackground:addEventListener( "touch", dismisKeyboard )

	local locationLabel = display.newText("Enter location", display.contentCenterX, 90, myData.fontBold, 18 )
	locationLabel:setFillColor( unpack( theme.textColor ) )
	sceneGroup:insert( locationLabel)

	local locationTableViewHeight = display.actualContentHeight - 210
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
        hideBackground = true,
        listener = locationListener
	})
	sceneGroup:insert( locationsTableView )
end

function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then

		reloadData()
		sceneBackground:setFillColor( unpack( theme.backgroundColor ) )
	else
		local fieldWidth = display.contentWidth - 40

		locationEntryField = native.newTextField( 20, 120, fieldWidth, 30 )
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
