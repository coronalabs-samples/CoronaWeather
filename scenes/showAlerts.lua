--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- showAlerts.lua -- Used to display severe weather alerts when detected in the currentConditions module.
--
local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )

local wx = require( "classes.weather" )
local myData = require( "classes.mydata" )
local theme = require( "classes.theme" )

local params

local function dismissAlerts( event )
    if "ended" == event.phase then
        composer.hideOverlay(  "crossFade", 250 )
    end
    return true
end

local function onRowRender( event )
    local row = event.row
    local params = event.row.params
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    if params.label then -- it's the header row 
        local title = display.newText( params.label, rowWidth * 0.5, rowHeight * 0.5, theme.fontBold, 20 )
        row:insert( title )
        local closeButtonBG = display.newCircle( rowWidth - 10, 12, 10 )
        row:insert( closeButtonBG )
        closeButtonBG:setFillColor( 1, 1, 1, 0.25 )
        local closeButtonX = display.newText( "×", closeButtonBG.x + 1, closeButtonBG.y - 1.5, theme.font, 16 )
        closeButtonX:setFillColor( 1 )
        row:insert( closeButtonX )
        closeButtonX:addEventListener( "touch", dismissAlerts )
    else
        local title = display.newText( params.title, rowWidth * 0.5, 10, theme.fontBold, 12 )
        row:insert( title )
        title:setFillColor( 1 )
        local descr = display.newText({
            parent = row,
            text = params.description,     
            x = rowWidth * 0.5,
            y = 25,
            width = rowWidth - 20,     --required for multi-line and alignment
            font = theme.font,   
            fontSize = 10,
            align = "left"  --new alignment parameter
        })
        descr.anchorY = 0
    end
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
    local alerts = myData.currentWeatherData.alerts
    local testAlerts = { {
                          expires = 1463029200,
                          title = "Special Weather Statement for Jefferson, KY",
                          description = "...A CLUSTER OF STRONG THUNDERSTORMS WILL AFFECT EASTERN JEFFERSON...\nSOUTHERN HENRY...SOUTHERN OLDHAM...WESTERN FRANKLIN...SPENCER...\nNORTHEASTERN NELSON...NORTHEASTERN BULLITT...SHELBY AND WESTERN\nANDERSON COUNTIES...\nAT 920 PM EDT...A CLUSTER OF STRONG THUNDERSTORMS WAS ALONG A LINE\nEXTENDING FROM NEAR LA GRANGE TO NEAR TAYLORSVILLE TO 9 MILES NORTH\nOF BARDSTOWN...AND MOVING EAST AT 45 MPH.\nWIND GUSTS UP TO 50 MPH AND PEA SIZE HAIL ARE POSSIBLE WITH THESE\nSTORMS. THE STRONGEST WIND GUSTS WILL BE AHEAD OF THE ACTUAL STORMS\nWITH THE GUST FRONT.\nLOCATIONS IMPACTED INCLUDE...\nJEFFERSONTOWN...SHELBYVILLE...SHEPHERDSVILLE...LYNDON...LA GRANGE...\nMIDDLETOWN...DOUGLASS HILLS...HURSTBOURNE...ANCHORAGE AND HURSTBOURNE\nACRES.\n",
                          uri = "http://alerts.weather.gov/cap/wwacapget.php?x=KY1255FC282F44.SpecialWeatherStatement.1255FC28C350KY.LMKSPSLMK.5f732e85207c691b7e3cb535ac24a95d",
                          time = 1463016060
                        },{
                          expires= 1463029200,
                          title = "Severe Thunderstorm Watch for Jefferson, KY",
                          description = "SEVERE THUNDERSTORM WATCH 171 IS IN EFFECT UNTIL 1200 AM CDT\nFOR THE FOLLOWING LOCATIONS\nKY\n.    KENTUCKY COUNTIES INCLUDED ARE\nBRECKINRIDGE         BULLITT             BUTLER\nCALDWELL             CRITTENDEN          DAVIESS\nGRAYSON              HANCOCK             HARDIN\nHENDERSON            HOPKINS             JEFFERSON\nLIVINGSTON           MCLEAN              MEADE\nMUHLENBERG           OHIO                OLDHAM\nUNION                WEBSTER\n",
                          uri = "http://alerts.weather.gov/cap/wwacapget.php?x=KY1255FC1C49F4.SevereThunderstormWatch.1255FC28C350KY.WNSWOU1.58029d17feace019b060580807ed117a",
                          time = 1463009100
                        }}

    --
    -- Lets get all the weather bits we are interested in
    --
    --alerts = testAlerts
    print( json.prettify( alerts ) , #alerts)

    -- make a rectangle for the backgrouned and color it to the current theme
    local sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    sceneGroup:insert( sceneBackground )
    sceneBackground:setFillColor( 0, 0, 0, 0.25 )
    sceneBackground:addEventListener( "touch", dismissAlerts )

    local alertBackground = display.newRoundedRect( sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth - 40, display.actualContentHeight - 210, 12 )
    alertBackground:setFillColor( 0.25, 0, 0)
    alertBackground:setStrokeColor( 0.9, 0.8, 0.8 )
    alertBackground.strokeWidth = 2

    local tableView = widget.newTableView({
        height = alertBackground.height - 40, 
        width = alertBackground.width - 40,
        onRowRender = onRowRender,
        backgroundColor = { 0.25, 0, 0 },
        hideBackground = true,
    })
    tableView.x = display.contentCenterX
    tableView.y = display.contentCenterY
    sceneGroup:insert( tableView )
    tableView:insertRow({
        isCategory = false,
        rowHeight = 30,
        rowColor = { default = { 0.25, 0, 0 } },
        lineColor = { 0.75, 0.5, 0.5 },
        params = { label = "Alert!" }
    })
    for i = 1, #alerts do
        local tmpText = display.newText({
            text = alerts[i].description,     
            width = tableView.width - 20,     --required for multi-line and alignment
            font = theme.font,   
            fontSize = 10,
            align = "left"  --new alignment parameter
        })
        local rowHeight = tmpText.height + 30
        tmpText:removeSelf()
        tmpText = nil
        tableView:insertRow({
            isCategory = true,
            rowHeight = rowHeight,
            rowColor = { default = { 0.25, 0, 0 } },
            lineColor = { 0.75, 0.5, 0.5 },
            params = { title = alerts[i].title, description = alerts[i].description, alertTime = alerts[i].time, expiresTime = alerts[i].expires }
        })
    end



end

function scene:show( event )
    local sceneGroup = self.view


    if event.phase == "did" then

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
