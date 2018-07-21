
local Window 		= require 'window'		-- Window class & system
local Snapshot		= require 'snapshotClass'	-- store and display one image 
local theme		= require 'theme'		-- global theme
local Pawn		= require 'pawn'		-- store and display one pawn to display on map 
local rpg		= require 'rpg'		
local utf8		= require 'utf8'		
local codepage		= require 'codepage'		-- windows cp1252 support

local glowCode = [[
extern vec2 size;
extern int samples = 5; // pixels per axis; higher = bigger glow, worse performance
extern float quality = 2.5; // lower = smaller glow, better quality
 
vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
{
  vec4 source = Texel(tex, tc);
  vec4 sum = vec4(0);
  int diff = (samples - 1) / 2;
  vec2 sizeFactor = vec2(1) / size * quality;
  
  for (int x = -diff; x <= diff; x++)
  {
    for (int y = -diff; y <= diff; y++)
    {
      vec2 offset = vec2(x, y) * sizeFactor;
      sum += Texel(tex, tc + offset);
    }
  }
  
  return ((sum / (samples * samples)) + source) * colour;
} ]]

local lastPawn = nil
local lastPawnTimer = 0
local lastPawnTimerDelay = 1	-- sec to activate the timer

-- for scenario search
local textBase                = "Search: "
local text                    = textBase              -- text printed on the screen when typing search keywords
local searchIterator          = nil                   -- iterator on the results, when search is done
local searchPertinence        = 0                     -- will be set by using the iterator, and used during draw
local searchIndex             = 0                     -- will be set by using the iterator, and used during draw
local searchSize              = 0                     -- idem

-- map placement at startup
local mapOpeningSize          = 400                   -- approximate width size at opening
local mapOpeningXY            = 250                   -- position to open next map, will increase with maps opened
local mapOpeningStep          = 8                     -- increase x,y at each map opening

--
-- Multiple inheritance mechanism
-- call CreateClass with any number of existing classes 
-- to create the new inherited class
--

-- look up for `k' in list of tables `plist'
local function Csearch (k, plist)
	for i=1, table.getn(plist) do
	local v = plist[i][k] -- try `i'-th superclass
	if v then return v end
	end
	end

local function createClass (a,b)
	local c = {} -- new class
	setmetatable(c, {__index = function (t, k) return Csearch(k, {a,b}) end})
	c.__index = c
	function c:new (o) o = o or {}; setmetatable(o, c); return o end
	return c
	end

-- some convenient file loading functions (based on filename or file descriptor)
local function loadDistantImage( filename )
 
  if __WINDOWS__ then filename =  codepage.utf8tocp1252(filename) end
  local file = assert( io.open( filename, 'rb' ) )
  local image = file:read('*a')
  file:close()
  return image  
end

local function loadLocalImage( file )
  file:open('r')
  local image = file:read()
  file:close()
  return image
end

local lfn = love.filesystem.newFileData
local lin = love.image.newImageData
local lgn = love.graphics.newImage

-- Map class
-- a Map inherits from Window and from Snapshot, and is referenced both 
-- in the Atlas and in the snapshots list
-- It has the following additional properties
-- * it displays a jpeg image, a map, on which we can put and move pawns
-- * it can be of kind "map" (the default) or kind "scenario"
-- * it can be visible, meaning it is displayed to the players on
--   the projector, in realtime. There is maximum one visible map at a time
--   (but there may be several maps displayed on the server, to the MJ)

local Map = createClass( Window , Snapshot )

function Map:lazyLoad()
  	local img = lgn(lin(self.fileData), { mipmaps=true } )
  	--local success, img = pcall(function() return lgn(lin(self.fileData), { mipmaps=true } ) end)
  	img:setMipmapFilter( "nearest" )
  	--pcall(function() img:setMipmapFilter( "nearest" ) end)
  	local mode, sharpness = img:getMipmapFilter( )
  	io.write("map lazy load: mode, sharpness = " .. tostring(mode) .. " " .. tostring(sharpness) .. "\n")
	self.im = img
  end

function Map:load( t ) -- create from filename or file object (one mandatory). kind is optional
  local t = t or {}
  if not t.kind then self.kind = "map" else self.kind = t.kind end 
  self.class = "map"
  self.buttons = { 'unquad', 'scotch', 'eye', 'fog', 'fullsize', 'kill', 'wipe', 'round', 'always', 'close' } 
  self.layout = t.layout
 
  -- snapshot part of the object
  assert( t.filename or t.file )
  local image
  if t.filename then
	self.filename = t.filename 
	image = loadDistantImage( self.filename )
	self.is_local = false
	self.baseFilename = string.gsub(self.filename,baseDirectory,"")
	self.displayFilename = splitFilename(self.filename)
  else 
	self.file = t.file
	image = loadLocalImage( self.file )
	self.is_local = true
	self.baseFilename = self.file:getFilename() 
	self.displayFilename = splitFilename(self.file:getFilename())
  end
  self.title = self.displayFilename or ""
  local success, img 
  self.fileData = lfn(image, 'img', 'file') -- store data for further usage 
  if self.kind == "map" then
	success, img = pcall(function() return lgn(lin(self.fileData) ) end)
  	--success, img = pcall(function() return lgn(lin(lfn(image, 'img', 'file')), { mipmaps=true } ) end)
  	--pcall(function() img:setMipmapFilter( "nearest" ) end)
  	--local mode, sharpness = img:getMipmapFilter( )
  	--io.write("map load: mode, sharpness = " .. tostring(mode) .. " " .. tostring(sharpness) .. "\n")
  else
	-- scenario ? DEPRECATED
	--success, img = pcall(function() return lgn(lin(lfn(image, 'img', 'file')) ) end)
  end
  self.im = img
  self.w, self.h = self.im:getDimensions()
  local f1, f2 = self.layout.snapshotSize / self.w, self.layout.snapshotSize / self.h
  self.snapmag = math.min( f1, f2 )
  self.thumb = createThumbnail(self.im,self.snapmag)
 
  -- now we have the snapshot, we remove the full image and keep only the fileData
  self.im = nil
  collectgarbage()
  self.showIcons = nil		-- pawn on which we must display the icons
  self.showIconsX = 0 
  self.showIconsY = 0 
 
  self.selected = false
  -- window part of the object
  self.zoomable = true
  self.whResizable = true
  self.mag = self.w / mapOpeningSize	-- we set ratio so we stick to the required opening size	
  self.x, self.y = self.w/2, self.h/2
  Window.translate(self,mapOpeningXY-self.layout.W/2,mapOpeningXY-self.layout.H/2) -- set correct position
 
  mapOpeningXY = mapOpeningXY + mapOpeningStep
 
  -- specific to the map itself. By default a map is completely masked by the fog of war
  if self.kind == "map" then 
	self.mask = { "RECT 0 0 0 0" } -- we always create a "dummy" mask, to it is sent to the projector and the map is hidden to players 
  else
	self.mask = nil
  end
  self.highlight = false
  self.step = 50
  self.pawns = {}
  self.basePawnSize = nil -- base size for pawns on this map (in pixels, for map at scale 1)
  self.shader = love.graphics.newShader( glowCode ) 
  self.quad = nil
  self.translateQuadX, self.translateQuadY = 0,0
  self.fullSize = false

  -- outmost limits of the current mask
  self.maskMinX, self.maskMaxX, self.maskMinY, self.maskMaxY = 100 * self.w , -100 * self.w, 100 * self.h, - 100 * self.h 
end

function Map:setQuad(x1,y1,x2,y2)
        local W,H=self.layout.W,self.layout.H
	if not x1 then 
		-- setQuad() with no arguments removes the quad 
		self.quad = nil 
		self.w, self.h = self.im:getDimensions()
  		local f1, f2 = self.layout.snapshotSize / self.w, self.layout.snapshotSize / self.h
  		self.snapmag = math.min( f1, f2 )
		--self.restoreX, self.restoreY, self.restoreMag = nil, nil, nil
		-- restore window size but do not move it according to where the Quad was
		local nx,ny = self:WtoS( self.translateQuadX, self.translateQuadY )
		local x,y = self:WtoS(0,0)
		self:translate(x-nx,y-ny)
		self.translateQuadX, self.translateQuadY = 0,0
		return
		end 
  	local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
	local x1, y1 = math.floor((x1 - zx) * self.mag) , math.floor((y1 - zy) * self.mag)  -- convert to map coordinates
	local x2, y2 = math.floor((x2 - zx) * self.mag) , math.floor((y2 - zy) * self.mag)  -- convert to map coordinates
	if x1 > x2 then x1, x2 = x2, x1 end
	if y1 > y2 then y1, y2 = y2, y1 end
	local w, h = math.floor(x2 - x1), math.floor(y2 - y1)
	if x1 + w > self.w then w = self.w - x1 end
	if y1 + h > self.h then h = self.h - y1 end
	self.quad = love.graphics.newQuad(x1,y1,w,h,self.w,self.h)
	local px,py = self:WtoS(x1,y1)
	self.translateQuadX, self.translateQuadY = math.floor(x1), math.floor(y1) 
	io.write("creating quad x y w h (versus w h): " .. x1 .. " " .. y1 .. " " .. w .. " " .. h .. " " .. "(" .. self.w .. " " .. self.h .. ")\n")
	self.w, self.h = w, h
	local nx,ny = self:WtoS(0,0)
	self:translate(px-nx,py-ny)
  	local f1, f2 = self.layout.snapshotSize / self.w, self.layout.snapshotSize / self.h
  	self.snapmag = math.min( f1, f2 )
	--self.restoreX, self.restoreY, self.restoreMag = self.x, self.y, self.mag
	end

-- a Map move or zoom is a  bit more than a window move or zoom: 
-- We might send the same movement to the projector as well
function Map:move( x, y ) 
		self.x = x; self.y = y
		if atlas:isVisible(self) and not self.sticky then 
			tcpsend( projector, "CHXY " .. math.floor(self.x+self.translateQuadX) .. " " .. math.floor(self.y+self.translateQuadY) ) 
		end
	end

function Map:zoom( mag )
	if mag == 1 then
		-- +1, reduce size
		if self.mag < 1 then self.mag = self.mag + 0.1
		elseif self.mag >= 1 then self.mag = self.mag + 0.5 end
		if self.mag >= 20 then self.mag = 20 end
	elseif mag == -1 then
		-- -1, augment size
		if self.mag > 1 then self.mag = self.mag - 0.5 
		elseif self.mag <= 1 then self.mag = self.mag - 0.1 end
		if self.mag <= 0.1 then self.mag = 0.1 end
	end
	if atlas:isVisible(self) and not self.sticky then tcpsend( projector, "MAGN " .. 1/self.mag ) end	
	end

function Map:drop( o )
        local W,H=self.layout.W,self.layout.H
	local obj = o.object
	if obj.class == "pnjtable" or obj.class == "pnj" then -- receiving a PNJ either from PNJ list or from snapshot PNJ Class bar 
		if not self.basePawnSize then self.layout.notificationWindow:addMessage("No pawn size defined on this map. Please define it with Ctrl+mouse")
		else
		  local x, y = love.mouse.getPosition()
  		  local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
		  local px, py = (x - zx) * self.mag , (y - zy) * self.mag 

		  -- maybe we need to create the PNJ before
		  local id
		  if obj.class == "pnj" then
			id  = rpg.generateNewPNJ( obj.rpgClass.class )
		  else
			id = obj.id
		  end
		  if not id then return end
		  io.write("map drop 1: object is pnj of class '" .. obj.rpgClass.class .. "' with id " .. id .. "\n")

		  local p = self:createPawns(0,0,0,id)  -- we create it at 0,0, and translate it afterwards
		  if p then 
			p.x, p.y = px + self.translateQuadX ,py + self.translateQuadY 
		  	io.write("map drop 2: creating pawn " .. id .. "\n")
			end

		  -- send it to projector
		  if p and atlas:isVisible(self) then	
	  		local flag
	  		if p.PJ then flag = "1" else flag = "0" end
			local i = findPNJ( p.id )
	  		local f = p.snapshot.baseFilename -- FIXME: what about pawns loaded dynamically ?
	  		io.write("PAWN " .. p.id .. " " .. math.floor(p.x) .. " " .. math.floor(p.y) .. " " .. 
					--math.floor(p.sizex * PNJTable[i].sizefactor) .. " " .. flag .. " " .. f .. "\n")
					math.floor(p.sizex) .. " " .. flag .. " " .. f .. "\n")
	  		tcpsend( projector, "PAWN " .. p.id .. " " .. math.floor(p.x) .. " " .. math.floor(p.y) .. " " .. 
					--math.floor(p.sizex * PNJTable[i].sizefactor) .. " " .. flag .. " " .. f)
					math.floor(p.sizex) .. " " .. flag .. " " .. f)
			end
		end
	end 
	end

function Map:killAll() 
	PNJTable = {}
	if atlas:isVisible(self) then tcpsend( projector, "ERAS" ); end
  	end

function Map:wipe()
	if atlas:isVisible(self) then
	  for i=1,#PNJTable do
		if PNJTable[i].is_dead then tcpsend( projector, "ERAP " .. PNJTable[i].id ); end
	  end
	end
	rpg.removeDeadPNJ()
	end

function Map:fullsize()

	-- if values are stored for restoration, we restore
	if self.restoreX then
		self.x, self.y, self.mag = self.restoreX, self.restoreY, self.restoreMag
		self.restoreX, self.restoreY, self.restoreMag = nil,nil,nil,nil 
		self.fullSize = false
		if atlas:isVisible(self) and not self.sticky then 
			tcpsend( projector, "MAGN " .. 1/self.mag ) 
			tcpsend( projector, "CHXY " .. math.floor(self.x+self.translateQuadX) .. " " .. math.floor(self.y+self.translateQuadY) )
		end
		return
	end

	-- store values for restoration
	self.restoreX, self.restoreY, self.restoreMag = self.x, self.y, self.mag
	self.fullSize = true 
	self.x, self.y = self.w / 2, self.h / 2
	self.mag = 1.0

	if atlas:isVisible(self) and not self.sticky then 
		tcpsend( projector, "MAGN " .. 1/self.mag ) 
		tcpsend( projector, "CHXY " .. math.floor(self.x+self.translateQuadX) .. " " .. math.floor(self.y+self.translateQuadY) ) 
	end

	end

function Map:draw()

     local map = self
     currentWindowDraw = self

     if not self.im then self:lazyLoad() end

     self:drawBack()
 
     local W,H=self.layout.W,self.layout.H
     local SX,SY,MAG = map.x, map.y, map.mag
     local x,y = -( SX * 1/MAG - W / 2), -( SY * 1/MAG - H / 2)
  

     if map.mask then	
       --love.graphics.setColor(100,100,50,200)
       if layout:getFocus() == map then
		love.graphics.setColor(200,200,100)
       else
		love.graphics.setColor(150,150,150)
       end	
       love.graphics.stencil( myStencilFunction, "increment" )
       love.graphics.setStencilTest("equal", 1)
     else
       --love.graphics.setColor(255,255,255,240)
       love.graphics.setColor(255,255,255)
     end

     love.graphics.setScissor(x,y,self.w/MAG,self.h/MAG) 
     if map.quad then
       love.graphics.draw( map.im, map.quad, x, y, 0, 1/MAG, 1/MAG )
     else
       love.graphics.draw( map.im, x, y, 0, 1/MAG, 1/MAG )
     end

     if map.mask then
       love.graphics.setStencilTest("gequal", 2)
       love.graphics.setColor(255,255,255)
     if map.quad then
       love.graphics.draw( map.im, map.quad, x, y, 0, 1/MAG, 1/MAG )
     else
       love.graphics.draw( map.im, x, y, 0, 1/MAG, 1/MAG )
     end
       love.graphics.setStencilTest()
     end


     -- draw pawns, if any
     if map.pawns then
	     for i=1,#map.pawns do
       	     	     local index = findPNJ(map.pawns[i].id) 
		     -- we do some checks before displaying the pawn: it might happen that the character corresponding to the pawn 
		     -- is dead, or, worse, has been removed completely from the list
		     if index then 
		        local rw = map.pawns[i].snapshot.w * map.pawns[i].f / map.mag
		     	local dead = false
		     	dead = PNJTable[ index ].is_dead
		     	if map.pawns[i].snapshot.im then
  		       		local zx,zy = (map.pawns[i].x - map.translateQuadX) * 1/map.mag + x , (map.pawns[i].y - map.translateQuadY) * 1/map.mag + y
				-- color is different depending on PJ/PNJ, and if the character has played this round or not, or has the focus
		       		if PNJTable[index].done then love.graphics.setColor(unpack(theme.color.green))
				elseif PNJTable[index].PJ then love.graphics.setColor(50,50,250) else love.graphics.setColor(250,50,50) end
		       		love.graphics.rectangle( "fill", zx, zy, (map.pawns[i].sizex+6) / map.mag, (map.pawns[i].sizey+6) / map.mag)
		       		if dead then 
					love.graphics.setColor(50,50,50,200) -- dead are grey
				else
					love.graphics.setColor( unpack(map.pawns[i].color) )  
				end
		       		nzx = zx + map.pawns[i].offsetx / map.mag
		       		nzy = zy + map.pawns[i].offsety / map.mag
		       		love.graphics.draw( map.pawns[i].snapshot.im , nzx, nzy, 0, map.pawns[i].f / map.mag , map.pawns[i].f / map.mag )
				-- display hits number and ID
		       		love.graphics.setColor(0,0,0)  
				local f = map.basePawnSize / 5
				local g = rw / 5
				local s = f / 22 
		       		love.graphics.setColor(0,0,0) 
		       		love.graphics.rectangle( "fill", zx, zy, f / map.mag, 3 * f / map.mag)
		       		love.graphics.setColor(theme.color.green) 
		       		love.graphics.rectangle( "fill", zx, zy + f / map.mag, f / map.mag, f / map.mag)
        			love.graphics.setFont(theme.fontSearch)
		       		love.graphics.setColor(255,255,255) 
				love.graphics.print( PNJTable[index].hits , zx, zy , 0, s/map.mag, s/map.mag )
				love.graphics.print( PNJTable[index].id , zx, zy + 2 * f/map.mag , 0, s/map.mag, s/map.mag )
		       		love.graphics.setColor(0,0,0) 
				love.graphics.print( "D" .. PNJTable[index].armor , zx, zy + f/map.mag, 0, s/map.mag, s/map.mag )
				-- display actions if PJ
				if PNJTable[index].PJ then
		       		  if PNJTable[index].actions == PJMaxAction then love.graphics.setColor(theme.color.red) else love.graphics.setColor(theme.color.green) end
		       		  love.graphics.rectangle( "fill", zx + (g*4), zy , g , (PNJTable[index].actions+1) * g )
		       		  love.graphics.setColor(0,0,0) 
				  love.graphics.print( "A", zx + (g*4) , zy , 0, s/map.mag, s/map.mag )
				  for j=1,PNJTable[index].actions do
					love.graphics.print( j , zx + (g*4) , zy + j * g, 0, s/map.mag, s/map.mag )
				  end
				end 
				-- display icons if PJ
				if PNJTable[index].PJ and self.showIcons and map.pawns[i] == self.showIcons then
				  self.showIconsX, self.showIconsY = zx + g * 5 + 2 , zy
				  love.graphics.setColor(50,50,250)
				  love.graphics.rectangle( "fill", zx + g * 5 - 2 , zy - 4 , theme.iconSize  + 10 , theme.iconSize * 4 + 12 )
		       		  love.graphics.setColor(255,255,255) 
				  love.graphics.rectangle( "fill", zx + g * 5 + 2 , zy , theme.iconSize  + 2 , theme.iconSize * 4 + 6 )
				  love.graphics.draw( theme.iconSuccess , zx + g * 5 + 2 , zy )
				  love.graphics.draw( theme.iconPartialSalve , zx + g * 5 + 2 , zy + theme.iconSize  + 2 )
				  love.graphics.draw( theme.iconPartialTailler , zx + g * 5 + 2 , zy +  2 * theme.iconSize  + 4)
				  love.graphics.draw( theme.iconFail , zx + g * 5 + 2 , zy +  3 * theme.iconSize  + 6)
				end
	     	     	end
		     end
	     end
     end

     -- print visible 
     if atlas:isVisible( map ) then
	local char = "V" -- a priori
	if map.sticky then char = "S" end -- stands for S(ticky)
        love.graphics.setColor(200,0,0,180)
        love.graphics.setFont(theme.fontDice)
	local fx = math.max( x , 0 )
	local fy = math.max( y + (20/map.mag), 0 )
	love.graphics.print( char , fx , fy , 0, 2/map.mag, 2/map.mag) -- bigger letters
     end

     -- print search zone if scenario
     if self.kind == "scenario" then
      	love.graphics.setColor(0,0,0)
      	love.graphics.setFont(theme.fontSearch)
      	love.graphics.printf(text, 800, H - 60, 400)
      	-- print number of the search result is needed
      	if searchIterator then love.graphics.printf( "( " .. searchIndex .. " [" .. string.format("%.2f", searchPertinence) .. "] out of " .. 
						           searchSize .. " )", 800, H - 40, 400) end
    end

    love.graphics.setScissor() 

    -- print window button bar
    self:drawResize()
    self:drawBar()

    -- print popup if needed
    local p, popup
    if layout:getFocus() == self then
     love.graphics.setColor(255,255,255)
     local x,y = love.mouse.getPosition()
     p , _ , popup, _ = self:isInsidePawn(x,y)
     if p and popup then
	-- we are hovering the popup zone of a pawn 
	-- Show popup now if there is a popup associated with that Pawn
 	local i = findPNJ( p.id )
	if i and PNJTable[ i ].snapshotPopup then		
		-- compute x,y to show the popup window so it does not exceed the window limits
		if x + PNJTable[ i ].snapshotPopup.w > W then x = (W - PNJTable[ i ].snapshotPopup.w) end
		if y + PNJTable[ i ].snapshotPopup.h > H then y = (H - PNJTable[ i ].snapshotPopup.h) end
		love.graphics.draw( PNJTable[ i ].snapshotPopup.im , x, y )
	end
     end   

    if p and p == lastPawn then
      if love.timer.getTime( ) - lastPawnTimer > lastPawnTimerDelay then
      	lastPawnTimer = love.timer.getTime( )
	-- reorder pawns, selected pawn comes last
	local newP = {}
	for i=1,#self.pawns do
	  if lastPawn ~= self.pawns[i] then table.insert(newP,self.pawns[i]) end
	end
	table.insert(newP,lastPawn)
	self.pawns = newP
	self.showIcons = p 
	self.showIconsTimer = 0 
      end
    elseif not p then
    	lastPawn= nil 
    	lastPawnTimer = 0 
	if self.showIconsTimer == 0 then self.showIconsTimer = love.timer.getTime( ) end -- we are outside a pawn, start timer to make icons disappear
    else
    	lastPawn= p
    	lastPawnTimer = love.timer.getTime( )
	self.showIconsTimer = 0 
    end 

    end -- layout:getFocus

    if self.showIcons and self.showIconsTimer > 0 and love.timer.getTime( ) - self.showIconsTimer > 3 then
	self.showIcons = nil
	self.showIconsX, self.showIconsY = 0, 0
	self.showIconsTimer = 0 
    end

 
end

function Map:getFocus() 
	if self.kind == "scenario" then 
		textActiveCallback = function(t) text = text .. t end
        	textActiveBackspaceCallback = function ()
			if text == textBase then return end
         		-- get the byte offset to the last UTF-8 character in the string.
         		local byteoffset = utf8.offset(text, -1)
         		if byteoffset then text = string.sub(text, 1, byteoffset - 1) end
        		end
	end 
	end

function Map:looseFocus() 
	if self.kind == "scenario" then 
		textActiveCallback = nil
		textActiveBackspaceCallback = nil
	end 
	end

function Map:iterate()
	if self.kind ~= "scenario" then return end
	if searchIterator then self.x,self.y,searchPertinence,searchIndex,searchSize = searchIterator() end
	end

function Map:doSearch()
	  if self.kind ~= "scenario" then return end
          searchIterator = doSearch( string.gsub( text, textBase, "" , 1) )
          text = textBase
          if searchIterator then self.x,self.y,searchPertinence,searchIndex,searchSize = searchIterator() end
	end

function Map:update(dt)	

	-- move pawns progressively, if needed
	-- restore their color (white) which may have been modified if they are current target of an arrow
	if self.kind =="map" then
		for i=1,#self.pawns do
			local p = self.pawns[i]
			if p.timer then p.timer:update(dt) end
			if p.x == p.moveToX and p.y == p.moveToY then p.timer = nil end -- remove timer in the end
			p.color = theme.color.white
		end	
	end


	Window.update(self,dt)
	end

-- remove a pawn from the list (different from killing the pawn)
function Map:removePawn( id )
	for i=1,#self.pawns do if self.pawns[i].id == id then table.remove( self.pawns , i ) ; break end end
	end

--
-- Create characters from PNJTable as pawns on the 'map', with the 'requiredSize' (in pixels on the screen) 
-- and around the position 'sx','sy' (expressed in pixel position in the screen)
--
-- createPawns() only create characters that are not already created on this 'map'. 
-- When new characters are created on a map with existing pawns, 'requiredSize' is ignored, replaced by 
-- the current value for existing pawns on the map.
--
-- createPawns() will create all characters of the existing list. But if 'id' is provided, it will 
-- only create this character
--
-- return the pawns array if multiple pawns requested, or the unique pawn if 'id' provided
--

function Map:setPawnSize( requiredSize )
  	local border = 3 -- size of a colored border, in pixels, at scale 1 (3 pixels on all sides)
  	local requiredSize = math.floor((requiredSize) * self.mag) - border*2
  	self.basePawnSize = requiredSize
	end

function Map:createPawns( sx, sy, requiredSize , id ) 

  local map = self

  local uniquepawn = nil

  local border = 3 -- size of a colored border, in pixels, at scale 1 (3 pixels on all sides)

  -- set to scale 1
  -- get actual size, without borders.
  requiredSize = math.floor((requiredSize) * map.mag) - border*2

  -- use the required size unless the map has pawns already. In this case, reuse the same size
  local pawnSize = map.basePawnSize or requiredSize 
  if not map.basePawnSize then map.basePawnSize = pawnSize end

  local margin = math.floor(pawnSize / 10) -- small space between 2 pawns

  -- position of the upper-left corner of the map on screen
  local W,H=self.layout.W,self.layout.H
  local zx,zy = -( map.x * 1/map.mag - W / 2), -( map.y * 1/map.mag - H / 2)

  -- position of the mouse, relative to the map at scale 1 (and not to the screen)
  sx, sy = ( sx - zx ) * map.mag, ( sy - zy ) * map.mag 

  -- set position of 1st pawn to draw (relative to the map)
  local starta,startb = math.floor(sx - 2 * (pawnSize + border*2 + margin)) , math.floor(sy - 2 * (pawnSize + border*2 + margin)) 

  -- a,b could be outside the map, check for this...
  local aw, bh = (pawnSize + border*2 + margin) * 4, (pawnSize + border*2 + margin) * 4
  if starta < 0 then starta = 0 end
  if starta + aw > map.w then starta = map.w - aw end
  if startb < 0 then startb = 0 end
  if startb + bh > map.h then startb = map.h - bh end

  local a,b = starta, startb

  for i=1,#PNJTable do

	 local p
	 local needCreate = true

	 -- don't create pawns for characters already dead...
	 if PNJTable[i].is_dead then needCreate = false end

	 -- check if pawn with same ID exists or not on the map
	 for k=1,#map.pawns do if map.pawns[k].id == PNJTable[i].id then needCreate = false; break; end end

	 -- limit creation to only 1 character if ID is provided
	 if id and (PNJTable[i].id ~= id) then needCreate = false end

	 if needCreate then
	  local f
	  if PNJTable[i].snapshot then
	  	p = Pawn:new( PNJTable[i].id , PNJTable[i].snapshot, pawnSize * PNJTable[i].sizefactor , a , b ) 
	  else
		assert(defaultPawnSnapshot,"no default image available. You should refrain from using pawns on the map...")
	  	p = Pawn:new( PNJTable[i].id , defaultPawnSnapshot, pawnSize * PNJTable[i].sizefactor , a , b ) 
	  end
	  p.PJ = PNJTable[i].PJ
	  map.pawns[#map.pawns+1] = p
	  io.write("creating pawn " .. i .. " with id " .. p.id .. " and inserting in map at rank " .. #map.pawns .. "\n")
	  if id then uniquepawn = p end

	  -- send to projector...
	  if not id and atlas:isVisible(map) then
	  	local flag
	  	if p.PJ then flag = "1" else flag = "0" end
		-- send over the socket
		if p.snapshot.is_local then
			tcpsendBinary{ file=p.snapshot.file }
	  		tcpsend( projector, "PEOF " .. p.id .. " " .. a .. " " .. b .. " " .. math.floor(pawnSize * PNJTable[i].sizefactor) .. " " .. flag )
		elseif fullBinary then
			tcpsendBinary{ filename=p.snapshot.filename }
	  		tcpsend( projector, "PEOF " .. p.id .. " " .. a .. " " .. b .. " " .. math.floor(pawnSize * PNJTable[i].sizefactor) .. " " .. flag )
		else
	  		local f = p.snapshot.filename
	  		f = string.gsub(f,baseDirectory,"")
	  		io.write("PAWN " .. p.id .. " " .. a .. " " .. b .. " " .. math.floor(pawnSize * PNJTable[i].sizefactor) .. " " .. flag .. " " .. f .. "\n")
	  		tcpsend( projector, "PAWN " .. p.id .. " " .. a .. " " .. b .. " " .. math.floor(pawnSize * PNJTable[i].sizefactor) .. " " .. flag .. " " .. f)
		end
	  end
	  -- set position for next image: we display pawns on 4x4 line/column around the mouse position
	  if i % 4 == 0 then
			a = starta 
			b = b + pawnSize + border*2 + margin
	  	else
			a = a + pawnSize + border*2 + margin	
	  end
	  end

  end

  if id then return uniquepawn else return map.pawns end

  end

--
-- return true and an icon index (from 1 to ...) if hovering pawn icons zone
--
function Map:isInsideIcons(x,y)
  if not self.showIcons then return nil, nil end
  if x >= self.showIconsX and x <= self.showIconsX + theme.iconSize and y >= self.showIconsY and y <= self.showIconsY + 4 * theme.iconSize then
    local index = math.floor( (y - self.showIconsY ) / (theme.iconSize + 2))
    return self.showIcons, index
  end 
  return nil, nil
  end

-- return a pawn if position x,y on the screen (typically, the mouse), is
-- inside any pawn of the map. If several pawns at same location, return the
-- one with highest layer value
--
-- return pawn , hit , popup , action
-- where
--   pawn is the pawn below the coordinates x, y (or nil)
--   hit is true if the mouse is over the "hit" zone 
--   popup is true if the mouse is over the "popup" zone 
--   action is true if the mouse is over the "action" zone
-- 
function Map:isInsidePawn(x,y)
  if self:isInsideIcons(x,y) then return nil, false, false, false end -- icons take precedence...
  local W,H=self.layout.W,self.layout.H
  local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2) -- position of the map on the screen
  if self.pawns then
	local hitClicked = false -- a priori
	local popup = false -- a priori
	local action = false -- a priori
	local indexWithMaxLayer, maxlayer = 0, 0
	for i=1,#self.pawns do
		-- check that this pawn is still active/alive
		local index = findPNJ( self.pawns[i].id )
		if index then  
		  local lx,ly = self.pawns[i].x - self.translateQuadX, self.pawns[i].y - self.translateQuadY-- position x,y relative to the map, at scale 1
		  local tx,ty = zx + lx / self.mag, zy + ly / self.mag -- position tx,ty relative to the screen
		  local sizex = self.pawns[i].sizex / self.mag -- size relative to the screen
		  local sizey = self.pawns[i].sizey / self.mag -- size relative to the screen
		  if x >= tx and x <= tx + sizex and y >= ty and y <= ty + sizey and self.pawns[i].layer > maxlayer then
			maxlayer = self.pawns[i].layer
			indexWithMaxLayer = i
			if x <= tx + sizex / 5 and y <= ty + sizey / 5 then hitClicked = true else hitClicked = false end
			if x <= tx + sizex / 5 and y >= ty + sizey / 5 and y <= ty + 2 * sizey / 5 then popup = true else popup = false end
			if x >= tx + (sizex / 5) * 4 and y <= ty + sizey / 5 then action = true else action = false end
		  end
	  	end
  	end
	if indexWithMaxLayer == 0 then return nil, false, false, false else return self.pawns[ indexWithMaxLayer ], hitClicked, popup, action end
  end
end

-- set or unset sticky mode
function Map:setSticky()
		local map = self
		if not atlas:isVisible(map) then return end -- if map is not visible, do nothing
                if not map.sticky then
                        -- we enter sticky mode. Normally, the projector is fully aligned already, so
                        -- we just save the current status for future restoration
                        map.stickX, map.stickY, map.stickmag = map.x, map.y, map.mag
                        map.sticky = true
                        layout.notificationWindow:addMessage("Map " .. map.displayFilename .. " is now sticky")
                else
                        -- we were already sticky, with a different status probably. So we store this
                        -- new one, but we need to align the projector as well
                        map.stickX, map.stickY, map.stickmag = map.x, map.y, map.mag
                        tcpsend( projector, "CHXY " .. math.floor(map.x+map.translateQuadX) .. " " .. math.floor(map.y+map.translateQuadY) )
                        tcpsend( projector, "MAGN " .. 1/map.mag )
                end
end

function Map:setUnsticky()
		if not self.sticky then return end
                self:move( self.stickX , self.stickY )
                self.mag = self.stickmag
                self.sticky = false
                layout.notificationWindow:addMessage("Map " .. self.displayFilename .. " is no more sticky. Be careful with your movements")
end

function Map:clickPawnAction( p , index )
	if not p then return end
	local i = findPNJ(p.id)
	if not i then return end
	if index == 0 then
		-- just success...
		rpg.increaseAction(i)
	elseif index == 1 then
		layout.notificationWindow:addMessage( rpg.getPartialS() , 10 )
		rpg.increaseAction(i)
	elseif index == 2 then
		layout.notificationWindow:addMessage( rpg.getPartialT() , 10 )
		rpg.increaseAction(i)
	elseif index == 3 then
		layout.notificationWindow:addMessage( rpg.getFail() , 10 )
		rpg.increaseAction(i)
	end
end
 

return Map

