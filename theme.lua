-- theme.lua

local M = {}

M.backgroundColor = { 0.95, 0.95, 0.95 }
M.textColor = { 0, 0, 0 }
M.navBarBackgroundColor = { 1, 1, 1 }
M.navBarTextColor = { 0, 0, 0 }
M.font = "Roboto-Thin.ttf"
M.fontBold = "Roboto-Regular.ttf"

function M.setTheme( scheme )
	if scheme == "light" then
		M.backgroundColor = { 0.95, 0.95, 0.95 }
		M.textColor = { 0, 0, 0 }
		M.navBarBackgroundColor = { 1, 1, 1 }
		M.navBarTextColor = { 0, 0, 0 }
	else
		M.backgroundColor = { 0.05, 0.05, 0.05 }
		M.textColor = { 1, 1, 1 }
		M.navBarBackgroundColor = { 0.2, 0.2, 0.2 }
		M.navBarTextColor = { 1, 1, 1 }
	end
	display.setDefault( "background", unpack( M.backgroundColor ) )
end

return M