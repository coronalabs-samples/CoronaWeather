--
-- CoronaWeather - A sample app
--
-- Demonstrate business app practices with this sample app.
--
-- weather.lua -- weather features common to multiple modules
--
local json = require( "json" )
local myData = require( "classes.mydata" )

local M = {}

-- define the directional labels
M.bearingLabels = { "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N" }

-- We will always fetch the data is metric. There are times we want the temperature in
-- fahrenheit. This function will handle covnersions
function M.convertTemperature( baseValue, format )
    local temperature = baseValue
    if format == "fahrenheit" then
        temperature = temperature * 9 / 5 + 32
    end
    return temperature
end

-- Same as temperature, our distances will be in kilometers, this will, if selected return miles
function M.convertDistance( baseValue, format )
    local distance = baseValue
    if distance == nil then 
        return 0
    end
    if format == "miles" then
        distance = distance * 0.621371
    end
    return distance
end

-- This function is called if we need to actually query the server.     
local function processWeatherRequest( event )
	myData.currentWeatherData = json.decode(event.response)
    myData.lastRefresh = os.time()
    if M.callBack then
        M.callBack()
    end
end

-- Retrieve the weather. This will take a call back function to display the weather after
-- it's retrieved from the server. 
function M.fetchWeather( callBack )
	M.callBack = callBack

    -- Look for a selected location. If not, use the defaults 

    if #myData.settings.locations > 0 then
        myData.latitude = myData.settings.locations[1].latitude
        myData.longitude = myData.settings.locations[1].longitude
        myData.currentLocation = myData.settings.locations[1].name
        for i = 1, #myData.settings.locations do
            if myData.settings.locations[i].selected then
                myData.latitude = myData.settings.locations[i].latitude
                myData.longitude = myData.settings.locations[i].longitude
                myData.currentLocation = myData.settings.locations[i].name
                break
            end
        end
    else
        native.showAlert( "Error", "You don't have any locations selected.", { "Okay "} )
    end

    print( "*** Fetching Weather ***")
    local forecastIOURL = "https://api.forecast.io/forecast/" .. myData.forecastIOkey .. "/" .. tostring(myData.latitude) .. "," .. tostring(myData.longitude) .. "?units=si"
    network.request( forecastIOURL, "GET", processWeatherRequest )

--[[
    local now = os.time()

    if now > myData.lastRefresh + (15 * 60) then
        network.request( forecastIOURL, "GET", processWeatherRequest )
    else
        if M.callBack then
            M.callBack( )
        end
    end
--]]
end

return M