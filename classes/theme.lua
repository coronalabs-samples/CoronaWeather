--
-- Corona Weather - A business style sample app
--
-- MIT Licensed
--
-- theme.lua a simple object to hold the colors and font definitions the app uses. 
-- As well as a funtion to change the colors as needed.

-- Simple data bits for the colors and fonts
-- Also provide a function to set the theme.

local M = {}

M.backgroundColor = { 0.95, 0.95, 0.95 }
M.textColor = { 0, 0, 0 }
M.navBarBackgroundColor = { 1, 1, 1 }
M.navBarTextColor = { 0, 0, 0 }
M.rowBackgroundColor = { 1, 1, 1 }
M.font = "fonts/Roboto-Thin.ttf"
M.fontBold = "fonts/Roboto-Regular.ttf"
M.name = "light"

function M.setTheme( scheme )
	if scheme == "light" then
		M.backgroundColor = { 0.95, 0.95, 0.95 }
		M.textColor = { 0, 0, 0 }
		M.navBarBackgroundColor = { 1, 1, 1 }
		M.navBarTextColor = { 0, 0, 0 }
		M.rowBackgroundColor = { 1, 1, 1 }
		M.name = "light"
	else
		M.backgroundColor = { 0.05, 0.05, 0.05 }
		M.textColor = { 1, 1, 1 }
		M.navBarBackgroundColor = { 0.2, 0.2, 0.2 }
		M.navBarTextColor = { 1, 1, 1 }
		M.rowBackgroundColor = { 0.2, 0.2, 0.2 }
		M.name = "dark"
	end
	display.setDefault( "background", unpack( M.backgroundColor ) )
end

return M