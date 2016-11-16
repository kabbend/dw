
local Window 	= require 'window'
local theme 	= require 'theme'

--
-- notificationWindow class
-- a notificationWindow is a window which displays a temporary message in the background . it is not zoomable, movable, no window bar
-- and always at bottom
--

local notificationWindow = Window:new{ class = "notification", alwaysOnTop = true, zoomable = false, movable = false }

function notificationWindow:new( t ) -- create from w, h, x, y, messages
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  new.messages = t.messages
  new.opening = false
  new.closing = false
  new.pause   = false
  new.maxX = t.x + t.w - 10 
  new.minX = t.x 
  return new
end

function notificationWindow:draw()
  local zx,zy = -( self.x/self.mag - W / 2), -( self.y/self.mag - H / 2)
  love.graphics.setColor(255,255,255)
  love.graphics.rectangle( "fill", zx, zy, self.w, self.h, 10, 10 ) 
  love.graphics.setColor(0,0,0)
  love.graphics.setFont(theme.fontRound)
  if self.text then love.graphics.printf( self.text, zx + 10, zy + 5, self.w - 20 ) end
  end

function notificationWindow:update(dt)
  if not self.text and #self.messages ~= 0 then
	self.text = self.messages[1].text
	table.remove(self.messages,1)
 	self.opening = true 
	self.layout:setDisplay(self,true)
  end
  if self.opening and self.x <= self.maxX then 
	self.x = self.x + 3 
	if self.x > self.maxX then self.opening = false; self.pause = true; self.closing = false; self.pauseTimer = 3  end
  end
  if self.pause then
	self.pauseTimer = self.pauseTimer - dt
	if self.pauseTimer < 0 then self.pause = false; self.closing = true end
  end
  if self.closing and self.x >= self.minX then 
	self.x = self.x - 3 
	if self.x < self.minX then self.closing = false; self.text = nil ; self.layout:setDisplay(self,false) end
  end
  end

function notificationWindow:click(x,y)
  self.opening = false
  self.pause = false
  self.closing = true
  end

return notificationWindow
