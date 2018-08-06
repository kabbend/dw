
local Window 		= require 'window'	-- Window class & system
local theme		= require 'theme'	-- global theme

-- we write only in debug mode
local oldiowrite = io.write
function io.write( data ) if debug then oldiowrite( data ) end end

-- rulesWindow class
-- a rulesWindow is a window which displays images. it is not zoomable
local rulesWindow = Window:new{ class = "rules" , title = "RULES" , buttons = { 'always', 'close' } , whResizable = true }

function rulesWindow:new( t ) -- create from w, h, x, y
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  self.im = theme.imageRules 
  self.mag = 1.0
  return new
end

function rulesWindow:draw()
  local W,H=self.layout.W, self.layout.H
  local zx,zy = -( self.x / self.mag - W / 2), -( self.y / self.mag - H / 2)
  love.graphics.setColor(theme.color.white)
  love.graphics.draw( self.im , zx , zy , 0 , 1 / self.mag, 1 / self.mag )
  -- print bar
  self:drawBar()
  self:drawResize()
  end

return rulesWindow

