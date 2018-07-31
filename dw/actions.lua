
local Window 		= require 'window'	-- Window class & system
local theme		= require 'theme'	-- global theme
local rpg		= require 'rpg'

-- rule images, will be loaded in main.lua at startup
rules = {}


local iconSize = theme.iconSize
local iconMargin = 2

--
--

local actionsBar = Window:new{ 	class = "actions" , title = 'ACTIONS' , wResizable = false , hResizable = false, 
				alwaysOnTop = true, alwaysVisible = true , buttons = {'danger','potion', 'magic', 'name'} }

--
-- new actions window
--
function actionsBar:new( t ) -- create from w, h, x, y

  local new = t or {}
  setmetatable( new , self )
  self.__index = self

  -- structure of the window. 
  -- This could be improved, as it must be consistent with the size of the window in main.lua, and nothing prevents potential inconsistency...
  new.lines = 2
  new.columns = 7

  -- actual icons available in the window 
  -- { name , icon-image (32x32), snapshot of the rule }
  new.icons    = {
	{
	  { 'tailler', theme.iconTailler , rules["tailler"] }, 
	  { 'salve', theme.iconSalve , rules["salve"] }, 
	  { 'defendre', theme.iconDefendre , rules["defendre"] }, 
	  { 'defier', theme.iconDefier, rules["defier"] }, 
	  { 'discerner', theme.iconDiscerner , rules["discerner"] }, 
	  { 'etaler', theme.iconEtaler, rules["etaler"]  }, 
	  { 'aider', theme.iconAider, rules["aider"] }},
	 {
	  { 'negocier', theme.iconNegocier, rules["negocier"] }, 
	  { 'camp',theme.iconCamp, rules["camp"] },
	  { 'recuperer',theme.iconRecuperer, rules["recuperer"] },
	  { 'session',theme.iconSession,rules["session"]},
	  { 'niveau',theme.iconNiveau,rules["niveau"]},
	  { 'fail',theme.iconFail,rules["fail"]},
	  { 'soupir',theme.iconSoupir, rules["soupir"] }
	 },
	}
  return new
end

--
-- draw the window but also, when we pass mouse over an icon, we display the rule on the screen for the gamemaster
--
function actionsBar:draw()

  self:drawBack()

  love.graphics.setColor(255,255,255)

  local zx,zy = -( self.x - self.layout.W / 2), -( self.y - self.layout.H / 2)
  for line = 1, self.lines do 
    for col = 1, self.columns do
	if self.icons[line] and self.icons[line][col] and self.icons[line][col][2] then
	  love.graphics.draw( self.icons[line][col][2] , zx + iconMargin + (col-1) * (iconSize + iconMargin), zy + iconMargin + (line-1) * (iconSize + iconMargin)) 
	end
    end
  end

  -- print bar
  self:drawBar()

  -- draw a rule eventually
  local x , y = love.mouse.getPosition()
  if layout:getFocus() == self and x >= zx and x <= zx + self.w and y >= zy and y <= zy + self.h then
    local l = math.floor( (y - zy) / (iconSize + iconMargin) ) + 1
    local c = math.floor( (x - zx) / (iconSize + iconMargin) ) + 1
    if self.icons[l] and self.icons[l][c] and self.icons[l][c][3] then
	love.graphics.draw( self.icons[l][c][3].im , x + 5, y + 5 )
    end
  end


end

--
-- when we click on an icon (except 'fail', which is reserverd for gamemaster), we display that rule in the projector
-- so the players can read it
--
function actionsBar:click(x,y)

  local zx,zy = -( self.x - self.layout.W / 2), -( self.y - self.layout.H / 2)

  if (y - zy) >= 0 then  -- only if not clicking on the button bar

   local line = math.floor((y - zy) / (iconSize + iconMargin))+1
   local col = math.floor((x - zx) / (iconSize + iconMargin))+1

   if self.icons[line] and self.icons[line][col] and self.icons[line][col][3] and self.icons[line][col][1] ~= "fail" then
  	layout.pWindow.currentImage = self.icons[line][col][3].im
        layout.pWindow.o = nil
        -- remove the 'visible' flag from maps (eventually)
        atlas:removeVisible()
        tcpsend(projector,"ERAS")       -- remove all pawns (if any) 
        -- send the filename over the socket
        tcpsendBinary{ file = self.icons[line][col][3].file }
        tcpsend(projector,"BEOF")
        tcpsend( projector, "DISP")     -- display immediately
   end
 
  else 
	-- click on the button bar or moving the window 
  	Window.click(self,x,y)
  end
  end

return actionsBar

