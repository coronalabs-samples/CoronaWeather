--
-- CoronaWeather - A sample app
--
-- Demonstrate business app practices with this sample app.
--
-- weather.lua -- weather features common to multiple modules
--
local json = require( "json" )
local myData = require( "mydata" )
local M = {}

M.bearingLabels = { "N", "NNE", "NE", "ENE", "E", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N" }


function M.convertTemperature( baseValue, format )
    local temperature = baseValue
    if format == "fahrenheit" then
        temperature = temperature * 9 / 5 + 32
    end
    return temperature
end

function M.convertDistance( baseValue, format )
    local distance = baseValue
    if format == "miles" then
        distance = distance * 0.621371
    end
    return distance
end

local function processWeatherRequest( event )
	myData.currentWeatherData = json.decode(event.response)
    myData.lastRefresh = os.time()
    M.callBack()
end

function M.fetchWeather( callBack )
	M.callBack = callBack

    myData.latitude = myData.settings.locations[1].latitude
    myData.longitude = myData.settings.locations[1].longitude
    for i = 1, #myData.settings.locations do
        if myData.settings.locations[i].selected then
            myData.latitude = myData.settings.locations[i].latitude
            myData.longitude = myData.settings.locations[i].longitude
            break
        end
    end

    local forecastIOURL = "https://api.forecast.io/forecast/" .. myData.forecastIOkey .. "/" .. tostring(myData.latitude) .. "," .. tostring(myData.longitude)
    forecastIOURL = forecastIOURL .. "?units=si"
    print( forecastIOURL )
    local now = os.time()
    print("cache test", now, myData.lastRefresh )
    if now > myData.lastRefresh + (15 * 60) then
        network.request( forecastIOURL, "GET", processWeatherRequest )
    else
        print("showing cached data")
        M.callBack( )
    end
end

return M