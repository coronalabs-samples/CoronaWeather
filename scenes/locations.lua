--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- locations.lua -- scene to let the user select a location to get weather for.
-- 
-- Locations will be saved in the user's settings table. One of the items will be the currently 
-- selected location. One other will be called "Current Location" and will be an undeletable 
-- entry used to use the current GPS location.
-- 
-- Our weather API uses latitude and longitude to get the current weather. We need a source of
-- locations that maps to a GPS location. A free location list from http://www.geonames.org/ 
-- has been converted (and slimmed down to just critical location information) to an sqlite3 
-- database and included in the resource bundle. In production you probably should build in 
-- plans to update the database periodically.
--
-- The scene will include a native.newTextField() to input text. After three characters have
-- have been entered, it will query the database for all matching records. An additional 
-- tableView will be created just below the input box to show the database matches. Tapping
-- on a row will add it to the locations table and update the tableView to show it. 
--
-- The settings will be saved back out to the JSON encoded file the next time the app restarts.
--

--
-- Bring in our modules
--
-- System modules
local composer = require( "composer" )
local scene = composer.newScene()
local widget = require( "widget" )
local json = require( "json" )
local sqlite3 = require( "sqlite3" )

-- Our modules
local myData = require( "classes.mydata" ) 	-- our global data
local utility = require( "libs.utility" )  	-- varous utility functions
local theme = require( "classes.theme" )   	-- Theme module
local UI = require( "classes.ui" )			-- The TabBar and NavBar code. It sits above all composer scenes.
local wx = require( "classes.weather")		-- the weather module
-- Forward declarations
local locationEntryField 		-- holds the entry string
local searchTableView = nil 	-- The tableView to hold our dynamic search results
local locationsTableView 		-- The tableView to display the user's selected locations
local locationChoices = {}		-- Tempoary table to hold the SQL search results
local locationLabel 			-- Label for the form
local sceneBackground 			-- needs accessed in multiple functions for themimg reasons
local wasSwiped 				-- Flag to help separate touch events

-- Function to hide the text field
-- Because native.newTextField()'s are always on top, if the user has the hamburger menu active, 
-- it will show underneath the text field. The menu.lua scene needs to be able to show and hide the 
-- text field while the menu is visible. These functions, as part of the scene object will let that
-- happen.
function scene.hideTextField()
	print("hiding text field")
	locationEntryField.isVisible = false
	locationEntryField.x = locationEntryField.x + 200
end

-- function to show the text field.
function scene.showTextField()
	print("showing text field")
	locationEntryField.isVisible = true
	locationEntryField.x = locationEntryField.x - 200

end

-- function to completly dump the tableView and reload it's data
-- since we may have a theme change, we need to be able to regenerate
-- all the rows. It's a brute force technique but there will only be a few
-- records in the table, its managable. We do get some DRY
-- advantages since this can be used to intially load the table too.
-- delete the rows and re-insert them. 
--
-- One of the reaons why we do this, is when we add a new record and make it
-- the selected one, we have to clear the selected flag from the other entries. 
-- Since we are using paramters to pass the data to onRowRender() we don't have
-- access to the view to change that one item from here.
--
-- This is called from multiple points below. It needs to be high up in 
-- the module for visibility.
local function reloadData()
	--
	locationsTableView:deleteAllRows()

    local isCategory = false
    local rowHeight = 40
    local rowColor = { default={ 1, 1, 1 }, over={ 0.9, 0.9, 0.9 } }
    local lineColor = { 0.95, 0.95, 0.95 }
    if "dark" == myData.settings.theme then
    	rowColor = { default={ 0.2, 0.2, 0.2 }, over={ 0.3, 0.3, 0.3 } }
    	lineColor = { 0, 0, 0 }
    end

    -- insert one record for each item in the user's saved location settings
    -- The data will be inserted via the params table to decouple of the rendering
    -- of the row from needing to know the state of the data table. This is kind of
    -- an attempt at Model-View-Controller design.
	for i = 1, #myData.settings.locations do
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
				noDelete = myData.settings.locations[i].noDelete,
				id = i
			},
		})
	end
end

-- Searching
-- touch handler for the search results tableView. If a record is touched, it gets
-- added to the location table and the location tableView is reloaded.
local function onSearchRowTouch( event )
	-- make sure a row was actually touched
	if event.row then 
		-- handle both the tap and touch type events for the row
		if "tap" == event.phase or "release" == event.phase then
			local idx = event.row.id
			-- loop over and clear any other selected locations
			for i = 1, #myData.settings.locations do
				myData.settings.locations[i].selected = false
			end
			-- add the new entry to the end of the location data, flag it as the selected entry
			myData.settings.locations[#myData.settings.locations + 1] = { 
				name = locationChoices[idx].name, 
				latitude = locationChoices[idx].latitude, 
				longitude = locationChoices[idx].longitude,
				selected = true
			}
			-- Save the settings table
			utility.saveTable( myData.settings, "settings.json" )
			-- regenerate the table
			reloadData()
			-- fetch the weather for the new location
			wx.fetchWeather( nil ) -- No need to call a listener function, just get the data.
			-- destroy the search results table
			searchTableView:removeSelf()
			searchTableView = nil
			-- clear the search field
			locationEntryField.text = ""
		end
	end
	native.setKeyboardFocus( nil )
	return true
end


-- This function will render each row of the search results table. It's only going to
-- show one object, a text string for the found city. 
local function onSearchRowRender( event )
    local row = event.row
    local params = event.row.params

    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    -- params should only have one member, .name. Create a display.newText 20 px from the left
    -- of the tableView and centered vertically
    local rowTitle = display.newText( row, params.name, 20, rowHeight * 0.5, myData.font, 16 )
    rowTitle:setFillColor( unpack( theme.textColor ) )
    rowTitle.anchorX = 0
end

-- This function will generate the searchTableView from scratch. We don't want the 
-- tableView until we have a reason to search for it, so create it on the fly. It
-- will be destroyed above when something is selcted but if it's not clean it up first.
local function displayHits( )
	-- if the tableView exists, destroy it
	if searchTableView then
		searchTableView:removeSelf()
		searchTableView = nil
	end
	-- create a new tableView
	searchTableView = widget.newTableView({
        left = 20,
        top = locationEntryField.y + 15,
        height = display.actualContentHeight - locationEntryField.y - 65,
        width = display.actualContentWidth - 40,
        onRowRender = onSearchRowRender,
        onRowTouch = onSearchRowTouch,
	})

	-- Loop over the locationChoices table which has the matched records from the 
	-- database and insert the rows into the table. We need to also pass in the 
	-- latitude and longitude as well for when we add an entry to the user's location 
	-- table.
    local isCategory = false
    local rowHeight = 40
    local rowColor = { default=theme.rowBackgroundColor, over=theme.rowBackgroundColor }
    local lineColor = { 0.5, 0.5, 0.5 }
    print("Before inserting rows into tableView")
    local t = system.getTimer()
	for i = 1, #locationChoices do
	    print( locationChoices[i].name)
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
	print("After inserting rows into tableView", system.getTimer() - t)
end

-- Look up a string in the sqlite database. Return a list of matched locations. This is called
-- from the text entry field's event handler.
local function lookupCity( address )
	table.remove( locationChoices )
	locationChoices = nil
	locationChoices = {}
	print("Before Query" )
	local t = system.getTimer( )
	for row in myData.db:nrows("SELECT * FROM cities WHERE LOWER(city) LIKE '" .. address .. "%' ORDER BY city") do
    	locationChoices[ #locationChoices + 1 ] = { name = row.city, latitude = row.latitude, longitude = row.longitude }
    	print(row.city)
	end
	print("After Query", system.getTimer() - t)
	if #locationChoices <= 100 then
		displayHits()
	end
end

-- handle the user input
--local hasFetchedLocationList = false
local function fieldHandler( textField )
	return function( event )
		print( event.phase, textField().text )
		if ( "began" == event.phase ) then
			-- This is the "keyboard has appeared" event
			-- Since we are just starting to type, indicate we haven't done a DB lookup yet.
			--hasFetchedLocationList = false
		elseif ( "ended" == event.phase ) then
			-- This event is called when the user stops editing a field: for example, when they touch a different field
			
		elseif ( "editing" == event.phase ) then
			-- don't query the database for one or two letters.
			if string.len( textField().text ) > 2 then
				lookupCity( textField().text )
			else
				if searchTableView then
					searchTableView:removeSelf()
					searchTableView = nil
				end
			end
		elseif ( "submitted" == event.phase ) then
			-- This event occurs when the user presses the "return" key (if available) on the onscreen keyboard
			-- There are two ways to select the location. Tapping the table row, or hitting the submit/enter key.
			-- This handles the enter key scenerio.
			print( textField().text )
			lookupCity( textField().text )
			-- Hide keyboard
			native.setKeyboardFocus( nil )
		end
	end
end

-- Handle deleting a row button. 
-- Since we recorded the table index as the ".id" value, we can use that to reference
-- back into our locations table.
local function deleteRow( event )
	if "ended" == event.phase then
		-- if the row we are deleting is the selected one, we need a source for the weather,
		-- so choose the first record which should the "Current Location" record which can't be
		-- deleted (it doesn't have a delete button!)
		if myData.settings.locations[ event.target.id ].selected then
			myData.settings.locations[ 1 ].selected = true
		end
		-- remove just the one row from the locations table
		table.remove( myData.settings.locations, event.target.id )
		-- save the updated table
		utility.saveTable( myData.settings, "settings.json" )
		-- regenerate the tableView after all these changes.
		reloadData()
	end
	return true
end

-- function to handle the row touch events
local function onLocationRowTouch( event )
	local row = event.row
	-- Our tableView taps are very short events. If the user holds their finger down too long
	-- it turns into a touch event which generates press, swipeLeft/Right and release events.
	-- We only care about swipes and if the user released their finger so map "tap" to a "release" event.
	if "tap" == event.phase then
		event.phase = "release"
	end
	-- we need to know if the user just did a press/release combination or if they swiped
	-- start by flagging that we were not swipped.
	if "press" == event.phase then
		wasSwiped = false
	elseif "swipeLeft" == event.phase and event.row.deleteButton and not event.row.deleteIsShowing then
		-- handle delete row here
		-- we have detected a swipe so set the swipe flag to true.
		wasSwiped = true
		-- if this was done on an actual row, show the delete button and set a flag to track that it's showing
		if row and event.row.deleteButton then
			transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x - 51 })
			event.row.deleteIsShowing = true
		end
	elseif "swipeRight" == event.phase and event.row.deleteButton and event.row.deleteIsShowing then
		-- again, track the swipe event
		wasSwiped = true
		-- if we are on a row swiping right, then hide the delete button
		if row and event.row.deleteButton then
			transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x + 51 })	
			event.row.deleteIsShowing = false	
		end
	elseif "release" == event.phase then
		if row then
			if not wasSwiped then
				-- if we have a valid row and I was not swiping, then I must be trying to select the row
				-- if the delete button is showing, hide it
				if row.deleteButton and row.deleteIsShowing then
					transition.to( row.deleteButton, { time=250, x = row.deleteButton.x + 51 })	
					row.deleteIsShowing = false
				end
				-- clear any other selected rows 
				for i = 1, #myData.settings.locations do
					myData.settings.locations[i].selected = false
				end
				-- select the current row
				myData.settings.locations[row.id].selected = true
				-- save the change
				utility.saveTable( myData.settings, "settings.json" )
				-- force reload the table
				reloadData()
				-- fetch the weather for our new location, no need to display it yet.
				wx.fetchWeather( nil )
			end
		end
		-- we are done so clear the swipe flag
		wasSwiped = false
	end
	-- hide the keyboard
	native.setKeyboardFocus( nil )
end

-- Draw a row for the user's selcted locations. Data will be passed in as params in the insertRow() method
-- to emulate M-V-C design patterns.
local function onLocationRowRender( event )
    -- Get reference to the row group
    local row = event.row
    local params = event.row.params

    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    -- Each row will have three potentially visible components:
    -- The location text (rowTitle), the delete button (off screen), and a check mark if selected.
    -- Render each part
    local rowTitle = display.newText( row, params.name, 20, rowHeight * 0.5, myData.font, 16 )
    rowTitle:setFillColor( unpack( theme.textColor ) )
    rowTitle.anchorX = 0
    if params.selected then
		local checkMark = display.newImageRect( row, "images/checkmark.png", 30, 30 )
		checkMark.x = rowWidth - 30
		checkMark.y = rowTitle.y
    end
    -- a row can be marked as undeletable (i.e. Current Location). If we are not that row, then
    -- generate a delete button and give it a touch handler of it's own.
    if not params.noDelete then
    	-- construct the button from a red rectangle and a white text object
    	-- put them in a group so they can move together.
	    local deleteButton = display.newGroup()
	    local deleteButtonBackground = display.newRect( 25, 20 , 50, 40)
	    deleteButtonBackground:setFillColor( 0.9, 0, 0 )
	    deleteButton:insert( deleteButtonBackground )
	    local deleteButtonText = display.newText( "Delete", 25, 20, myData.font, 11 )
	    deleteButtonText:setFillColor( 1 )
	    deleteButton:insert( deleteButtonText )
	    deleteButton:addEventListener( "touch", deleteRow )
	    deleteButton.x = rowWidth + 1 
	    deleteButton.y = 0 
	    deleteButton.id = params.id
	    row.deleteButton = deleteButton
	    row:insert( deleteButton )
	end
end

local function locationListener( event )
	-- stub out for now
end

-- If the keyboard is showing and you tap outside of something that needs a keyboard, we need
-- to hide it. The keyboard listener will handle itself. We also dismiss when the search tableView 
-- rows are touched. Any touches that make it to the background will be cause the keybaord to dismiss
-- as well.
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

	local statusBarPad = display.topStatusBarContentHeight

	-- make a rectangle for the backgrouned and color it to the current theme
    sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    sceneGroup:insert( sceneBackground )
    -- it will be themed in the show() event before it comes on screen
    -- make sure that touches outside of places that expect them will hide the keyboard
    sceneBackground:addEventListener( "touch", dismisKeyboard )

	locationLabel = display.newText("Enter location", display.contentCenterX, 90 + statusBarPad, myData.fontBold, 18 )
	sceneGroup:insert( locationLabel)

	-- compute the height of the tableView
	-- for iOS devices there is a 50px tabBar at the bottom. 
	-- The total for the navBar + tabBar + locationLabel, the text field and sufficient padding
	-- to make it look nice is 210 pixels of UI. The tableView can occupy the rest

	local locationTableViewHeight = display.actualContentHeight - 210 - statusBarPad
	if "Android" == myData.platform then
		-- adjust for lack of a tabBar at the bottom on Android
		locationTableViewHeight = locationTableViewHeight + 50 
	end

	-- create the tableView, position it below the text label + the text field which 
	-- hasn't been created yet.
	locationsTableView = widget.newTableView({
        left = 20,
        top = locationLabel.y + 60 + statusBarPad,
        height = locationTableViewHeight,
        width = display.contentWidth - 40,
        onRowRender = onLocationRowRender,
        onRowTouch = onLocationRowTouch,
        hideBackground = true,
        listener = locationListener
	})
	sceneGroup:insert( locationsTableView )
end

-- handle showing the scene. Here we will create text field, set the theme, open the DB, reload the 
-- user's locations and set the navBar label
function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		-- before the scene comes on screen open the city DB
		local path = system.pathForFile( "citydata.db", system.ResourceDirectory )
		myData.db = sqlite3.open( path )   
		-- reload the user's locations
		reloadData()
		-- set the navBar
		UI.navBar:setLabel( "Locations" )
		-- set the theme
		sceneBackground:setFillColor( unpack( theme.backgroundColor ) )
		locationLabel:setFillColor( unpack( theme.textColor ) )
	else
		local statusBarPad = display.topStatusBarContentHeight

		-- after the scene is on the screen
		-- calcuate how wide the text entry field will be (leave 20 px padding on both sides)
		local fieldWidth = display.contentWidth - 40
		-- create the text field and handler. Doing this before the scene is on the screen looks weird.
		locationEntryField = native.newTextField( 20, 120 + statusBarPad, fieldWidth, 30 )
		locationEntryField:addEventListener( "userInput", fieldHandler( function() return locationEntryField end ) ) 
		sceneGroup:insert( locationEntryField)
		locationEntryField.anchorX = 0
		locationEntryField.placeholder = "Location"		
	end
end

-- handle features when we need to hide the scene
function scene:hide( event )
	local sceneGroup = self.view
	
	if event.phase == "will" then
		-- before we leave the screen, close the database, since it was opened in show()
		myData.db:close()
		myData.db = nil
		-- remove the text field, since we created it in show().
		locationEntryField:removeSelf();
		locationEntryField = nil

	end

end

function scene:destroy( event )
	local sceneGroup = self.view
	-- place holder in case we need to destroy something later (not a usual thing if you created things correctly)	
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
return scene
