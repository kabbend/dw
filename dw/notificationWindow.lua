
local Window 	= require 'window'
local theme 	= require 'theme'
local unpack = table.unpack or unpack
function color(c) return unpack(theme.color[c]) end

--
-- notificationWindow class
-- a notificationWindow is a window which displays a temporary message in the background . it is not zoomable, movable, no window bar
-- and always at bottom
--

local notificationWindow = Window:new{ class = "notification", alwaysOnTop = true, zoomable = false, movable = false, buttons = {} }

function notificationWindow:new( t ) -- create from w, h, x, y
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  new.opening = false
  new.closing = false
  new.pause   = false
  new.maxX = t.x + t.w - 15
  new.minX = t.x 
  new.messages = {}
  return new
end

-- insert a new message to display
function notificationWindow:addMessage( text, time , colorName, important )
  if not time then time = 5 end
  if not colorName then colorName = 'red' end
  table.insert( self.messages, { text=text , time=time, color=colorName, offset=0, important=important } )
end

function notificationWindow:draw()
  local W,H=self.layout.W, self.layout.H
  local zx,zy = -( self.x/self.mag - W / 2), -( self.y/self.mag - H / 2)
  --love.graphics.setColor(255, 51, 51)
  love.graphics.setColor(color(self.color))
  love.graphics.rectangle( "fill", zx, zy, self.w, self.h, 10, 10 ) 
  love.graphics.setColor(color('white'))
  love.graphics.setFont(theme.fontTitle)
  if self.text then love.graphics.printf( self.text, zx + 10, zy + 5, self.w - 20 ) end
  if (#self.messages >= 1) then
    love.graphics.setColor(color(self.color))
    --love.graphics.setColor(255, 51, 51)
    love.graphics.circle("fill",W-13,zy-8,13)
    love.graphics.setColor(0,0,0)
    love.graphics.circle("line",W-13,zy-8,13)
    love.graphics.setFont(theme.fontRound)
    love.graphics.setColor(color('white'))
    love.graphics.print(#self.messages,W-16,zy-16)
  end
  end

function notificationWindow:update(dt)
  if not self.text and #self.messages ~= 0 then
	self.text = self.messages[1].text
	self.timer = self.messages[1].time
	self.color = self.messages[1].color
	table.remove(self.messages,1)
 	self.opening = true 
	self.layout:setDisplay(self,true)
  end
  if self.opening and self.x <= self.maxX then 
	self.x = self.x + 10
	if self.x > self.maxX then self.opening = false; self.pause = true; self.closing = false; self.pauseTimer = self.timer  end
  end
  if self.pause then
	self.pauseTimer = self.pauseTimer - dt
	if self.pauseTimer < 0 then self.pause = false; self.closing = true end
  end
  if self.closing and self.x >= self.minX then 
	self.x = self.x - 10 
	if self.x < self.minX then self.closing = false; self.text = nil ; self.layout:setDisplay(self,false) end
  end
  end

function notificationWindow:click(x,y)
  self.opening = false
  self.pause = false
  self.closing = true
  end

return notificationWindow

