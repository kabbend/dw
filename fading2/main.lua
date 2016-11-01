
-- interface import
local utf8 	= require 'utf8'
local yui 	= require 'yui.yaoui' 	-- graphical library on top of Love2D
local socket 	= require 'socket'	-- general networking
local parser    = require 'parse'	-- parse command line arguments
local tween	= require 'tween'	-- tweening library (manage transition states)

require 'scenario'			-- read scenario file and perform text search
require 'rpg'				-- code related to the RPG itself

-- dice3d code
require	'fading2/dice/base'
require	'fading2/dice/loveplus'
require	'fading2/dice/vector'
require 'fading2/dice/render'
require 'fading2/dice/stars'
require 'fading2/dice/geometry'
require 'fading2/dice/diceview'
require 'fading2/dice/light'
require 'fading2/dice/default/config'

--
-- GLOBAL VARIABLES
--

debug = false

-- main layout
layout = nil
currentWindowDraw = nil

-- tcp information for network
address, serverport	= "*", "12345"		-- server information
server			= nil			-- server tcp object
ip,port 		= nil, nil		-- projector information
clients			= {}			-- list of clients. A client is a couple { tcp-object , id } where id is a PJ-id or "*proj"
projector		= nil			-- direct access to tcp object for projector
projectorId		= "*proj"		-- special ID to distinguish projector from other clients
chunksize 		= (8192 - 1)		-- size of the datagram when sending binary file
fullBinary		= false			-- if true, the server will systematically send binary files instead of local references

-- main screen size
W, H = 1420, 790 	-- main window size default values (may be changed dynamically on some systems)
viewh = H - 170 	-- view height
vieww = W - 300		-- view width
size = 19 		-- base font size
margin = 20		-- screen margin in map mode

-- messages zone
messages 		= {}
messagesH		= H - 22

-- snapshots
snapshots    = {}
snapshots[1] = { s = {}, index = 1, offset = 0 } 	-- small snapshots at the bottom, for general images
snapshots[2] = { s = {}, index = 1, offset = 0 }	-- small snapshots at the bottom, for scenario & maps
snapshots[3] = { s = {}, index = 1, offset = 0 }	-- small snapshots at the bottom, for pawns
snapText = { "IMAGES", "MAPS", "PAWNS" }
currentSnap		= 1				-- by default, we display images
snapshotSize 		= 70 				-- w and h of each snapshot
snapshotMargin 		= 7 				-- space between images and screen border
snapshotH 		= messagesH - snapshotSize - snapshotMargin

-- pawns and PJ snapshots
pawnMove 		= nil		-- pawn currently moved by mouse movement
defaultPawnSnapshot	= nil		-- default image to be used for pawns
pawnMaxLayer		= 1
pawnMovingTime		= 2		-- how many seconds to complete a movement on the map ?

-- snapshot size and image
H1, W1 = 140, 140
currentImage = nil

-- some GUI buttons whose color will need to be changed at runtime
attButton	= nil		-- button Roll Attack
armButton	= nil		-- button Roll Armor
nextButton	= nil		-- button Next Round
clnButton	= nil		-- button Cleanup
thereIsDead	= false		-- is there a dead character in the list ? (if so, cleanup button is clickable)

-- maps & scenario stuff
textBase		= "Search: "
text 			= textBase		-- text printed on the screen when typing search keywords
searchActive		= false
ignoreLastChar		= false
searchIterator		= nil			-- iterator on the results, when search is done
searchPertinence 	= 0			-- will be set by using the iterator, and used during draw
searchIndex		= 0			-- will be set by using the iterator, and used during draw
searchSize		= 0 			-- idem
keyZoomIn		= ':'			-- default on macbookpro keyboard. Changed at runtime for windows
keyZoomOut 		= '=' 			-- default on macbookpro keyboard. Changed at runtime for windows

-- dialog stuff
dialogBase		= "Message: "
dialog 			= dialogBase		-- text printed on the screen when typing dialog 
dialogActive		= false
dialogLog		= {}			-- store all dialogs for complete display
ack			= false			-- automatic acknowledge when message received ?

-- Help stuff
HelpLog = {
	{"",0,""},
	{"CTRL+H",170,"Help. Ouvre cette fenêtre"},
	{"CTRL+X",170,"Ferme la fenêtre courante"},
	{"CTRL+D",170,"Dialog. Ouvre la fenêtre de dialogue (communication avec les joueurs)"},
	{"CTRL+C",170,"Center. Recentre la fenêtre au milieu de l'écran"},
	{"CTRL+TAB",170,"Passe à la fenêtre suivante"},
	{"CTRL+V",170,"Visible. Rend la Map sélectionnée visible/invisible des joueurs, sur le projecteur"},
	{"CTRL+S",170,"Stick. Active le mode 'sticky' sur la Map sélectionnée, si elle est visible"},
	{"CTRL+U",170,"Unstick. Retire le mode 'sticky' de la Map sélectionnée"},
	{"CTRL+Z",170,"Zoom. Active la maximization/minimization de la Map sélectionnée"},
	{"CTRL+P",170,"Pions. Sur une Map avec des pions, retire tous les pions"},
	{"SHIFT+Mouse",170,"Sur une Map, créé une forme géométrique qui réduit le brouillard de guerre"},
	{"CTRL+Mouse",170,"Sur une Map, créé et positionne des pions"},
	{"TAB",170,"Pour les Maps, passe du mode Rectangle au mode Cercle pour tracer les brouillards de guerre"},
	{"ESPACE",170,"Change la catégorie de la barre de snapshots, entre images, maps et pions"},
	{"ESC",170,"Cache toutes les fenêtres (ou les restaure)"},
	{"",0,""},
	{": ou = (macbook pro)",300,"Sur une Map, Zoom - ou +"},
	{": ou ! (windows)",300,"Sur une Map, Zoom - ou +"},
	{"",0,""},
	{"Double-click (snapshot image)",300,"L'envoie au projecteur"},
	{"Double-click (snapshot Map)",300, "Ouvre la map"},
	{"Double-click (Snapshot pion)",300,"Associe le pion au personnage sélectionné dans la liste"},
	}

-- some basic colors
color = {
  masked = {210,210,210}, black = {0,0,0}, red = {250,80,80}, darkblue = {66,66,238}, purple = {127,0,255}, 
  orange = {204,102,0},   darkgreen = {0,102,0},   white = {255,255,255} } 

-- array of actual PNJs, from index 1 to index (PNJnum - 1)
-- None at startup (they are created upon user request)
-- Maximum number is PNJmax
-- At a given time, number of PNJs is (PNJnum - 1)
-- A Dead PNJ counts as 1, except if explicitely removed from the list
PNJTable 	= {}		
PNJnum 		= 1		-- next index to use in PNJTable 
PNJmax   	= 13		-- Limit in the number of PNJs (and the GUI frame size as well)

-- Direct access (without traversal) to GUI structure:
-- PNJtext[i] gives a direct access to the i-th GUI line in the GUI PNJ frame
-- this corresponds to the i-th PNJ as stored in PNJTable[i]
PNJtext 	= {}		

-- Round information
roundTimer	= 0
roundNumber 	= 1			
newRound	= true

-- flash flag and timer when 'next round' is available
flashTimer	= 0
nextFlash	= false
flashSequence	= false

-- in combat mode, a given PNJ line may have the focus
focus	        = nil   -- Index (in PNJTable) of the current PNJ with focus (or nil if no one)
focusTarget     = nil   -- unique ID (and not index) of the corresponding target
focusAttackers  = {}    -- List of unique IDs of the corresponding attackers
lastFocus	= nil	-- store last focus value

-- flag and timer to draw d6 dices in combat mode
dice 		    = {}	-- list of d6 dices
drawDicesTimer      = 0
drawDices           = false	-- flag to draw dices
drawDicesResult     = false	-- flag to draw dices result (in a 2nd step)	
diceKind 	    = ""	-- kind of dice (black for 'attack', white for 'armor') -- unused
diceSum		    = 0		-- result to be displayed on screen
lastDiceSum	    = 0		-- store previous result
diceStableTimer	    = 0

-- information to draw the arrow in combat mode
arrowMode 		 = false	-- draw an arrow with mouse, yes or no
arrowStartX, arrowStartY = 0,0		-- starting point of the arrow	
arrowX, arrowY 		 = 0,0		-- current end point of the arrow
arrowStartIndex 	 = nil		-- index of the PNJ at the starting point
arrowStopIndex 		 = nil		-- index of the PNJ at the ending point
arrowModeMap		 = nil		-- either nil (not in map mode), "RECT" or "CIRC" shape used to draw map maskt
maskType		 = "RECT"	-- shape to use, rectangle by default

-- we write only in debug mode
local oldiowrite = io.write
function io.write( data ) if debug then oldiowrite( data ) end end

--
-- Multiple inheritance mechanism
-- call CreateClass with any number of existing classes 
-- to create the new inherited class
--

-- look up for `k' in list of tables `plist'
function Csearch (k, plist)
	for i=1, table.getn(plist) do
	local v = plist[i][k] -- try `i'-th superclass
	if v then return v end
	end
	end

function createClass (a,b)
	local c = {} -- new class
	setmetatable(c, {__index = function (t, k) return Csearch(k, {a,b}) end})
	c.__index = c
	function c:new (o) o = o or {}; setmetatable(o, c); return o end
	return c
	end

-- some convenient file loading functions (based on filename or file descriptor)
function loadDistantImage( filename )
  local file = assert( io.open( filename, 'rb' ) )
  local image = file:read('*a')
  file:close()
  return image  
end

function loadLocalImage( file )
  file:open('r')
  local image = file:read()
  file:close()
  return image
end

-- Snapshot class
-- a snapshot holds an image, displayed in the bottom part of the screen.
-- Snapshots are used for general images, and for pawns. For maps, use the
-- specific class Map instead, which is derived from Snapshot.
-- The image itself is stored in memory in its binary form, but for purpose of
-- sending it to the projector, it is also either stored as a path on the shared 
-- filesystem, or a file object on the local filesystem
Snapshot = { class = "snapshot" , filename = nil, file = nil }
function Snapshot:new( t ) -- create from filename or file object (one mandatory)
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  assert( new.filename or new.file )
  local image
  if new.filename then 
	image = loadDistantImage( new.filename )
	new.is_local = false
	new.baseFilename = string.gsub(new.filename,baseDirectory,"")
  else 
	image = loadLocalImage( new.file )
	new.is_local = true
	new.baseFilename = nil
  end
  local lfn = love.filesystem.newFileData
  local lin = love.image.newImageData
  local lgn = love.graphics.newImage
  local img = lgn(lin(lfn(image, 'img', 'file')), { mipmaps=true } ) 
  pcall( function() img:setMipmapFilter( "nearest" ) end )
  local mode, sharpness = img:getMipmapFilter( )
  io.write("snapshot load: mode, sharpness = " .. tostring(mode) .. " " .. tostring(sharpness) .. "\n")
  new.im = img
  new.w, new.h = new.im:getDimensions()
  local f1, f2 = snapshotSize / new.w, snapshotSize / new.h
  new.snapmag = math.min( f1, f2 )
  new.selected = false
  return new
end


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
-- Notes:
-- Each object derived from Window class should redefine its own draw(), getFocus()
-- and looseFocus() methods.
-- Windows are gathered and manipulated thru the mainLayout object.
-- The main screen of the application (with yui view, etc.) is not considered as
--   a window object. For the moment, only scenario, maps and logs are windows,
--   and are displayed "on top" of this main screen.
--
Window = { class = "window", w = 0, h = 0, mag = 1.0, x = 0, y = 0 , zoomable = false ,
	   sticky = false, stickX = 0, stickY = 0, stickmag = 0 , markForClosure = false,
	   title = "" }
function Window:new( t ) 
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  return new
end

-- return true if the point (x,y) (expressed in layout coordinates system,
-- typically the mouse), is inside the window frame (whatever the display or
-- layer value, managed at higher-level)
function Window:isInside(x,y)
  local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
  return x >= zx and x <= zx + self.w / self.mag and 
  	 y >= zy - 20 and y <= zy + self.h / self.mag -- 20 needed to take window bar into account
end

function Window:zoom( mag ) if self.zoomable then self.mag = mag end end
function Window:move( x, y ) self.x = x; self.y = y end
function Window:setTitle( title ) self.title = title end

-- drawn upper button bar
function Window:drawBar()
 local reservedForButtons = 20*4
 local availableForTitle = self.w / self.mag - reservedForButtons - 20
 local numChar = math.floor(availableForTitle / 7)
 local title = string.sub( self.title , 1, numChar ) 
 love.graphics.setColor(224,224,224)
 local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
 love.graphics.rectangle( "fill", zx , zy - 20 , self.w / self.mag , 20 )
 love.graphics.setColor(255,0,0)
 love.graphics.setFont(fontRound)
 love.graphics.print( "X" , zx + self.w / self.mag - 12 , zy - 18 )
 love.graphics.setColor(0,0,0)
 love.graphics.print( title , zx + 20 , zy - 18 )
  -- draw small circle or rectangle in upper corner, to show which mode we are in
 love.graphics.setColor(255,0,0)
 if self.class == "map" and self.kind == "map" then
    if maskType == "RECT" then love.graphics.rectangle("line",zx + 5, zy - 16 ,12, 12) end
       if maskType == "CIRC" then love.graphics.circle("line",zx + 10, zy - 10, 5) end
     end
end

-- click in the window. Check some rudimentary behaviour (quit...)
function Window:click(x,y)
 	local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
	-- click on X symbol
	if x >= zx + self.w / self.mag - 12 and x <= zx + self.w / self.mag and
		y >= zy - 20 and y <= zy then
		self.markForClosure = true
		-- mark the window for a future closure. We don't close it right now, because
		-- there might be another object clickable just below that would be wrongly
		-- activated ( a yui button ). So we wait for the mouse release to perform
		-- the actual closure
	end
	return self
	end

-- to be redefined in inherited classes
function Window:draw() end 
function Window:getFocus() end
function Window:looseFocus() end
function Window:update(dt) end

--
--  Pawn object 
--  A pawn holds the image, with proper scale defined at pawn creation on the map,
--  along with the ID of the corresponding PJ/PNJ.
--  Both sizes of the pawn image (sizex and sizey) are computed to follow the image
--  original height/width ratio. Sizex is directly defined by the MJ at pawn creation,
--  using the arrow on the map, sizey is then derived from it
-- 
Pawn = {}
function Pawn:new( id, snapshot, width , x, y ) 
  local new = {}
  setmetatable(new,self)
  self.__index = self 
  new.id = id
  new.layer = pawnMaxLayer 
  new.x, new.y = x or 0, y or 0 		-- current pawn position, relative to the map
  new.moveToX, new.moveToY = new.x, new.y 	-- destination of a move 
  new.snapshot = snapshot
  new.sizex = width 				-- width size of the image in pixels, for map at scale 1
  local w,h = new.snapshot.w, new.snapshot.h
  new.sizey = new.sizex * (h/w) 
  local f1,f2 = new.sizex/w, new.sizey/h
  new.f = math.min(f1,f2)
  new.offsetx = (new.sizex + 3*2 - w * new.f ) / 2
  new.offsety = (new.sizey + 3*2 - h * new.f ) / 2
  new.PJ = false
  new.color = color.white
  return new
  end

-- Map class
-- a Map inherits from Window and from Snapshot, and is referenced both 
-- in the Atlas and in the snapshots list
-- It has the following additional properties
-- * it displays a jpeg image, a map, on which we can put and move pawns
-- * it can be of kind "map" (the default) or kind "scenario"
-- * it can be visible, meaning it is displayed to the players on
--   the projector, in realtime. There is maximum one visible map at a time
--   (but there may be several maps displayed on the server, to the MJ)

Map = createClass( Window , Snapshot )

function Map:load( t ) -- create from filename or file object (one mandatory). kind is optional
  local t = t or {}
  if not t.kind then self.kind = "map" else self.kind = t.kind end 
     -- a map by default. A scenario should be declared by the caller
  --setmetatable( new , self )
  --self.__index = self
  self.class = "map"
  
  -- snapshot part of the object
  assert( t.filename or t.file )
  local image
  if t.filename then
	self.filename = t.filename 
	image = loadDistantImage( self.filename )
	self.is_local = false
	self.baseFilename = string.gsub(self.filename,baseDirectory,"")
  else 
	self.file = t.file
	image = loadLocalImage( self.file )
	self.is_local = true
	self.baseFilename = nil
  end
  self.title = self.baseFilename or ""
  local lfn = love.filesystem.newFileData
  local lin = love.image.newImageData
  local lgn = love.graphics.newImage
  local success, img 
  if self.kind == "map" then
  	success, img = pcall(function() return lgn(lin(lfn(image, 'img', 'file')), { mipmaps=true } ) end)
  	pcall(function() img:setMipmapFilter( "nearest" ) end)
  	local mode, sharpness = img:getMipmapFilter( )
  	io.write("map load: mode, sharpness = " .. tostring(mode) .. " " .. tostring(sharpness) .. "\n")
  else
	success, img = pcall(function() return lgn(lin(lfn(image, 'img', 'file')) ) end)
  end
  self.im = img
  self.w, self.h = self.im:getDimensions()
  local f1, f2 = snapshotSize / self.w, snapshotSize / self.h
  self.snapmag = math.min( f1, f2 )
  self.selected = false
  
  -- window part of the object
  self.zoomable = true
  self.x = self.w / 2
  self.y = self.h / 2
  self.mag = 1.0
  
  -- specific to the map itself
  if self.kind == "map" then self.mask = {} else self.mask = nil end
  self.step = 50
  self.pawns = {}
  self.basePawnSize = nil -- base size for pawns on this map (in pixels, for map at scale 1)
  self.zoomtable = { 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 2, 3, 4, 5, 6, 7, 8 , 9, 10}
  self.magindex = 10 -- correspond to mag = 1.0
  self.maskMinX, self.maskMaxX, self.maskMinY, self.maskMaxY = 100 * self.w , -100 * self.w, 100 * self.h, - 100 * self.h 
end

-- a Map move or zoom is a  bit more than a window move or zoom: 
-- We might send the same movement to the projector as well
function Map:move( x, y ) 
		self.x = x; self.y = y
		if atlas:isVisible(self) and not self.sticky then 
			tcpsend( projector, "CHXY " .. math.floor(self.x) .. " " .. math.floor(self.y) ) 
		end
	end

function Map:zoom( mag )
		self.magindex = self.magindex + mag
		if self.magindex < 1 then self.magindex = 1 end
		if self.magindex > #self.zoomtable then self.magindex = #self.zoomtable end
		self.mag = self.zoomtable[self.magindex]
		if atlas:isVisible(self) and not self.sticky then tcpsend( projector, "MAGN " .. 1/self.mag ) end	
	end

function Map:maximize()

	-- if values are stored for restoration, we restore
	if self.restoreX then
		self.x, self.y, self.magindex, self.mag = self.restoreX, self.restoreY, self.restoreMagindex, self.restoreMag
		self.restoreX, self.restoreY, self.restoreMagindex, self.restoreMag = nil,nil,nil,nil 
		return
	end

	-- store values for restoration
	self.restoreX, self.restoreY, self.restoreMagindex, self.restoreMag = self.x, self.y, self.magindex, self.mag

	if not self.mask or (self.mask and #self.mask == 0) then
		-- no mask, just center the window with scale 1:0
		self.x, self.y = self.w / 2, self.h / 2
		self.magindex = 10 -- scale 1
		self.mag = 1.0
	else
		-- there are masks. We take the center of the combined masks
		self.x, self.y = (self.maskMinX + self.maskMaxX) / 2, (self.maskMinY + self.maskMaxY) / 2 
		self.magindex = 10 -- scale 1
		self.mag = 1.0
	end
	end

function Map:draw()

     local map = self
     currentWindowDraw = self

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

     love.graphics.draw( map.im, x, y, 0, 1/MAG, 1/MAG )

     if map.mask then
       love.graphics.setStencilTest("gequal", 2)
       love.graphics.setColor(255,255,255)
       love.graphics.draw( map.im, x, y, 0, 1/MAG, 1/MAG )
       love.graphics.setStencilTest()
     end


     -- draw pawns, if any
     if map.pawns then
	     for i=1,#map.pawns do
       	     	     local index = findPNJ(map.pawns[i].id) 
		     -- we do some checks before displaying the pawn: it might happen that the character corresponding to the pawn 
		     -- is dead, or, worse, has been removed completely from the list
		     if index then 
		     	local dead = false
		     	dead = PNJTable[ index ].is_dead
		     	if map.pawns[i].snapshot.im then
  		       		local zx,zy = (map.pawns[i].x) * 1/map.mag + x , (map.pawns[i].y) * 1/map.mag + y
		       		if PNJTable[index].PJ then love.graphics.setColor(50,50,250) else love.graphics.setColor(250,50,50) end
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
				local s = f / 22 
		       		love.graphics.rectangle( "fill", zx, zy, f / map.mag, 2 * f / map.mag)
		       		love.graphics.setColor(255,255,255) 
        			love.graphics.setFont(fontSearch)
				love.graphics.print( PNJTable[index].hits , zx, zy , 0, s/map.mag, s/map.mag )
				love.graphics.print( PNJTable[index].id , zx, zy + f/map.mag , 0, s/map.mag, s/map.mag )
	     	     	end
		     end
	     end
     end

     -- print visible 
     if atlas:isVisible( map ) then
	local char = "V" -- a priori
	if map.sticky then char = "S" end -- stands for S(tuck)
        love.graphics.setColor(200,0,0,180)
        love.graphics.setFont(fontDice)
	love.graphics.print( char , x + 5 , y + (40 / map.mag) , 0, 2/map.mag, 2/map.mag) -- bigger letters
     end

     -- print search zone if scenario
     if self.kind == "scenario" then
      	love.graphics.setColor(0,0,0)
      	love.graphics.setFont(fontSearch)
      	love.graphics.printf(text, 800, H - 60, 400)
      	-- print number of the search result is needed
      	if searchIterator then love.graphics.printf( "( " .. searchIndex .. " [" .. string.format("%.2f", searchPertinence) .. "] out of " .. 
						           searchSize .. " )", 800, H - 40, 400) end
    end

    -- print window button bar
    self:drawBar()

end

function Map:getFocus() if self.kind == "scenario" then searchActive = true end end
function Map:looseFocus() if self.kind == "scenario" then searchActive = false end end

function Map:update(dt)	
	-- move pawns progressively, if needed
	-- restore their color (white) which may have been modified if they are current target of an arrow
	if self.kind =="map" then
		for i=1,#self.pawns do
			local p = self.pawns[i]
			if p.timer then p.timer:update(dt) end
			if p.x == p.moveToX and p.y == p.moveToY then p.timer = nil end -- remove timer in the end
			p.color = color.white
		end	
	end
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

  for i=1,PNJnum-1 do

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
	  io.write("creating pawn " .. i .. " with id " .. p.id .. "\n")
	  p.PJ = PNJTable[i].PJ
	  map.pawns[#map.pawns+1] = p
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

-- return a pawn if position x,y on the screen (typically, the mouse), is
-- inside any pawn of the map. If several pawns at same location, return the
-- one with highest layer value
function Map:isInsidePawn(x,y)
  local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2) -- position of the map on the screen
  if self.pawns then
	local indexWithMaxLayer, maxlayer = 0, 0
	for i=1,#self.pawns do
		-- check that this pawn is still active/alive
		local index = findPNJ( self.pawns[i].id )
		if index then  
		  local lx,ly = self.pawns[i].x, self.pawns[i].y -- position x,y relative to the map, at scale 1
		  local tx,ty = zx + lx / self.mag, zy + ly / self.mag -- position tx,ty relative to the screen
		  local sizex = self.pawns[i].sizex / self.mag -- size relative to the screen
		  local sizey = self.pawns[i].sizey / self.mag -- size relative to the screen
		  if x >= tx and x <= tx + sizex and y >= ty and y <= ty + sizey and self.pawns[i].layer > maxlayer then
			maxlayer = self.pawns[i].layer
			indexWithMaxLayer = i
		  end
	  	end
  	end
	if indexWithMaxLayer == 0 then return nil else return self.pawns[ indexWithMaxLayer ] end
  end
end

-- Help class
-- a Help is a window which displays some fixed text . it is not zoomable
Help = Window:new{ class = "help" , title = "Help" }

function Help:new( t ) -- create from w, h, x, y
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  return new
end

function Help:draw()
   -- draw window frame
   love.graphics.setFont(fontSearch)
   love.graphics.setColor(10,10,10,150)
   local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
   love.graphics.rectangle( "fill", zx , zy , self.w , self.h )  
   -- print current help text
   love.graphics.setColor(255,255,255)
   for i=1,#HelpLog do 
	love.graphics.printf( HelpLog[i][1] , zx + 5, zy + (i-1)*18 , self.w )	
	love.graphics.printf( HelpLog[i][3] , zx + HelpLog[i][2], zy + (i-1)*18 , self.w )	
   end
   -- print bar
   self:drawBar()
end

-- Dialog class
-- a Dialog is a window which displays some text and let some input. it is not zoomable
Dialog = Window:new{ class = "dialog" , title = "Dialog" }

function Dialog:new( t ) -- create from w, h, x, y
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  return new
end

function Dialog:draw()
   -- draw window frame
   love.graphics.setFont(fontSearch)
   love.graphics.setColor(10,10,10,150)
   local zx,zy = -( self.x * 1/self.mag - W / 2), -( self.y * 1/self.mag - H / 2)
   love.graphics.rectangle( "fill", zx , zy , self.w , self.h )  
   -- print current log text
   local start
   if #dialogLog > 10 then start = #dialogLog - 10 else start = 1 end
   love.graphics.setColor(255,255,255)
   for i=start,#dialogLog do 
	love.graphics.printf( dialogLog[i] , zx , zy + (i-start)*18 , self.w )	
   end
   -- print MJ input eventually
   love.graphics.setColor(200,200,255)
   love.graphics.printf(dialog, zx , zy + self.h - 22 , self.w )

   -- print bar
   self:drawBar()
end

function Dialog:getFocus() dialogActive = true end
function Dialog:looseFocus() dialogActive = false end

--
-- mainLayout class
-- store all windows, with their display status (displayed or not) and layer value
--
mainLayout = {}
function mainLayout:new()
  local new = { windows= {}, maxWindowLayer = 1 , focus = nil, sorted = {} }
  setmetatable( new , self )
  self.__index = self
  self.globalDisplay = true
  return new
end

function mainLayout:addWindow( window, display ) 
	self.maxWindowLayer = self.maxWindowLayer + 1
	self.windows[window] = { w=window , l=self.maxWindowLayer , d=display }
	-- sort windows by layer (ascending) value
	table.insert( self.sorted , self.windows[window] )
	table.sort( self.sorted , function(a,b) return a.l < b.l end )
	end

function mainLayout:removeWindow( window ) 
	if self.focus == window then self:setFocus( nil ) end
	for i=1,#self.sorted do if self.sorted[i].w == window then table.remove( self.sorted , i ); break; end end
	self.windows[window] = nil
	end

-- manage display status of a window
function mainLayout:setDisplay( window, display ) 
	if self.windows[window] then 
		self.windows[window].d = display
		if not display and self.focus == window then self:setFocus(nil) end -- looses the focus as well
	end
	end 
	
function mainLayout:getDisplay( window ) if self.windows[window] then return self.windows[window].d else return false end end

-- we can set a global value to display, or hide, all windows in one shot
function mainLayout:toggleDisplay() 
	self.globalDisplay = not self.globalDisplay 
 	if not self.globalDisplay then self:setFocus(nil) end -- no more window focus	
	end

-- return (if there is one) or set the window with focus 
-- if we set focus, the window automatically gets in front layer
function mainLayout:getFocus() return self.focus end

-- set the focus on the given window. if window is nil, remove existing focus if any
function mainLayout:setFocus( window ) 
	if window then
		if window == self.focus then return end -- this window was already in focus. nothing happens
		self.maxWindowLayer = self.maxWindowLayer + 1
		self.windows[window].l = self.maxWindowLayer
		table.sort( self.sorted , function(a,b) return a.l < b.l end )
		window:getFocus()
		if self.focus then self.focus:looseFocus() end
	end
	if not window and self.focus then self.focus:looseFocus() end
	self.focus = window
	end 

-- when ctrl+tab is pressed, select the next window to put focus on
function mainLayout:nextWindow()
 	local t = {}
	local index = nil
	if not self.globalDisplay then return end
	for i=1,#self.sorted do if self.sorted[i].d then 
		table.insert( t , self.sorted[i].w ) 
		if self.sorted[i].w == self:getFocus() then index = i end
		end end
	if not index then
		if #t >= 1 then index = 1
		else return end
	end
 	index = index + 1
	if index > #t then index = 1 end	
	self:setFocus( t[index] )	
	end

-- check if there is (and return) a window present at the given position in the screen
-- this takes into account the fact that a window is displayed or not (of course) but
-- also the layer value (the window with highest layer is selected).
-- If a window is actually clicked, it automatically gets focus and will get in front.
-- If no window is clicked, they all loose the focus
function mainLayout:click( x , y )
	local layer = 0
	local result = nil
	if not self.globalDisplay then return nil end -- in ESC mode, no window at all
	for k,l in pairs( self.windows ) do
		if l.d and l.w:isInside(x,y) and l.l > layer then result = l.w ; layer = l.l end  
	end
	if result then
		-- a window was actually clicked. Call corresponding click() function 
		-- this gives opportunity to the window to react, and potentially to close itself
		-- if the close button is pressed. 
		result:click(x,y)
	end
	self:setFocus( result ) -- this gives or removes focus
	return result
	end

-- same as click function, except that no click is actually performed, so focus does not change
function mainLayout:getWindow( x , y )
	local layer = 0
	local result = nil
	if not self.globalDisplay then return nil end -- in ESC mode, no window at all
	for k,l in pairs( self.windows ) do
		if l.d and l.w:isInside(x,y) and l.l > layer then result = l.w ; layer = l.l end  
	end
	return result
	end

function mainLayout:draw() 
	if not self.globalDisplay then return end -- do nothing if globalDisplay is not set !
	for k,v in ipairs( self.sorted ) do if self.sorted[k].d then self.sorted[k].w:draw() end end
	end 

function mainLayout:update(dt)
	for k,v in pairs(self.windows) do v.w:update(dt) end
	end

-- insert a new message to display
function addMessage( text, time , important )
  if not time then time = 5 end
  table.insert( messages, { text=text , time=time, offset=0, important=important } )
end
 
-- send a command or data to the projector over the network
function tcpsend( tcp, data , verbose )
  if not tcp then return end -- no client connected yet !
  if verbose == nil or verbose == true then  
	local i,p=tcp:getpeername()
	io.write("send to " .. tostring(i) .. "," .. tostring(p) .. ":" .. data .. "\n") 
  end
  tcp:send(data .. "\n")
  end

-- send a whole binary file over the network
-- t is table with one (and only one) of file or filename
function tcpsendBinary( t )

 if not projector then return end 	-- no projector connected yet !
 local file = t.file
 local filename = t.filename
 assert( file or filename )

 tcpsend( projector, "BNRY") 		-- alert the projector that we are about to send a binary file
 local c = tcpbin:accept() 		-- wait for the projector to open a dedicated channel
 -- we send a given number of chunks in a row.
 -- At the end of file, we might send a smaller one, then nothing...
 if file then
 	file:open('r')
 	local data, size = file:read( chunksize )
 	while size ~= 0 do
       		c:send(data) -- send chunk
		io.write("sending " .. size .. " bytes. \n")
        	data, size = file:read( chunksize )
 	end
 else
  	file = assert( io.open( filename, 'rb' ) )
  	local data = file:read(chunksize)
 	while data do
       		c:send(data) -- send chunk
		io.write("sending " .. string.len(size) .. " bytes. \n")
        	data = file:read( chunksize )
 	end
 end
 file:close()
 c:close()
 end

-- send dialog message to player
function doDialog( text )
  local _,_,playername,rest = string.find(text,"(%a+)%A?(.*)")
  io.write("send message '" .. text .. "': player=" .. tostring(playername) .. ", text=" .. tostring(rest) .. "\n")
  local tcp = findClientByName( playername )
  if not tcp then io.write("player not found or not connected\n") return end
  tcpsend( tcp, rest ) 
  table.insert( dialogLog , "MJ: " .. string.upper(text) .. "(" .. os.date("%X") .. ")" )
  end

-- capture text input (for text search)
function love.textinput(t)
	if (not searchActive) and (not dialogActive) then return end
	if ignoreLastChar then ignoreLastChar = false; return end
	if searchActive then
		text = text .. t
	else
		dialog = dialog .. t
	end
	end

--
-- dropping a file over the main window will: 
--
-- if it's not a map:
--  * create a snapshot at bottom right of the screen,
--  * send this same image over the socket to the projector client
--  * if a map was visible, it is now hidden
--
-- if it's a map ("map*.jpg or map*.png"):
--  * load it as a new map
--
function love.filedropped(file)

	  local filename = file:getFilename()
	  local is_a_map = false
	  local is_a_pawn = false
	  local is_local = false

	  -- if filename does not contain the base directory, it is local
	  local i = string.find( filename, baseDirectory )
	  is_local = (i == nil) 
	  io.write("is local : " .. tostring(is_local) .. "\n")

	  local _,_,basefile = string.find( filename, ".*" .. sep .. "(.*)")
	  io.write("basefile: " .. tostring(basefile) .. "\n")

	  -- check if is a map or not 
	  if string.sub(basefile,1,3) == "map" and 
	    (string.sub(basefile,-4) == ".jpg" or string.sub(basefile,-4) == ".png") then
	 	is_a_map = true
	  end

	  -- check if is a pawn or not 
	  if string.sub(basefile,1,4) == "pawn" and 
	    (string.sub(basefile,-4) == ".jpg" or string.sub(basefile,-4) == ".png") then
	 	is_a_pawn = true
	  end

	  io.write("is map?: " .. tostring(is_a_map) .. "\n")
	  io.write("is pawn?: " .. tostring(is_a_pawn) .. "\n")

	  if not is_a_map then -- load image 

		local snap = Snapshot:new{ file = file }
		if is_a_pawn then 
			table.insert( snapshots[3].s , snap )
		else
			table.insert( snapshots[1].s , snap )
	  		-- set the local image
	  		currentImage = snap.im 
			-- remove the 'visible' flag from maps (eventually)
			atlas:removeVisible()
		  	tcpsend(projector,"ERAS") 	-- remove all pawns (if any) 
			if not is_local and not fullBinary then
    	  	  		-- send the filename (without path) over the socket
		  		filename = string.gsub(filename,baseDirectory,"")
		  		tcpsend(projector,"OPEN " .. filename)
		  		tcpsend(projector,"DISP") 	-- display immediately
			elseif fullBinary then
		  		-- send the file itself...
		  		tcpsendBinary{ filename=filename } 
 				tcpsend(projector,"BEOF")
		  		tcpsend(projector,"DISP")
			else
		  		-- send the file itself...
		  		tcpsendBinary{ file=file } 
 				tcpsend(projector,"BEOF")
		  		tcpsend(projector,"DISP")
			end
		end

	  elseif is_a_map then  -- add map to the atlas
	    local m = Map:new()
	    m:load{ file=file } -- no filename, and file object means local 
	    --atlas:addMap( m )  
	    layout:addWindow( m , false )
	    table.insert( snapshots[2].s , m )

	  end

	end

-- GUI basic functions
function love.update(dt)

	-- decrease timelength of 1st message if any
	if messages[1] then 
	  if messages[1].time < 0 then
		messages[1].offset = messages[1].offset + 1
		if messages[1].offset > 21 then table.remove( messages, 1 ) end
	  else	  
		messages[1].time = messages[1].time - dt 
	end	
	end

	-- listening to anyone calling on our port 
	local tcp = server:accept()
	if tcp then
		-- add it to the client list, we don't know who is it for the moment
		table.insert( clients , { tcp = tcp, id = nil } )
		local ad,ip = tcp:getpeername()
		addMessage("receiving connection from " .. tostring(ad) .. " " .. tostring(ip))
		io.write("receiving connection from " .. tostring(ad) .. " " .. tostring(ip) .. "\n")
		tcp:settimeout(0)
	end

	-- listen to connected clients 
	for i=1,#clients do

 	 local data, msg = clients[i].tcp:receive()

 	 if data then

	    io.write("receiving command: " .. data .. "\n")

	    local command = string.sub( data , 1, 4 )

	    -- this client is unidentified. This should be a connection request
	    if not clients[i].id then

	      if data == "CONNECT" then 
		io.write("receiving projector call\n")
		addMessage("receiving projector call")
		clients[i].id = projectorId
		projector = clients[i].tcp
	    	tcpsend(projector,"CONN")
	
	      elseif 
		-- scan for the command itself to find the player's name
	       string.lower(command) == "eric" or -- FIXME, hardcoded
	       string.lower(command) == "phil" or
	       string.lower(command) == "bibi" or
	       string.lower(command) == "gui " or
	       string.lower(command) == "gay " then
		addMessage( string.upper(data) , 8 , true ) 
		table.insert( dialogLog , string.upper(data) .. " (" .. os.date("%X") .. ")" )
		local index = findPNJByClass( command )
		--PNJTable[index].ip, PNJTable[index].port = lip, lport -- we store the ip,port for further communications 
		clients[i].id = command
		if ack then
			tcpsend( clients[i].tcp, "(ack. " .. os.date("%X") .. ")" )
		end
	      end

	   else -- identified client
		
	    if clients[i].id ~= projectorId then
		-- this is a player calling us, from a known device. We answer
		addMessage( string.upper(clients[i].id) .. " : " .. string.upper(data) , 8 , true ) 
		table.insert( dialogLog , string.upper(clients[i].id) .. " : " .. string.upper(data) .. " (" .. os.date("%X") .. ")" )
		if ack then	
			tcpsend( clients[i].tcp, "(ack. " .. os.date("%X") .. ")" )
		end

	    else
		-- this is the projector
	      if command == "TARG" then

		local map = atlas:getVisible()
		if map and map.pawns then
		  local str = string.sub(data , 6)
                  local _,_,id1,id2 = string.find( str, "(%a+) (%a+)" )
		  local indexP = findPNJ( id1 )
		  local indexT = findPNJ( id2 )
		  updateTargetByArrow( indexP, indexT )
		else
		  io.write("inconsistent TARG command received while no map or no pawns\n")
		end

	      elseif command == "MPAW" then

		local map = atlas:getVisible()
		if map and map.pawns then
		  local str = string.sub(data , 6)
                  local _,_,id,x,y = string.find( str, "(%a+) (%d+) (%d+)" )
		  -- the two innocent lines below are important: x and y are returned as strings, not numbers, which is quite inocuous
		  -- except that tween() functions really expect numbers. Here we force x and y to be numbers.
		  x = x + 0
		  y = y + 0
		  for i=1,#map.pawns do 
			if map.pawns[i].id == id then 
				map.pawns[i].moveToX = x; map.pawns[i].moveToY = y; 
				pawnMaxLayer = pawnMaxLayer + 1
				map.pawns[i].layer = pawnMaxLayer
				map.pawns[i].timer = tween.new( pawnMovingTime , map.pawns[i] , { x = map.pawns[i].moveToX, y = map.pawns[i].moveToY } )
				break; 
			end 
		  end 
		  table.sort( map.pawns, function(a,b) return a.layer < b.layer end )
		else
		  io.write("inconsistent MPAW command received while no map or no pawns\n")
		end
	    end -- end of command TARG/MPAW

	  end -- end of identified client

	  end -- end of identified/unidentified

	 end -- end of data

	end -- end of client loop

	-- change snapshot offset if mouse  at bottom right or left
	local snapMax = #snapshots[currentSnap].s * (snapshotSize + snapshotMargin) - W
	if snapMax < 0 then snapMax = 0 end
	local x,y = love.mouse.getPosition()
	if (x < snapshotMargin * 4 ) and (y > snapshotH) and (y < messagesH) then
	  snapshots[currentSnap].offset = snapshots[currentSnap].offset + snapshotMargin * 2
	  if snapshots[currentSnap].offset > 0 then snapshots[currentSnap].offset = 0  end
	end
	if (x > W - snapshotMargin * 4 ) and (y > snapshotH) and (y < messagesH) then
	  snapshots[currentSnap].offset = snapshots[currentSnap].offset - snapshotMargin * 2
	  if snapshots[currentSnap].offset < -snapMax then snapshots[currentSnap].offset = -snapMax end
	end

  	view:update(dt)
  	yui.update({view})

	-- restore pawn color when needed
	-- move pawns progressively
	layout:update(dt)

  	-- store current mouse position in arrow mode
  	if arrowMode then 
		arrowX, arrowY = love.mouse.getPosition() 
	end
  
	-- change pawn color to red if they are the target of an arrow
	if pawnMove then
		-- check that we are in the map...
		local map = layout:getFocus()
		if (not map) or (not map:isInside(arrowX,arrowY)) then return end
	
		-- check if we are just over another pawn
		local target = map:isInsidePawn(arrowX,arrowY)

		if target and target ~= pawnMove then
			-- we are targeting someone, draw the target in red color !
			target.color = color.red
		end
	end

	-- change some button behaviour when needed
	nextButton.button.black = not nextFlash 
	if not nextButton.button.black then 
		nextButton.button.timer:tween('color', 0.25, nextButton.button, {color = { 80, 110, 180}}, 'linear') 
	else
		nextButton.button.timer:tween('color', 0.25, nextButton.button, {color = { 20, 20, 20}}, 'linear') 
	end

	if isAttorArm( focus ) then
	  attButton.button.black = false 
	  attButton.button.timer:tween('color', 0.25, attButton.button, {color = { 80, 110, 180}}, 'linear') 
	  armButton.button.black = false 
	  armButton.button.timer:tween('color', 0.25, armButton.button, {color = { 80, 110, 180}}, 'linear') 
	else
	  attButton.button.black = true 
	  attButton.button.timer:tween('color', 0.25, attButton.button, {color = { 20, 20, 20}}, 'linear') 
	  armButton.button.black = true 
	  armButton.button.timer:tween('color', 0.25, armButton.button, {color = { 20, 20, 20}}, 'linear') 
	end

	if thereIsDead then
	  clnButton.button.black = false 
	  clnButton.button.timer:tween('color', 0.25, clnButton.button, {color = { 80, 110, 180}}, 'linear') 
	else
	  clnButton.button.black = true
	  clnButton.button.timer:tween('color', 0.25, clnButton.button, {color = { 20, 20, 20}}, 'linear') 
	end

  	-- draw dices if requested
	-- there are two phases of 1 second each: drawDices (all dices) then drawDicesResult (does not count failed ones)
  	if drawDices then

  		box:update(dt)

		local immobile = false   
		for i=1,#box do
  		  	if box[i].velocity:abs() > 0.8 then break end -- at least one alive !
  			immobile = true
			drawDicesResult = true
		end

		if immobile then
  			-- for each die, retrieve the 4 points with positive z coordinate
  			-- there should always be 4 (and exactly 4) such points, unless 
  			-- very unlikely situations for the die (not horizontal...). 
  			-- in that case, there is no simple way to retrieve the face anyway
  			-- so forget it...

			lastDiceSum = diceSum

			diceSum = 0
  			for n=1,#box do
    			  local s = box[n]
			  local index = {0,0,0,0} -- will store 4 indexes in the end
			  local t = 1
			  for i=1,8 do if s[i][3] > 0 then index[t] = i; t = t+1 end end
			  local num = whichFace(index[1],index[2],index[3],index[4]) or 0 -- find face number, or 0 if not possible to decide 
			  if num >= 1 and num <= 4 then diceSum = diceSum + 1 end
  			end 

			if lastDiceSum ~= diceSum then diceStableTimer = 0 end
		end
  
		-- dice are removed after a fixed timelength (30 sec.) or after the result is stable for long enough (6 sec.)
    		drawDicesTimer = drawDicesTimer + dt
		diceStableTimer = diceStableTimer + dt
    		if drawDicesTimer >= 30 or diceStableTimer >= 6 then drawDicesTimer = 0; drawDices = false; drawDicesResult = false; end

  	end

	-- check PNJ-related timers
  	for i=1,PNJnum-1 do

  		-- temporarily change color of DEF (defense) value for each PNJ attacked within the last 3 seconds, 
    		if not PNJTable[i].acceptDefLoss then
      			PNJTable[i].lasthit = PNJTable[i].lasthit + dt
      			if (PNJTable[i].lasthit >= 3) then
        			-- end of timer for this PNJ
        			PNJTable[i].acceptDefLoss = true
        			PNJTable[i].lasthit = 0
      			end
    		end

		-- sort and reprint screen after 3 s. an INIT value has been modified
    		if PNJTable[i].initTimerLaunched then
      			PNJtext[i].init.color = color.red
      			PNJTable[i].lastinit = PNJTable[i].lastinit + dt
      			if (PNJTable[i].lastinit >= 3) then
        			-- end of timing for this PNJ
        			PNJTable[i].initTimerLaunched = false
        			PNJTable[i].lastinit = 0
        			PNJtext[i].init.color = color.darkblue
        			sortAndDisplayPNJ()
      			end
    		end

    		if (PNJTable[i].acceptDefLoss) then PNJtext[i].def.color = color.darkblue else PNJtext[i].def.color = { 240, 10, 10 } end

  	end

  	-- change color of "Round" value after a certain amount of time (5 s.)
  	if (newRound) then
    		roundTimer = roundTimer + dt
    		if (roundTimer >= 5) then
      			view.s.t.round.color = color.black
      			view.s.t.round.text = tostring(roundNumber)
      			newRound = false
      			roundTimer = 0
    		end
  	end

  	-- the "next round zone" is blinking (with frequency 400 ms) until "Next Round" is pressed
  	if (nextFlash) then
    		flashTimer = flashTimer + dt
    		if (flashTimer >= 0.4) then
      			flashSequence = not flashSequence
      			flashTimer = 0
    		end
  	else
    		-- reset flash, someone has pressed the button
    		flashSequence = 0
    		flashTimer = 0
  	end


	end


-- draw a small colored circle, at position x,y, with 'id' as text
function drawRound( x, y, kind, id )
	if kind == "target" then love.graphics.setColor(250,80,80,180) end
  	if kind == "attacker" then love.graphics.setColor(204,102,0,180) end
  	if kind == "danger" then love.graphics.setColor(66,66,238,180) end 
  	love.graphics.circle ( "fill", x , y , 15 ) 
  	love.graphics.setColor(0,0,0)
  	love.graphics.setFont(fontRound)
  	love.graphics.print ( id, x - string.len(id)*3 , y - 9 )
	end


function myStencilFunction( )
	local map = currentWindowDraw
	local x,y,mag,w,h = map.x, map.y, map.mag, map.w, map.h
        local zx,zy = -( x * 1/mag - W / 2), -( y * 1/mag - H / 2)
	love.graphics.rectangle("fill",zx,zy,w/mag,h/mag)
	for k,v in pairs(map.mask) do
		--local _,_,shape,x,y,wm,hm = string.find( v , "(%a+) (%d+) (%d+) (%d+) (%d+)" )
		local _,_,shape = string.find( v , "(%a+)" )
		if shape == "RECT" then 
			local _,_,_,x,y,wm,hm = string.find( v , "(%a+) (%-?%d+) (%-?%d+) (%d+) (%d+)" )
			x = zx + x/mag
			y = zy + y/mag
			love.graphics.rectangle( "fill", x, y, wm/mag, hm/mag) 
		elseif shape == "CIRC" then
			local _,_,_,x,y,r = string.find( v , "(%a+) (%-?%d+) (%-?%d+) (%d+%.?%d+)" )
		  	x = zx + x/mag
			y = zy + y/mag
			love.graphics.circle( "fill", x, y, r/mag ) 
		end
	end
	end

function love.draw() 

  local alpha = 80

  love.graphics.setColor(255,255,255,200)
  love.graphics.draw( backgroundImage , 0 , 0)

  -- bottom snapshots list
  love.graphics.setColor(255,255,255)
  for i=snapshots[currentSnap].index, #snapshots[currentSnap].s do
	local x = snapshots[currentSnap].offset + (snapshotSize + snapshotMargin) * (i-1) - (snapshots[currentSnap].s[i].w * snapshots[currentSnap].s[i].snapmag - snapshotSize) / 2
	if x > W then break end
	if x >= -snapshotSize then 
		if snapshots[currentSnap].s[i].selected then
  			love.graphics.setColor(unpack(color.red))
			love.graphics.rectangle("line", 
				snapshots[currentSnap].offset + (snapshotSize + snapshotMargin) * (i-1),
				snapshotH, 
				snapshotSize, 
				snapshotSize)
		end
		if currentSnap == 2 and snapshots[currentSnap].s[i].kind == "scenario" then
			-- do not draw scenario, too big... Just print "Scenario"
  			love.graphics.setColor(0,0,0)
			love.graphics.rectangle("line", 
				snapshots[currentSnap].offset + (snapshotSize + snapshotMargin) * (i-1),
				snapshotH, 
				snapshotSize, 
				snapshotSize)
 			love.graphics.setFont(fontRound)
			love.graphics.print( "Scenario" , 3 + snapshots[currentSnap].offset + (snapshotSize + snapshotMargin) * (i-1), snapshotH )
		else
  			love.graphics.setColor(255,255,255)
			love.graphics.draw( 	snapshots[currentSnap].s[i].im , 
				x ,
				snapshotH - ( snapshots[currentSnap].s[i].h * snapshots[currentSnap].s[i].snapmag - snapshotSize ) / 2, 
			    	0 , snapshots[currentSnap].s[i].snapmag, snapshots[currentSnap].s[i].snapmag )
		end
	end
  end
  

  -- small snapshot
  love.graphics.setColor(230,230,230)
  love.graphics.rectangle("line", W - W1 - 10, H - H1 - snapshotSize - snapshotMargin * 6 , W1 , H1 )
  if currentImage then 
    local w, h = currentImage:getDimensions()
    -- compute magnifying factor f to fit to screen, with max = 2
    local xfactor = W1 / w
    local yfactor = H1 / h
    local f = math.min( xfactor, yfactor )
    if f > 2 then f = 2 end
    w , h = f * w , f * h
    love.graphics.draw( currentImage , W - W1 - 10 +  (W1 - w) / 2, H - H1 - snapshotSize - snapshotMargin * 6 + ( H1 - h ) / 2, 0 , f, f )
  end

    love.graphics.setLineWidth(3)

    -- draw FOCUS if applicable
    love.graphics.setColor(0,102,0,alpha)
    if focus then love.graphics.rectangle("fill",PNJtext[focus].x+2,PNJtext[focus].y-5,W-12,42) end

    -- draw ATTACKERS if applicable
    love.graphics.setColor(174,102,0,alpha)
    if focusAttackers then
      for i,v in pairs(focusAttackers) do
        if v then
          local index = findPNJ(i)
          if index then 
		  love.graphics.rectangle("fill",PNJtext[index].x+2,PNJtext[index].y-5,W-12,42) 
		  -- emphasize defense value, but only for PNJ
    		  if not PNJTable[index].PJ then
			  love.graphics.setColor(255,0,0,200)
		  	  love.graphics.rectangle("fill",PNJtext[index].x+743,PNJtext[index].y-3, 26,39) 
		  end
		  PNJtext[index].def.color = { unpack(color.white) }
    		  love.graphics.setColor(204,102,0,alpha)
	  end
        end
      end
    end 

    -- draw TARGET if applicable
    love.graphics.setColor(250,60,60,alpha*1.5)
    local index = findPNJ(focusTarget)
    if index then love.graphics.rectangle("fill",PNJtext[index].x+2,PNJtext[index].y-5,W-12,42) end

  if nextFlash then
    -- draw a blinking rectangle until Next button is pressed
    if flashSequence then
      love.graphics.setColor(250,80,80,alpha*1.5)
    else
      love.graphics.setColor(0,0,0,alpha*1.5)
    end
    love.graphics.rectangle("fill",PNJtext[1].x+1010,PNJtext[1].y-5,400,(PNJnum-1)*43)
  end

  -- draw view itself
  view:draw()

   
  -- display global dangerosity
  local danger = computeGlobalDangerosity( )
  if danger ~= -1 then drawRound( 1315 , 70, "danger", tostring(danger) ) end
   
  for i = 1, PNJnum-1 do
  
    local offset = 1212
    
    -- display TARGET (in a colored circle) when applicable
    local index = findPNJ(PNJTable[i].target)
    if index then 
        local id = PNJTable[i].target
        if PNJTable[index].PJ then id = PNJTable[index].class end
        drawRound( PNJtext[i].x + offset, PNJtext[i].y + 15, "target", id )
    end
    
    offset = offset + 30 -- in any case

    -- display ATTACKERS (in a colored circle) when applicable
    if PNJTable[i].attackers then
      local sorted = {}
      for id, v in pairs(PNJTable[i].attackers) do if v then table.insert(sorted,id) end end
      table.sort(sorted)
      for k,id in pairs(sorted) do
          local index = findPNJ(id)
          if index and PNJTable[index].PJ then id = PNJTable[index].class end
          if index then drawRound( PNJtext[i].x + offset, PNJtext[i].y + 15, "attacker", id ) ; offset = offset + 30; end
      end
    end
    
    -- display dangerosity per PNJ
    if PNJTable[i].PJ then
      local danger = computeDangerosity( i )
      if danger ~= -1 then drawRound( PNJtext[i].x + offset, PNJtext[i].y + 15, "danger", tostring(danger) ) end
    end
    
    -- draw PNJ snapshot if applicable
    if PNJTable[i].snapshot then
       	    love.graphics.setColor(255,255,255)
	    local s = PNJTable[i].snapshot
	    local xoffset = s.w * s.snapmag * 0.5 / 2
	    love.graphics.draw( s.im , 210 - xoffset , PNJtext[i].y - 2 , 0 , s.snapmag * 0.5, s.snapmag * 0.5 ) 
    end

  end

  -- draw windows
  layout:draw() 

  -- draw arrow
  if arrowMode then

      -- draw arrow and arrow head
      love.graphics.setColor(unpack(color.red))
      love.graphics.line( arrowStartX, arrowStartY, arrowX, arrowY )
      local x3, y3, x4, y4 = computeTriangle( arrowStartX, arrowStartY, arrowX, arrowY)
      if x3 then
        love.graphics.polygon( "fill", arrowX, arrowY, x3, y3, x4, y4 )
      end
     
      -- draw circle or rectangle itself
      if arrowModeMap == "RECT" then 
		love.graphics.rectangle("line",arrowStartX, arrowStartY,(arrowX - arrowStartX),(arrowY - arrowStartY)) 
      elseif arrowModeMap == "CIRC" then 
		love.graphics.circle("line",(arrowStartX+arrowX)/2, (arrowStartY+arrowY)/2, distanceFrom(arrowX,arrowY,arrowStartX,arrowStartY) / 2) 
      end
 
 end  

 -- print messages zone in any case 
 love.graphics.setColor(255,255,255)
 love.graphics.rectangle( "fill", 0, messagesH, W, 22 )

 -- bottom applicative message
 local appmessage = "> " .. snapText[currentSnap]
 if not layout.globalDisplay then appmessage = appmessage .. " -- ESC mode is ON" end 	
 local m = layout:getFocus() 
 if m and atlas:isVisible(m) then 
	appmessage = appmessage .. " -- Map is VISIBLE"  	
	if m.sticky then appmessage = appmessage .. " and STICKY"  end
 end
 love.graphics.setColor(170,5,255)
 love.graphics.setFont(fontRound)
 love.graphics.print( appmessage, 5, messagesH )
 love.graphics.setColor(255,255,255)

 -- print messages eventually
 if messages[1] then
        if messages[1].important then 
		love.graphics.setColor(255,0,0)
	else
		love.graphics.setColor(10,60,220)
	end
	local wi = string.len(messages[1].text) * 6
        love.graphics.setFont(fontRound)
	love.graphics.setScissor( 0, messagesH, W , 22 )
	love.graphics.printf( messages[1].text, W - wi - 15 , messagesH - messages[1].offset ,W)
	love.graphics.setScissor()
 end

 -- draw dices if needed
 if drawDices then

 --use a coordinate system with 0,0 at the center
 --and an approximate width and height of 10
 local cx,cy=380,380
 local scale=cx/4
  
  love.graphics.push()
  love.graphics.translate(cx,cy)
  love.graphics.scale(scale)
  
  render.clear()

  --render.bulb(render.zbuffer) --light source
  for i=1,#dice do if dice[i] then render.die(render.zbuffer, dice[i].die, dice[i].star) end end
  render.paint()

  love.graphics.pop()
  --love.graphics.dbg()

    -- draw number if needed
    if drawDicesResult then
      love.graphics.setColor(unpack(color.white))
      love.graphics.setFont(fontDice)
      love.graphics.print(diceSum,650,4*viewh/5)
    end

  end 

end


function distanceFrom(x1,y1,x2,y2) return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) end

-- compute the "head" of the arrow, given 2 points (x1,y1) the starting point of the arrow,
-- and (x2,y2) the ending point. Return 4 values x3,y3,x4,y4 which are the positions of
-- 2 other points which constitute, with (x2,y2), the head triangle
function computeTriangle( x1, y1, x2, y2 )
  local L1 = distanceFrom(x1,y1,x2,y2)
  local L2 = 30
  if L1 < L2 then return nil end -- too small
  local theta = 15
  local x3 = x2 - (L2/L1)*((x1-x2)*math.cos(theta) + (y1 - y2)*math.sin(theta))
  local y3 = y2 - (L2/L1)*((y1-y2)*math.cos(theta) - (x1 - x2)*math.sin(theta))
  local x4 = x2 - (L2/L1)*((x1-x2)*math.cos(theta) - (y1 - y2)*math.sin(theta))
  local y4 = y2 - (L2/L1)*((y1-y2)*math.cos(theta) + (x1 - x2)*math.sin(theta))
  return x3,y3,x4,y4
  end


-- when mouse is released and an arrow is being draw, check if the ending point
-- is on a given PNJ, and update PNJ accordingly
function love.mousereleased( x, y )   

	-- check if we must close the window
	local x,y = love.mouse.getPosition()
	local w = layout:getWindow(x,y)
	if w and w.markForClosure then 
		w.markForClosure = false
		layout:setDisplay(w,false) 
	end

	-- we were moving the map. We stop now
	if mouseMove then mouseMove = false; return end

	-- we were moving a pawn. we stop now
	if pawnMove then 

		arrowMode = false

		-- check that we are in the map, or in another map...
		local sourcemap = layout:getFocus()
		local targetmap = layout:getWindow( x , y )
		if (not targetmap) or (targetmap.class ~= "map") then pawnMove = nil; return end -- we are nowhere ! abort

		local map = targetmap

		--
		-- we are in another map: we just allow a move, not an attack
		--
		if map ~= sourcemap then

			-- if the target map has no pawn size already fixed, it is not easy to determine the right one
			-- here, we do a kind of ratio depending on the images respective widths
			local size = (sourcemap.basePawnSize / sourcemap.w) * map.w
			size = size / map.mag

			-- create the new pawn at 0,0, remove the old one
			local p = map:createPawns( 0, 0 , size , pawnMove.id ) -- size is ignored if map has pawns already...
			if p then
			
				sourcemap:removePawn( pawnMove.id )

				-- we consider that the mouse position is at the center of the new image
  				local zx,zy = -( map.x * 1/map.mag - W / 2), -( map.y * 1/map.mag - H / 2)
				local px, py = (x - zx) * map.mag - p.sizex / 2 , (y - zy) * map.mag - p.sizey / 2

				-- now it is created, set it to correct position
				p.x, p.y = px, py

				-- the pawn will popup, no tween
				pawnMaxLayer = pawnMaxLayer + 1
				pawnMove.layer = pawnMaxLayer
				table.sort( map.pawns , function (a,b) return a.layer < b.layer end )
	
				-- we must stay within the limits of the map	
				if p.x < 0 then p.x = 0 end
				if p.y < 0 then p.y = 0 end
				if p.x + p.sizex + 6 > map.w then p.x = math.floor(map.w - p.sizex - 6) end
				if p.y + p.sizey + 6 > map.h then p.y = math.floor(map.h - p.sizey - 6) end
	
				if atlas:isVisible(sourcemap) then	
					tcpsend( projector , "ERAP " .. p.id )
					io.write("ERAP " .. p.id .. "\n")
				end

				if atlas:isVisible(map) then	

	  				local flag
	  				if p.PJ then flag = "1" else flag = "0" end
					local i = findPNJ( p.id )
	  				local f = p.snapshot.baseFilename -- FIXME: what about pawns loaded dynamically ?
	  				io.write("PAWN " .. p.id .. " " .. math.floor(p.x) .. " " .. math.floor(p.y) .. " " .. 
						math.floor(p.sizex * PNJTable[i].sizefactor) .. " " .. flag .. " " .. f .. "\n")
	  				tcpsend( projector, "PAWN " .. p.id .. " " .. math.floor(p.x) .. " " .. math.floor(p.y) .. " " .. 
						math.floor(p.sizex * PNJTable[i].sizefactor) .. " " .. flag .. " " .. f)
				end

			end
		--
		-- we stay on same map: it may be a move or an attack
		--
		else

		  -- check if we are just stopping on another pawn
		  local target = map:isInsidePawn(x,y)
		  if target and target ~= pawnMove then

			-- we have a target
			local indexP = findPNJ( pawnMove.id )
			local indexT = findPNJ( target.id )
			updateTargetByArrow( indexP, indexT )
			
		  else

			-- it was just a move, change the pawn position
			-- we consider that the mouse position is at the center of the new image
  			local zx,zy = -( map.x * 1/map.mag - W / 2), -( map.y * 1/map.mag - H / 2)
			pawnMove.moveToX, pawnMove.moveToY = (x - zx) * map.mag - pawnMove.sizex / 2 , (y - zy) * map.mag - pawnMove.sizey / 2
			pawnMaxLayer = pawnMaxLayer + 1
			pawnMove.layer = pawnMaxLayer
			table.sort( map.pawns , function (a,b) return a.layer < b.layer end )
	
			-- we must stay within the limits of the map	
			if pawnMove.moveToX < 0 then pawnMove.moveToX = 0 end
			if pawnMove.moveToY < 0 then pawnMove.moveToY = 0 end
			if pawnMove.moveToX + pawnMove.sizex + 6 > map.w then pawnMove.moveToX = math.floor(map.w - pawnMove.sizex - 6) end
			if pawnMove.moveToY + pawnMove.sizey + 6 > map.h then pawnMove.moveToY = math.floor(map.h - pawnMove.sizey - 6) end

			pawnMove.timer = tween.new( pawnMovingTime , pawnMove , { x = pawnMove.moveToX, y = pawnMove.moveToY } )
	
			tcpsend( projector, "MPAW " .. pawnMove.id .. " " ..  math.floor(pawnMove.moveToX) .. " " .. math.floor(pawnMove.moveToY) )		
			
		  end

		end

		pawnMove = nil; 
		return 

	end

	-- we were not drawing anything, nothing to do
  	if not arrowMode then return end

	-- from here, we know that we were drawing an arrow, we stop it now
  	arrowMode = false

	-- if we were drawing a pawn, we stop it now
	if arrowPawn then
		-- this gives the required size for the pawns
  	  	--local map = atlas:getMap()
		local map = layout:getFocus()
		local w = distanceFrom(arrowX,arrowY,arrowStartX,arrowStartY)
		map:createPawns( arrowX, arrowY, w )
		table.sort( map.pawns, function(a,b) return a.layer < b.layer end )
		arrowPawn = false
		return
	end

	-- if we were drawing a mask shape as well, we terminate it now (even if we are outside the map)
	if arrowModeMap then
	
		local map = layout:getFocus()
		assert( map and map.class == "map" )

	  	local command = nil

		local maxX, maxY, minX, minY = 0,0,0,0

	  	if arrowModeMap == "RECT" then

	  		if arrowStartX > arrowX then arrowStartX, arrowX = arrowX, arrowStartX end
	  		if arrowStartY > arrowY then arrowStartY, arrowY = arrowY, arrowStartY end
	  		local sx = math.floor( (arrowStartX + ( map.x / map.mag  - W / 2)) *map.mag )
	  		local sy = math.floor( (arrowStartY + ( map.y / map.mag  - H / 2)) *map.mag )
	  		local w = math.floor((arrowX - arrowStartX) * map.mag)
	  		local h = math.floor((arrowY - arrowStartY) * map.mag)
	  		command = "RECT " .. sx .. " " .. sy .. " " .. w .. " " .. h 
		
			maxX = sx + w
			minX = sx
			maxY = sy + h
			minY = sy
			if minX > maxX then minX, maxX = maxX, minX end
			if minY > maxY then minY, maxY = maxY, minY end

	  	elseif arrowModeMap == "CIRC" then

			local sx, sy = math.floor((arrowX + arrowStartX) / 2), math.floor((arrowY + arrowStartY) / 2)
	  		sx = math.floor( (sx + ( map.x / map.mag  - W / 2)) *map.mag )
	  		sy = math.floor( (sy + ( map.y / map.mag  - H / 2)) *map.mag )
			local r = distanceFrom( arrowX, arrowY, arrowStartX, arrowStartY) * map.mag / 2
	  		if r ~= 0 then command = "CIRC " .. sx .. " " .. sy .. " " .. r end

			maxX = sx + r
			minX = sx - r
			maxY = sy + r
			minY = sy - r
	  	end

	  	if command then 
			table.insert( map.mask , command ) 
			io.write("inserting new mask " .. command .. "\n")

			if minX < map.maskMinX then map.maskMinX = minX end
			if minY < map.maskMinY then map.maskMinY = minY end
			if maxX > map.maskMaxX then map.maskMaxX = maxX end
			if maxY > map.maskMaxY then map.maskMaxY = maxY end

	  		-- send over if requested
	  		if atlas:isVisible( map ) then tcpsend( projector, command ) end
	  	end

		arrowModeMap = nil
	
	-- not drawing a mask, so maybe selecting a PNJ
	else 
	   	-- depending on position on y-axis
  	  	for i=1,PNJnum-1 do
    		  if (y >= PNJtext[i].y-5 and y < PNJtext[i].y + 42) then
      			-- this stops the arrow mode
      			arrowMode = false
			arrowModeMap = nil
      			arrowStopIndex = i
      			-- set new target
      			if arrowStartIndex ~= arrowStopIndex then 
        			updateTargetByArrow(arrowStartIndex, arrowStopIndex) 
      			end
    		  end
		end	

	end

	end
	
-- put FOCUS on a PNJ line when mouse is pressed (or remove FOCUS if outside PNJ list)
function love.mousepressed( x, y , button )   

	local window = layout:click(x,y)

	if window and window.class ~= "map" then
		-- want to move window 
	   	mouseMove = true
	   	arrowMode = false
	   	arrowStartX, arrowStartY = x, y
		arrowModeMap = nil
		return
	end

	-- clicking somewhere in the map, this starts either a Move or a Mask	
	if window and window.class == "map" then

		local map = window

		local p = map:isInsidePawn(x,y)

		if p then

		  -- clicking on a pawn will start an arrow that will represent
		  -- * either an attack, if the arrow ends on another pawn
		  -- * or a move, if the arrow ends somewhere else on the map
		  pawnMove = p
	   	  arrowMode = true
	   	  arrowStartX, arrowStartY = x, y
	   	  mouseMove = false 
		  arrowModeMap = nil 

		-- not clicking a pawn, it's either a map move or an rect/circle mask...
		elseif button == 1 then --Left click
	  		if not love.keyboard.isDown("lshift") and not love.keyboard.isDown("lctrl") then 
				-- want to move map
	   			mouseMove = true
	   			arrowMode = false
	   			arrowStartX, arrowStartY = x, y
				arrowModeMap = nil

          		elseif love.keyboard.isDown("lctrl") then
				-- want to create pawn 
				arrowPawn = true
	   			arrowMode = true
	   			arrowStartX, arrowStartY = x, y
	   			mouseMove = false 
				arrowModeMap = nil 

			else
	   			if map.kind ~= "scenario" then 
					-- want to create a mask
	   				arrowMode = true
					arrowModeMap = maskType 
	   				mouseMove = false 
	   				arrowStartX, arrowStartY = x, y
          			end
        		end


        	end

		return

    	end

  -- Clicking on upper button section does not change the current FOCUS, but cancel the arrow
  if y < 40 then 
    arrowMode = false
    return
  end
 
  -- Clicking on bottom section may select a snapshot image
  if y > H - snapshotSize - snapshotMargin * 2 then
    -- incidentally, this cancels the arrow as well
    arrowMode = false
    -- check if there is a snapshot there
    local index = math.floor((x - snapshots[currentSnap].offset) / ( snapshotSize + snapshotMargin)) + 1
    -- 2 possibilities: if this image is already selected, then use it
    -- otherwise, just select it (and deselect any other eventually)
    if index >= 1 and index <= #snapshots[currentSnap].s then
      if snapshots[currentSnap].s[index].selected then
	      -- already selected
	      snapshots[currentSnap].s[index].selected = false 

	      -- Three different ways to use a snapshot

	      -- 1: general image, sent it to projector
	      if currentSnap == 1 then
	      	currentImage = snapshots[currentSnap].s[index].im
	      	-- remove the 'visible' flag from maps (eventually)
	      	atlas:removeVisible()
		tcpsend(projector,"ERAS") 	-- remove all pawns (if any) 
    	      	-- send the filename over the socket
		if snapshots[currentSnap].s[index].is_local then
			tcpsendBinary{ file = snapshots[currentSnap].s[index].file } 
 			tcpsend(projector,"BEOF")
		elseif fullBinary then
			tcpsendBinary{ filename = snapshots[currentSnap].s[index].filename } 
 			tcpsend(projector,"BEOF")
		else
	      		tcpsend( projector, "OPEN " .. snapshots[currentSnap].s[index].baseFilename)
		end
	      	tcpsend( projector, "DISP") 	-- display immediately

	      -- 2: map. This should open a window 
	      elseif currentSnap == 2 then

			layout:setDisplay( snapshots[currentSnap].s[index] , true )
			layout:setFocus( snapshots[currentSnap].s[index] ) 
	
	      -- 3: Pawn. If focus is set, use this image as PJ/PNJ pawn image 
	      else
			if focus then PNJTable[ focus ].snapshot = snapshots[currentSnap].s[index] end

	      end

      else
	      -- not selected, select it now
	    for i,v in ipairs(snapshots[currentSnap].s) do
	      if i == index then snapshots[currentSnap].s[i].selected = true
	      else snapshots[currentSnap].s[i].selected = false end
	    end

	    -- If in pawn mode, this does NOT change the focus, so we break now !
	    if currentSnap == 3 then return end
      end
    end
  end

  -- we assume that the mouse was pressed outside PNJ list, this might change below
  lastFocus = focus
  focus = nil
  focusTarget = nil
  focusAttackers = nil

  -- check which PNJ was selected, depending on position on y-axis
  for i=1,PNJnum-1 do
    if (y >= PNJtext[i].y-5 and y < PNJtext[i].y + 42) then
      PNJTable[i].focus = true
      lastFocus = focus
      focus = i
      focusTarget = PNJTable[i].target
      focusAttackers = PNJTable[i].attackers
      -- this starts the arrow mode if PNJ
      --if not PNJTable[i].PJ then
        arrowMode = true
        arrowStartX = x
        arrowStartY = y
        arrowStartIndex = i
      --end
    else
      PNJTable[i].focus = false
    end
  end

end


Atlas = {}
Atlas.__index = Atlas

function Atlas:removeVisible() self.visible = nil end
function Atlas:isVisible(map) return self.visible == map end
function Atlas:getVisible() return self.visible end 
function Atlas:toggleVisible( map )
	if not map then return end
	if map.kind == "scenario" then return end -- a scenario is never displayed to the players
	if self.visible == map then 
		self.visible = nil 
		map.sticky = false
		-- erase snapshot !
		currentImage = nil 
	  	-- remove all pawns remotely !
		tcpsend( projector, "ERAS")
	  	-- send hide command to projector
		tcpsend( projector, "HIDE")
	else    
		self.visible = map 
		-- change snapshot !
		currentImage = map.im
	  	-- remove all pawns remotely !
		tcpsend( projector, "ERAS")
		-- send to projector
		if map.is_local and not fullBinary then
		  tcpsendBinary{ file=map.file } 
 		  tcpsend(projector,"BEOF")
		elseif fullBinary then
		  tcpsendBinary{ filename=map.filename } 
 		  tcpsend(projector,"BEOF")
		else 
  		  tcpsend( projector, "OPEN " .. map.baseFilename )
		end
  		-- send mask if applicable
  		if map.mask then
			for k,v in pairs( map.mask ) do
				tcpsend( projector, v )
			end
  		end
		-- send pawns if any
		for i=1,#map.pawns do
			local p = map.pawns[i]
			-- check the pawn state before sending it: 
			-- * it might happen that the character has been removed from the list
			-- * don't send dead pawns (what for?)
			local index = findPNJ( p.id )
			if index and (not PNJTable[index].is_dead) then
				local flag = 0
				if p.PJ then flag = 1 end
				-- send over the socket
				if p.snapshot.is_local then
					tcpsendBinary{ file=p.snapshot.file }
	  				tcpsend( projector, "PEOF " .. p.id .. " " .. math.floor(p.x) .. " " .. math.floor(p.y) .. " " .. math.floor(p.sizex) .. " " .. flag )
				elseif fullBinary then
					tcpsendBinary{ filename=p.snapshot.filename }
	  				tcpsend( projector, "PEOF " .. p.id .. " " .. math.floor(p.x) .. " " .. math.floor(p.y) .. " " .. math.floor(p.sizex) .. " " .. flag )
				else
	  				local f = p.snapshot.filename
	  				f = string.gsub(f,baseDirectory,"")
	  				tcpsend( projector, "PAWN " .. p.id .. " " .. math.floor(p.x) .. " " .. math.floor(p.y) .. " " .. math.floor(p.sizex) .. " " .. flag .. " " .. f)
				end
			end
		end
		-- set map frame
  		tcpsend( projector, "MAGN " .. 1/map.mag)
  		tcpsend( projector, "CHXY " .. math.floor(map.x) .. " " .. math.floor(map.y) )
  		tcpsend( projector, "DISP")

	end
	end

function Atlas.new() 
  local new = {}
  setmetatable(new,Atlas)
  --new.maps = {}
  new.visible = nil -- map currently visible (or nil if none)
  return new
  end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- return the index of the 1st character of a class, or nil if not found
function findPNJByClass( class )
  if not class then return nil end
  class = string.lower( trim(class) )
  for i=1,PNJnum-1 do if string.lower(PNJTable[i].class) == class then return i end end
  return nil
  end

function findClientByName( class )
  if not class then return nil end
  if not clients then return nil end
  class = string.lower( trim(class) )
  for i=1,#clients do if clients[i].id and string.lower(clients[i].id) == class then return clients[i].tcp end end
  return nil
  end

-- return the character by its ID, or nil if not found
function findPNJ( id )
  if not id then return nil end
  for i=1,PNJnum-1 do if PNJTable[i].id == id then return i end end
  return nil
  end

function love.mousemoved(x,y,dx,dy)

if mouseMove then

   local map = layout:getFocus()

   if map then

	-- store old values, in case we need to rollback because we get outside limits
	local oldx, oldy = map.x, map.y

	-- check changes
	local newx = map.x - dx * map.mag 
	local newy = map.y - dy * map.mag 

	-- check we are still within margins of the screen
  	local zx,zy = -( map.x * 1/map.mag - W / 2), -( map.y * 1/map.mag - H / 2)
	
	if zx > W - margin or zx + map.w / map.mag < margin then newx = oldx end	
	if zy > H - margin or zy + map.h / map.mag < margin then newy = oldy end	

	-- move the map 
	if (newx ~= oldx or newy ~= oldy) then
		map:move( newx, newy )
	end

    end
end

end

function love.keypressed( key, isrepeat )

-- keys applicable in any context
-- we expect:
-- 'lctrl + d' : open dialog window
-- 'lctrl + h' : open help window
-- 'lctrl + tab' : give focus to the next window if any
-- 'escape' : hide or restore all windows 
if key == "d" and love.keyboard.isDown("lctrl") then
  if dialogWindow then 
	layout:setDisplay( dialogWindow, true )
	layout:setFocus( dialogWindow ) 
  else
	dialogWindow = Dialog:new{w=800,h=220,x=400,y=110}
	layout:addWindow( dialogWindow , true ) -- display it. Set focus
	layout:setFocus( dialogWindow ) 
  end
  return
end
if key == "h" and love.keyboard.isDown("lctrl") then
  if helpWindow then 
	layout:setDisplay( helpWindow, true )
	layout:setFocus( helpWindow ) 
  else
	helpWindow = Help:new{w=1000,h=480,x=500,y=240}
	layout:addWindow( helpWindow , true ) -- display it. Set focus
	layout:setFocus( helpWindow ) 
  end
  return
end
if key == "escape" then
	layout:toggleDisplay()
	return
end
if key == "tab" and love.keyboard.isDown("lctrl") then
	layout:nextWindow()
	return
end

-- other keys applicable 
local window = layout:getFocus()
if not window then
  -- no window selected at the moment, we expect:
  -- 'up', 'down' within the PNJ list
  -- 'space' to change snapshot list
  if focus and key == "down" then
    if focus < PNJnum-1 then 
      lastFocus = focus
      focus = focus + 1
      focusAttackers = PNJTable[ focus ].attackers
      focusTarget  = PNJTable[ focus ].target
    end
    return
  end
  
  if focus and key == "up" then
    if focus > 1 then 
      lastFocus = focus
      focus = focus - 1
      focusAttackers = PNJTable[ focus ].attackers
      focusTarget  = PNJTable[ focus ].target
    end
    return
  end

  if key == 'space' then
	  currentSnap = currentSnap + 1
	  if currentSnap == 4 then currentSnap = 1 end
	  return
  end
  
else
  -- a window is selected. Keys applicable to any window:
  -- 'lctrl + c' : recenter window
  -- 'lctrl + x' : close window
  if key == "x" and love.keyboard.isDown("lctrl") then
	layout:setDisplay( window, false )
	return
  end
  if key == "c" and love.keyboard.isDown("lctrl") then
	window:move( window.w / 2, window.h / 2 )
	return
  end

  if     window.class == "dialog" then
	-- 'return' to submit a dialog message
	-- 'backspace'
	-- any other key is treated as a message input
  	if (key == "return") then
	  doDialog( string.gsub( dialog, dialogBase, "" , 1) )
	  dialog = dialogBase
  	end

  	if (key == "backspace") and (dialog ~= dialogBase) then
         -- get the byte offset to the last UTF-8 character in the string.
         local byteoffset = utf8.offset(dialog, -1)
         if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            dialog = string.sub(dialog, 1, byteoffset - 1)
         end
  	end
	
  elseif window.class == "map" and window.kind == "map" then

	local map = window

	-- keys for map. We expect:
	-- Zoom in and out
	-- 'tab' to get to circ or rect mode
	-- 'lctrl + p' : remove all pawns
	-- 'lctrl + v' : toggle visible / not visible
	-- 'lctrl + z' : maximize/minimize (zoom)
	-- 'lctrl + s' : stick map
	-- 'lctrl + u' : unstick map

  	if key == "s" and love.keyboard.isDown("lctrl") then
		if not atlas:isVisible(map) then return end -- if map is not visible, do nothing
		if not map.sticky then
			-- we enter sticky mode. Normally, the projector is fully aligned already, so
			-- we just save the current status for future restoration
			map.stickX, map.stickY, map.stickmag = map.x, map.y, map.magindex
			map.sticky = true
		else
			-- we were already sticky, with a different status probably. So we store this
			-- new one, but we need to align the projector as well
			map.stickX, map.stickY, map.stickmag = map.x, map.y, map.magindex
			tcpsend( projector, "CHXY " .. math.floor(map.x) .. " " .. math.floor(map.y) ) 
			tcpsend( projector, "MAGN " .. 1/map.mag ) 
		end
		return
  	end

  	if key == "u" and love.keyboard.isDown("lctrl") then
		if not map.sticky then return end
		window:move( window.stickX , window.stickY )
		window.magindex = window.stickmag
		window:zoom(0)
		window.sticky = false
		return
	end

    	if key == keyZoomIn then
		ignoreLastChar = true
		map:zoom( 1 )
    	end 

    	if key == keyZoomOut then
		ignoreLastChar = true
		map:zoom( -1 )
    	end 
    
	if key == "v" and love.keyboard.isDown("lctrl") then
		atlas:toggleVisible( map )
		if not atlas:isVisible( map ) then map.sticky = false end
    	end

   	if key == "p" and love.keyboard.isDown("lctrl") then
	   map.pawns = {} 
	   map.basePawnSize = nil
	   tcpsend( projector, "ERAS" )    
   	end
   	if key == "z" and love.keyboard.isDown("lctrl") then
		map:maximize()
	end

   	if key == "tab" then
	  if maskType == "RECT" then maskType = "CIRC" else maskType = "RECT" end
   	end
	
  elseif window.class == "map" and window.kind == "scenario" then

	local map = window

	-- keys for map. We expect:
	-- Zoom in and out
	-- 'return' to submit a query
	-- 'backspace'
	-- 'tab' to get to next search result
	-- any other key is treated as a search query input
    	if key == keyZoomIn then
		ignoreLastChar = true
		map:zoom( 1 )
    	end 

    	if key == keyZoomOut then
		ignoreLastChar = true
		map:zoom( -1 )
    	end 
	
   	if key == "backspace" and text ~= textBase then
        	-- get the byte offset to the last UTF-8 character in the string.
        	local byteoffset = utf8.offset(text, -1)
        	if byteoffset then
            	-- remove the last UTF-8 character.
            	-- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            		text = string.sub(text, 1, byteoffset - 1)
        	end
    	end

   	if key == "tab" then
	  if searchIterator then map.x,map.y,searchPertinence,searchIndex,searchSize = searchIterator() end
   	end

   	if key == "return" then
	  searchIterator = doSearch( string.gsub( text, textBase, "" , 1) )
	  text = textBase
	  if searchIterator then map.x,map.y,searchPertinence,searchIndex,searchSize = searchIterator() end
   	end

  end
  end

  end


function leave()
	if server then server:close() end
	for i=1,#clients do clients[i].tcp:close() end
	if tcpbin then tcpbin:close() end
	if logFile then logFile:close() end
	end

-- load initial data from file at startup
function loadStartup( t )

    -- call with kind == "all" or "pawn", and path
    local path = assert(t.path)
    local kind = t.kind or "all"

    -- list all files in that directory, by executing a command ls or dir
    local allfiles = {}, command
    if love.system.getOS() == "OS X" then
	    io.write("ls '" .. path .. "' > .temp\n")
	    os.execute("ls '" .. path .. "' > .temp")
    elseif love.system.getOS() == "Windows" then
	    io.write("dir /b \"" .. path .. "\" > .temp\n")
	    os.execute("dir /b \"" .. path .. "\" > .temp ")
    end

    -- store output
    for line in io.lines (".temp") do table.insert(allfiles,line) end

    -- remove temporary file
    os.remove (".temp")

    for k,f in pairs(allfiles) do

      io.write("scanning file '" .. f .. ":")

      if kind == "pawns" then

	-- all (image) files are considered as pawn images
	if string.sub(f,-4) == '.jpg' or string.sub(f,-4) == '.png'  then

		local s = Snapshot:new{ filename = path .. sep .. f }
		local store = true

        	if string.sub(f,1,4) == 'pawn' then
		-- check if corresponds to a known PJ. In that case, do not
		-- store it in the snapshot list, as it is supposed to be unique
			local pjname = string.sub(f,5, f:len() - 4 )
			io.write("Looking for a PJ named " .. pjname .. "\n")
			local index = findPNJByClass( pjname ) 
			if index then 
				PNJTable[index].snapshot = s  
				store = false
			end
		end	
   
		if store then table.insert( snapshots[3].s, s ) end

		-- check if default image 
      		if f == 'pawnDefault.jpg' then
			defaultPawnSnapshot = s 
		end

		-- check if corresponds to a PNJ template as well
		for k,v in pairs( templateArray ) do
			if v.image == f then 
				v.snapshot = s 
				io.write("store image for class " .. v.class .. "\n")
			end
		end

	end
 
      elseif f == 'scenario.txt' then 

      	--   SCENARIO IMAGE: 	named scenario.jpg
      	--   SCENARIO TEXT:	associated to this image, named scenario.txt
      	--   MAPS: 		map*jpg or map*png, they are considered as maps and loaded as such
      	--   PJ IMAGE:		pawnPJname.jpg or .png, they are considered as images for corresponding PJ
      	--   PNJ DEFAULT IMAGE:	pawnDefault.jpg
      	--   PAWN IMAGE:		pawn*.jpg or .png
      	--   SNAPSHOTS:		*.jpg or *.png, all are snapshots displayed at the bottom part

	      readScenario( path .. sep .. f ) 
	      io.write("Loaded scenario at " .. path .. sep .. f .. "\n")

      elseif f == 'scenario.jpg' then

	local s = Map:new()
	s:load{ kind="scenario", filename=path .. sep .. f }
	layout:addWindow( s , false )
	io.write("Loaded scenario image file at " .. path .. sep .. f .. "\n")
	table.insert( snapshots[2].s, s ) 

      elseif f == 'pawnDefault.jpg' then

	defaultPawnSnapshot = Snapshot:new{ filename = path .. sep .. f }
	table.insert( snapshots[3].s, defaultPawnSnapshot ) 

      elseif string.sub(f,-4) == '.jpg' or string.sub(f,-4) == '.png'  then

        if string.sub(f,1,4) == 'pawn' then

		local s = Snapshot:new{ filename = path .. sep .. f }
		table.insert( snapshots[3].s, s ) 

		local pjname = string.sub(f,5, f:len() - 4 )
		io.write("Looking for PJ " .. pjname .. "\n")
		local index = findPNJByClass( pjname ) 
		if index then PNJTable[index].snapshot = s  end

	elseif string.sub(f,1,3) == 'map' then

	  local s = Map:new()
	  s:load{ filename=path .. sep .. f } 
	  layout:addWindow( s , false )
	  table.insert( snapshots[2].s, s ) 

 	else

	  table.insert( snapshots[1].s, Snapshot:new{ filename = path .. sep .. f } ) 
	  
        end

      end

    end

end


options = { { opcode="-s", longopcode="--scenario", mandatory=false, varname="fadingDirectory", value=true, default="." , 
		desc="Path to scenario directory" },
	    { opcode="-d", longopcode="--debug", mandatory=false, varname="debug", value=false, default=false , 
		desc="Run in debug mode"},
	    { opcode="-l", longopcode="--log", mandatory=false, varname="log", value=false, default=false , 
		desc="Log to file (fading.log) instead of stdout"},
	    { opcode="-a", longopcode="--ack", mandatory=false, varname="acknowledge", value=false, default=false ,
		desc="With FS mobile: Send an automatic acknowledge reply for each message received"},
	    { opcode="-p", longopcode="--port", mandatory=false, varname="port", value=true, default=serverport,
		desc="Specify server local port, by default 12345" },
	    { opcode="-y", longopcode="--binary", mandatory=false, varname="binary", value=false, default=false,
		desc="Systematically send binary files to the projector, instead of filesystem references" },
	    { opcode="", mandatory=true, varname="baseDirectory" , desc="Path to global directory"} }
	    
--
-- Main function
-- Load PNJ class file, print (empty) GUI, then go on
--
function love.load( args )

    -- main window layout
    layout = mainLayout:new()

    -- parse arguments
    local parse = doParse( args )

    -- get images & scenario directory, provided at command line
    fadingDirectory = parse.fadingDirectory 
    baseDirectory = parse.arguments[1]
    debug = parse.debug
    serverport = parse.port
    fullBinary = parse.binary
    ack = parse.acknowledge
    sep = '/'

    -- log file
    if parse.log then
      logFile = io.open("fading.log","w")
      io.output(logFile)
    end

    -- GUI initializations...
    yui.UI.registerEvents()
    love.window.setTitle( "Fading Suns Combat Tracker" )

    -- load fonts
    fontDice = love.graphics.newFont("yui/yaoui/fonts/OpenSans-ExtraBold.ttf",90)
    fontRound = love.graphics.newFont("yui/yaoui/fonts/OpenSans-Bold.ttf",12)
    fontSearch = love.graphics.newFont("yui/yaoui/fonts/OpenSans-ExtraBold.ttf",16)
   
    -- adjust number of rows in screen
    PNJmax = math.floor( viewh / 42 )

    -- some adjustments on different systems
    if love.system.getOS() == "Windows" then

    	W, H = love.window.getDesktopDimensions()
    	W, H = W*0.98, H*0.92 

	messagesH		= H - 22
	snapshotH 		= messagesH - snapshotSize - snapshotMargin

        PNJmax = 14 
	keyZoomIn, keyZoomOut = ':', '!'

    end

    love.window.setMode( W  , H  , { fullscreen=false, resizable=true, display=1} )
    love.keyboard.setKeyRepeat(true)

    -- some small differences in windows: separator is not the same, and some weird completion
    -- feature in command line may add an unexpected doublequote char at the end of the path (?)
    -- that we want to remove
    if love.system.getOS() == "Windows" then
	    local n = string.len(fadingDirectory)
	    if string.sub(fadingDirectory,1,1) ~= '"' and 
		    string.sub(fadingDirectory,n,n) == '"' then
		    fadingDirectory=string.sub(fadingDirectory,1,n-1)
	    end
    	    sep = '\\'
    end

    io.write("base directory   : |" .. baseDirectory .. "|\n") ; addMessage("base directory : " .. baseDirectory .. "\n")
    io.write("fading directory : |" .. fadingDirectory .. "|\n") ; addMessage("fading directory : " .. fadingDirectory .. "\n")

    -- initialize class template list  and dropdown list (opt{}) at the same time
    -- later on, we might attach some images to these classes if we find them
    -- try 2 locations to find data. Merge results if 2 files 
    local opt = loadTemplates{ 	baseDirectory .. sep .. "data" , 
				baseDirectory .. sep .. fadingDirectory .. sep .. "data" } 

    opt = opt or {""}
    local current_class = opt[1]

    -- create view structure
    --love.graphics.setBackgroundColor( 255, 205, 205 )
    backgroundImage = love.graphics.newImage( "background.jpg" )

    view = yui.View(0, 0, vieww, viewh, {
        margin_top = 5,
        margin_left = 5,
	yui.Stack({name="s",
            yui.Flow({name="t",
                yui.HorizontalSpacing({w=10}),
                yui.Button({name="nextround", text="  Next Round  ", size=size, black = true, 
			onClick = function(self) if self.button.black then return end 
				 		 if checkForNextRound() then nextRound() end end }),
                yui.Text({text="Round #", size=size, bold=1, center = 1}),
                yui.Text({name="round", text=tostring(roundNumber), size=32, w = 50, bold=1, color={0,0,0} }),
                yui.FlatDropdown({options = opt, size=size-2, onSelect = function(self, option) current_class = option end}),
                yui.HorizontalSpacing({w=10}),
                yui.Button({text=" Create ", size=size, 
			onClick = function(self) return generateNewPNJ(current_class) and sortAndDisplayPNJ() end }),
                yui.HorizontalSpacing({w=50}),
                yui.Button({name = "rollatt", text="     Roll Attack     ", size=size, black = true,
			onClick = function(self) if self.button.black then return end rollAttack("attack") end }), 
		yui.HorizontalSpacing({w=10}),
                yui.Button({name = "rollarm", text="     Roll  Armor     ", size=size, black = true,
			onClick = function(self) if self.button.black then return end rollAttack("armor") end }),
                yui.HorizontalSpacing({w=150}),
                yui.Button({name="cleanup", text="       Cleanup       ", size=size, 
			onClick = function(self) return removeDeadPNJ() and sortAndDisplayPNJ() end }),
                yui.HorizontalSpacing({w=270}),
                yui.Button({text="    Quit    ", size=size, onClick = function(self) leave(); love.event.quit() end }),
              }), -- end of Flow
            createPNJGUIFrame(),
           }) -- end of Stack
        --})
      })


    nextButton = view.s.t.nextround
    attButton = view.s.t.rollatt
    armButton = view.s.t.rollarm
    clnButton = view.s.t.cleanup

    nextButton.button.black = true
    attButton.button.black = true
    armButton.button.black = true
    clnButton.button.black = true
    
    -- create socket and listen to any client
    server = socket.tcp()
    server:settimeout(0)
    local success, msg = server:bind(address, serverport)
    io.write("server local bind to " .. tostring(address) .. ":" .. tostring(serverport) .. ":" .. tostring(success) .. "," .. tostring(msg) .. "\n")
    if not success then leave(); love.event.quit() end
    server:listen(10)

    tcpbin = socket.tcp()
    tcpbin:bind(address, serverport+1)
    tcpbin:listen(1)

    -- some initialization stuff
    generateUID = UIDiterator()

    -- create PJ automatically (1 instance of each!)
    -- later on, an image might be attached to them, if we find one
    createPJ()

    -- create a new empty atlas (an array of maps)
    atlas = Atlas.new()

    -- load various data files 
    loadStartup{ path = baseDirectory .. sep .. fadingDirectory }
    loadStartup{ path = baseDirectory .. sep .. "pawns" , kind = "pawns" }

end


