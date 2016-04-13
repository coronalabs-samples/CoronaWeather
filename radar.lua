local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local myData = require( "mydata" )
local utility = require( "utility" )

local header = [[<!DOCTYPE html>
<html>
  <head>
    <title>Google Maps JavaScript API v3 Example: Map Simple</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <meta charset="utf-8">
    <style>
      html, body, #map_canvas {
        margin: 0;
        padding: 0;
        height: 100%;
      }
    </style>
    <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBdqvI6314EdxCqf4xStHWDWdiN1m5znqk"></script>
    <script>
      var map;
      var radarOverlay;
      var mapBounds;
      var API_calls = 0;
      var rateLimitTimer;
]]
local body = [[      function initialize() {
        var myLatLong = new google.maps.LatLng(latitude, longitude);
        var mapOptions = {
          zoom: 8,
          center: myLatLong,
          mapTypeId: google.maps.MapTypeId.ROADMAP,
          zoomControl: false,
          scaleControl: false,
          panControl: false,
          streetViewControl: false,
          overviewMapContro: false
        };
        map = new google.maps.Map(document.getElementById('map_canvas'),
            mapOptions);
/*
        tileNEX = new google.maps.ImageMapType({
            getTileUrl: function(tile, zoom) {
                return "http://mesonet.agron.iastate.edu/cache/tile.py/1.0.0/nexrad-n0q-900913/" + zoom + "/" + tile.x + "/" + tile.y +".png?"+ (new Date()).getTime(); 
            },
            tileSize: new google.maps.Size(256, 256),
            opacity:0.75,
            name : 'NEXRAD',
            isPng: true
        });

*/
        google.maps.event.addListener(map, 'idle', function() {
            API_calls++;
            if (API_calls > 9) {
                // rate limit
                return(true);
            } 
            var center = map.getCenter();
            var bounds = map.getBounds();
            var zoom = map.getZoom();
            ne = bounds.getNorthEast();
            sw = bounds.getSouthWest();
            var URL = 'http://api.wunderground.com/api/63786a2636b67f31/animatedradar/image.gif?num=5&delay=50&maxlat=' + ne.lat() + '&maxlon=' + sw.lng() + '&minlat=' + sw.lat() + '&minlon=' + ne.lng() + '&width=' + screenWidth + '&height=' + screenHeight + '&rainsnow=1&smooth=1&noclutter=1';
            if (radarOverlay) {
              radarOverlay.setMap(null);
            }
            radarOverlay = new google.maps.GroundOverlay( URL, bounds );
            radarOverlay.setMap(map);
        });

        rateLimitTimer = setInterval(function () {
            API_calls--;
            if (API_calls < 0) {
                API_calls = 0;
            }
        }, 15000);


        /*
        goes = new google.maps.ImageMapType({
            getTileUrl: function(tile, zoom) {
                return "http://mesonet.agron.iastate.edu/cache/tile.py/1.0.0/goes-east-vis-1km-900913/" + zoom + "/" + tile.x + "/" + tile.y +".png?"+ (new Date()).getTime(); 
            },
            tileSize: new google.maps.Size(256, 256),
            opacity:0.30,
            name : 'GOES East Vis',
            isPng: true
        });

        map.overlayMapTypes.push(null); // create empty overlay entry
        map.overlayMapTypes.setAt("0",goes);
        */
        //map.overlayMapTypes.push(null); // create empty overlay entry
        //map.overlayMapTypes.setAt("1",tileNEX);

        
      }

      google.maps.event.addDomListener(window, 'load', initialize);
    </script>
  </head>
  <body>
    <div id="map_canvas"></div>
  </body>
</html>]]


local params
local webView

local function radarListener( event )
    utility.print_r( event )
    scene.view:insert( event.target )
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
    

end

function scene:show( event )
    local sceneGroup = self.view

    params = event.params

    --local URL = "http://api.wunderground.com/api/" .. myData.wuAPIkey .. "/animatedradar/q/" .. myData.settings.state .. "/" .. myData.settings.city .. ".gif?newmaps=1&timelabel=1&timelabel.y=10&num=15&delay=50&radius=10&rainsnow=1&smooth=1&noclutter=1&width=" .. display.contentWidth .. "&height=" .. display.contentHeight - 50
    if event.phase == "will" then
        local path = system.pathForFile( "radar.html" , system.TemporaryDirectory )
        local fp = io.open( path, "w" )
        if fp then
            fp:write(header)
            fp:write("var latitude = " .. tostring(35.7789) .. ";\n")
            fp:write("var longitude = " .. tostring(-78.8003) .. ";\n")
            fp:write("var screenWidth = " .. tostring( display.contentWidth) .. ";\n")
            fp:write("var screenHeight = " .. tostring( display.contentHeight - 50) .. ";\n")
            fp:write(body)
            fp:close()
        end
    else
        --display.loadRemoteImage( URL, "GET", radarListener, "radar.gif", system.CachesDirectory, display.contentCenterX, display.contentCenterY - 25 )
        webView = native.newWebView( display.contentCenterX, display.contentCenterY - 25, display.contentWidth, display.contentHeight - 50 )
        local path = system.pathForFile( "radar.html" , system.TemporaryDirectory )
        local fp = io.open( path, "r" )
        if fp then
            fp:close();
            webView:request( "radar.html", system.TemporaryDirectory )
        else
            webView:request( "radar.html", system.ResourceDirectory )
        end            
    end
end

function scene:hide( event )
    local sceneGroup = self.view
    
    if event.phase == "will" then
        webView:removeSelf()
        webView = nil
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
