
local Window 		= require 'window'	-- Window class & system
local theme		= require 'theme'	-- global theme
local rpg		= require 'rpg'

-- icons available in the window 
local icons    = {
	{ { 'tailler', theme.iconTailler , theme.imageTailler }, { 'salve', theme.iconSalve , theme.imageSalve}, { 'defendre', theme.iconDefendre , theme.imageDefendre}, {
'defier', theme.iconDefier, theme.imageDefier }, { 'discerner', theme.iconDiscerner , theme.imageDiscerner }, { 'etaler', theme.iconEtaler, theme.imageEtaler  }, { 'aider',
theme.iconAider, theme.imageAider }, { 'negocier', theme.iconNegocier, theme.imageNegocier }},
	{{'camp',theme.iconCamp,theme.imageCamp},{'recuperer',theme.iconRecuperer,theme.imageRecuperer},{'session',theme.iconSession,theme.imageSession},{'niveau',theme.iconNiveau,theme.imageNiveau},{'fail',theme.iconFail,theme.imageFail},{'soupir',theme.iconSoupir,theme.imageSoupir}},
	}

local iconSize = theme.iconSize
local iconMargin = 2

--
--

local actionsBar = Window:new{ 	class = "actions" , title = 'ACTIONS' , wResizable = false , hResizable = false, 
				alwaysOnTop = true, alwaysVisible = true , buttons = {'partialS','partialT','danger','potion', 'magic', 'name'} }

function actionsBar:new( t ) -- create from w, h, x, y
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  new.snapshots = icons 
  new.lines = 2
  new.columns = 8
  return new
end

function actionsBar:draw()

  self:drawBack()

  love.graphics.setColor(255,255,255)

  local zx,zy = -( self.x * 1/self.mag - self.layout.W / 2), -( self.y * 1/self.mag - self.layout.H / 2)
  for line = 1, self.lines do 
    for col = 1, self.columns do
	if icons[line] and icons[line][col] and icons[line][col][2] then
	  love.graphics.draw( icons[line][col][2] , zx + iconMargin + (col-1) * (iconSize + iconMargin), zy + iconMargin + (line-1) * (iconSize + iconMargin)) 
	end
    end
  end

  -- print bar
  self:drawBar()

  -- draw rules
  local x , y = love.mouse.getPosition()
  if layout:getFocus() == self and x >= zx and x <= zx + self.w and y >= zy and y <= zy + self.h then
    local l = math.floor( (y - zy) / (iconSize + iconMargin) ) + 1
    local c = math.floor( (x - zx) / (iconSize + iconMargin) ) + 1
    if icons[l] and icons[l][c] and icons[l][c][3] then
	love.graphics.draw( icons[l][c][3] , x + 5, y + 5 )
    end
  end


end

function actionsBar:click(x,y)

  local zx,zy = -( self.x - self.layout.W / 2), -( self.y - self.layout.H / 2)
  
  Window.click(self,x,y)

  end

return actionsBar

