
local theme = require 'theme'
local unpack = table.unpack or unpack
function color(c) return unpack(theme.color[c]) end
local oldiowrite = io.write
function io.write( data ) if debug then oldiowrite( data ) end end

-- Window class
-- a window is here an object slightly different from common usage, because
-- * a window may have the property to be zoomable, dynamically at runtime. This
--   is not the same as resizable, as its scale then changes (not only its frame)
--   For this reason, the important information about coordinates is not the
--   classical position (x,y) associated to the upper left corner of the window 
--   within the screen coordinate-system, but the point within the window itself,
--   expressed in the window-coordinate system, which is currently displayed at
--   the center of the screen (see the difference?). This point is an invariant
--   when the window zooms in or out.
-- * w and h are respectively width and height of the window, in pixels, but
--   expressed for the window at scale 1 (no zoom in or out). These dimensions
--   are absolute and will not change during the lifetime of the window object,
--   only the scaling factor will change to reflect a bigger (or smaller) object
--   actually drawn on the screen 
-- Notes: Windows are gathered and manipulated thru the mainLayout class 
--

-- sink motion
local sinkSteps = 25 
local border = 2

local Window = {class = "window", w = 0, h = 0, mag = 1.0, x = 0, y = 0 , title = "", 	-- base window information and shape
		zoomable = false ,							-- can we change the zoom ?
		buttons = { 'close' },							-- ordered list of buttons (when applicable)
											-- among:
											-- 'close', 'always', 'unquad', 'fulsize', 'kill', 'wipe'
		movable = true ,							-- can we move the window ?
	   	sticky = false, stickX = 0, stickY = 0, stickmag = 0 , 			-- FIXME: should be in map ?
		markForClosure = false,							-- event to close the window
		markForSink = false,							-- event to sink (gradually disappear)
	        alwaysOnTop = false, alwaysBottom = false , 				-- force layering
		wResizable = false, hResizable = false, whResizable = false, 		-- resizable for w and h
		widgets = {},								-- list of widgets in the window. Important: Inherited classes from Window
											-- should redeclare this table explicitely, otherwise all will share the same
											-- which is probably not the desired effect.
		layout = nil,								-- layout (although it is also global variable, at least for the moment)
		download = false,							-- download icon ? no by default
	  }

function Window:new( t ) 
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  new.markForSink = false
  new.markForUnsink = false
  new.markForSinkDeltax = 0 -- absolute delta per step (in pixels)
  new.markForSinkDeltay = 0
  new.markForSinkDeltaMag = 0
  new.markForSinkTimer = 0
  new.sinkSteps = 0
  return new
end

function Window:getButtonByPosition(position)
    io.write("getButtonByPosition, receiving " .. position .. " with array size " .. #self.buttons )
    if (position <= 0 or position > #self.buttons) then return nil end
    return self.buttons[position]
end


function Window:addWidget( widget ) table.insert( self.widgets, widget ); widget.parent = self end
 
-- window to screen, screen to window: transform x,y coordinates within the window from point on screen
function Window:WtoS(x,y) local W,H=self.layout.W, self.layout.H; return (x - self.x)/self.mag + W/2, (y - self.y)/self.mag + H/2 end

-- translate window by dx, dy pixels on screen, with unchanged mag factor 
function Window:translate(dx,dy) self.x = self.x - dx * self.mag; self.y = self.y - dy * self.mag end
	
-- request the window to sink at the given target position tx, ty on the screen, and covering a window
-- of width w on the screen
function Window:sink(tx,ty,w) 
	self.markForSink = true
	self.sinkFinalDisplay = false
	self.restoreSinkX, self.restoreSinkY, self.restoreSinkMag = self.x, self.y, self.mag
	local cx, cy = Window.WtoS(self,self.w/2, self.h/2)
	self.markForSinkDeltax, self.markForSinkDeltay = (tx - cx)/sinkSteps, (ty - cy)/sinkSteps
	local wratio = self.w / w
	self.markForSinkDeltaMag = (wratio - self.mag)/sinkSteps
	self.sinkSteps = 0
	self.markForSinkTimer = 0
	self.layout.sinkInProgress = true
	end
 	

-- request the window to unsink from source position sx, sy at the given target (window) position x,y, with mag factor 
function Window:unsink(sx, sy, sw, x, y, mag) 
	local W,H=self.layout.W, self.layout.H	
	self.markForSink = true
	self.sinkFinalDisplay = true
	local startingmag = self.w / sw
	self.markForSinkDeltaMag = (mag - startingmag) / sinkSteps
	-- where would be the window center on screen at the end ?
	self.mag = mag; self.x = x; self.y = y
	local cx, cy = Window.WtoS(self,self.w/2, self.h/2)
	self.markForSinkDeltax, self.markForSinkDeltay = (cx - sx)/sinkSteps, (cy - sy)/sinkSteps
	-- real starting data
	self.mag = startingmag; 
	self.x = self.w/2; self.y = self.h/2
	Window.translate(self,sx-W/2, sy-H/2) -- we apply the correct translation
	self.sinkSteps = 0
	self.markForSinkTimer = 0
	self.layout:setDisplay(self,true)
	self.layout.sinkInProgress = true
	end

-- return true if the point (x,y) (expressed in layout coordinates system,
-- typically the mouse), is inside the window frame (whatever the display or
-- layer value, managed at higher-level)
function Window:isInside(x,y)
  local W,H=self.layout.W, self.layout.H;
  local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
  return x >= zx and x <= zx + self.w / self.mag and 
  	 y >= zy - theme.iconSize and y <= zy + self.h / self.mag -- iconSize needed here to take window bar into account
end

function Window:zoom( mag ) if self.zoomable then self.mag = mag end end
function Window:move( x, y ) if self.movable then self.x = x; self.y = y end end
function Window:setTitle( title ) self.title = title end

-- drawn upper button bar
function Window:drawBar( )

 local W,H=self.layout.W, self.layout.H 
 -- reserve space for buttons 
 local reservedForButtons = theme.iconSize * #self.buttons

 -- reserve space on maps for mask symbol (circle or rect)
 local marginForRect = 0
 if self.class == "map" and self.kind == "map" then marginForRect = 20 end

 -- max space for title
 local availableForTitle = self.w / self.mag - reservedForButtons - marginForRect
 if availableForTitle < 0 then availableForTitle = 0 end 
 local numChar = math.floor(availableForTitle / theme.fontRound:getWidth("a"))
 local title = string.sub( self.title , 1, numChar ) 

 -- draw bar
 if self == self.layout:getFocus() then love.graphics.setColor(color('orange')) else love.graphics.setColor(color('grey')) end
 local lzx,lzy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
 local zx,zy = lzx, math.max(lzy,theme.iconSize) 
 love.graphics.rectangle( "fill", zx - border , zy - theme.iconSize , ((self.w) / self.mag)+2*border , theme.iconSize )

 -- draw icons. Positions are expressed from right to left, 1 is the rightmost one
 local position = #self.buttons
 love.graphics.setFont(theme.fontRound)

 for i=1,#self.buttons do
   local zxf = math.min(zx + self.w / self.mag, W)

   if self.buttons[i] == 'close' then
   	love.graphics.draw( theme.iconClose, zxf - position * theme.iconSize + 3, zy - theme.iconSize + 3)
   end
   if self.buttons[i] == 'always' then
     if self.alwaysOnTop then 	-- always on top, in position 2
 	love.graphics.draw( theme.iconOnTopActive, zxf - position*theme.iconSize+3 , zy - theme.iconSize+3)
     else
 	love.graphics.draw( theme.iconOnTopInactive, zxf - position*theme.iconSize+3 , zy - theme.iconSize+3)
     end
   end
   if self.buttons[i] == 'unquad' and self.quad then
   	love.graphics.draw( theme.iconExpand, zxf - position * theme.iconSize + 3, zy - theme.iconSize + 3)
   end
   if self.buttons[i] == 'kill' then
   	love.graphics.draw( theme.iconKill, zxf - position * theme.iconSize + 3, zy - theme.iconSize + 3)
   end
   if self.buttons[i] == 'wipe' then
   	love.graphics.draw( theme.iconWipe, zxf - position * theme.iconSize + 3, zy - theme.iconSize + 3)
   end
   if self.buttons[i] == 'fullsize' then
	if self.fullSize then
   		love.graphics.draw( theme.iconReduce, zxf - position * theme.iconSize + 3, zy - theme.iconSize + 3)
	else
   		love.graphics.draw( theme.iconFullSize, zxf - position * theme.iconSize + 3, zy - theme.iconSize + 3)
	end
   end
   position=position-1
 end

 -- print title
 if self == self.layout:getFocus() then love.graphics.setColor(255,255,255) else love.graphics.setColor(0,0,0) end
 love.graphics.print( title , zx + 3 + marginForRect , zy - theme.iconSize + 3 )

  -- draw small circle or rectangle in upper corner, to show which mode we are in
 love.graphics.setColor(255,0,0)
 if self.class == "map" and self.kind == "map" then
    if maskType == "RECT" then love.graphics.rectangle("line",zx + 5, zy - 16 ,12, 12) end
       if maskType == "CIRC" then love.graphics.circle("line",zx + 10, zy - 10, 5) end
 end

end

function Window:drawResize()
   local W,H=self.layout.W, self.layout.H
   local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
   love.graphics.draw( theme.iconResize, zx + self.w / self.mag - theme.iconSize + 3, zy + self.h/self.mag - theme.iconSize + 3)
end

function Window:drawBack()
  local W,H=self.layout.W, self.layout.H
  local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
  if self == self.layout:getFocus() then love.graphics.setColor(color('orange')) else love.graphics.setColor(color('grey')) end
  love.graphics.setLineWidth(border*2);
  love.graphics.rectangle( "line", zx, zy , ((self.w) / self.mag), (self.h / self.mag) )  
  love.graphics.setLineWidth(1);
  love.graphics.setColor(color('white'))
  love.graphics.rectangle( "fill", zx, zy, (self.w) / self.mag, (self.h) / self.mag )  
end

-- click in the window. Check some rudimentary behaviour (quit...)
function Window:click(x,y)
	local W,H=self.layout.W, self.layout.H
 	local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
 	local mx,my = self:WtoS(self.w, self.h) 
 	local tx, ty = mx - theme.iconSize, zy + 3
	tx, ty = math.min(tx,W-theme.iconSize), math.max(ty,0) + theme.iconSize

	local nButtons = #self.buttons
   	local zxf = math.min(zx + self.w / self.mag, W)
	local zyf = math.max(zy,theme.iconSize)

	if x >= zxf - nButtons * theme.iconSize and x <= zxf and y >= zyf - theme.iconSize and y <= zyf then
		-- click on a button . Which one ?
		local position = math.floor((x - (zxf - nButtons * theme.iconSize)) / theme.iconSize) + 1
		io.write("position=" .. position )
		local button = self:getButtonByPosition(position)
		io.write("button="..button )

		if (button == 'close') then 	
			-- click on Close
			self.markForClosure = true
			-- mark the window for a future closure. We don't close it right now, because
			-- there might be another object clickable just below that would be wrongly
			-- activated ( a yui button ). So we wait for the mouse release to perform
			-- the actual closure
			return self
		end

		if (button == 'always') then 	
			-- click on Always On Top 
			self.alwaysOnTop = not self.alwaysOnTop 
			self.layout:setOnTop(self, self.alwaysOnTop)
		end

		if (button == 'unquad') then 	
			-- click on Always On Top 
			-- click on Expand (for maps with quad)
			-- remove the quad. restore to initial size
			self:setQuad()
		end

		if (button == 'fullsize') then 	
			-- click on Maximize/Minimize at upper right corner 
			self:fullsize()	
		end
		if (button == 'kill') then 	
			self:killAll()	
		end
		if (button == 'wipe') then 	
			self:wipe()	
		end

 	end
	
	if x >= mx - theme.iconSize and y >= my - theme.iconSize then
		-- click on Resize at bottom right corner 
		if self.wResizable or self.hResizable or self.whResizable then mouseResize = true end
	elseif self.movable then
		-- clicking elsewhere, wants to move
		mouseMove = true
		arrowMode = false
		arrowStartX, arrowStartY = x, y
		arrowModeMap = nil
	end

	return nil
	end

function Window:update(dt) 

	local W,H=self.layout.W, self.layout.H
	if self.markForSink then 
			self.markForSinkTimer = 0
			self.sinkSteps = self.sinkSteps + 1
		
			-- we translate the window
			Window.translate(self,self.markForSinkDeltax, self.markForSinkDeltay)
			-- where is the center on screen now ?
			local cx, cy = Window.WtoS(self,self.w/2,self.h/2)
			-- we want the scale to change, but keeping the window center unchanged
			self.mag = self.mag + self.markForSinkDeltaMag
			local tx,ty = Window.WtoS(self,self.w/2,self.h/2) -- if doing nothing, we would be there
			Window.translate(self,cx-tx, cy-ty) -- we apply the correct translation
		
			if self.sinkSteps >= sinkSteps then 
				self.markForSink = false -- finish sink movement
				self.layout.sinkInProgress = false 
				-- disappear eventually
				if not self.sinkFinalDisplay then 
					self.layout:setDisplay(self, false) 
					self.minimized = true
				else
					self.minimized = false
				end	
			end
	end
	end

function Window:drawWidgets() for i=1,#self.widgets do self.widgets[i]:draw() end end 

-- to be redefined in inherited classes
function Window:draw() for i=1,#self.widgets do self.widgets[i]:draw() end end 
function Window:getFocus() end
function Window:looseFocus() end
function Window:drop() end

return Window

