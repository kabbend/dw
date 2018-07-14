
local utf8 		= require 'utf8'
local codepage		= require 'codepage'	-- windows cp1252 support
local socket 		= require 'socket'	-- general networking
local parser    	= require 'parse'	-- parse command line arguments
local tween		= require 'tween'	-- tweening library (manage transition states)
local yui 		= require 'yui.yaoui' 	-- graphical library on top of Love2D
local rpg 		= require 'rpg'		-- code related to the RPG itself
local mainLayout 	= require 'layout'	-- global layout to manage windows
local Window 		= require 'window'	-- Window class & system
local theme		= require 'theme'	-- global theme
local widget		= require 'widget'	-- widgets components

-- specific window classes
local Help			= require 'help'		-- Help window
local notificationWindow 	= require 'notificationWindow'	-- notifications
local iconWindow		= require 'iconWindow'		-- grouped 'Action'/'Histoire' icons
local Dialog			= require 'dialog'		-- dialog with players 
local setupWindow		= require 'setup'		-- setup/configuration information 
local projectorWindow		= require 'projector'		-- project images to players 
local snapshotBar		= require 'snapshot'		-- all kinds of images 
local Map			= require 'map'			-- maps 
local urlWindow			= require 'urlWindow'		-- provide an URL to load 

-- specific object classes
local Snapshot			= require 'snapshotClass'	-- store and display one image 
local Pawn			= require 'pawn'		-- store and display one pawn to display on map 
local Atlas			= require 'atlas'		-- store some information on maps (eg. which one is visible) 

layout = mainLayout:new()		-- one instance of the global layout
atlas = nil 				-- one instance of the atlas. Will be set in init()

function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

if love.system.getOS() == "Windows" then __WINDOWS__ = true end

layout.H1, layout.W1 	= 140, 140
layout.snapshotSize 	= 70 			-- w and h of each snapshot
layout.screenMargin 	= 40			-- screen margin in map mode
layout.intW		= 2 			-- interval between windows
layout.snapshotMargin	= 7 			-- space between images and screen border

local iconSize = theme.iconSize 
local sep = '/'

-- maps & scenario stuff
local ignoreLastChar	= false
local keyZoomIn		= ':'			-- default on macbookpro keyboard. Changed at runtime for windows
local keyZoomOut 	= '=' 			-- default on macbookpro keyboard. Changed at runtime for windows
local keyPaste		= 'lgui'		-- on mac only

--
-- GLOBAL VARIABLES
--

debug = true 

-- main layout
currentWindowDraw 	= nil

-- tcp information for network
address, serverport	= "*", "12345"		-- server information
server			= nil			-- server tcp object
ip,port 		= nil, nil		-- projector information
clients			= {}			-- list of clients. A client is a couple { tcp-object , id } where id is a PJ-id or "*proj"
projector		= nil			-- direct access to tcp object for projector
projectorId		= "*proj"		-- special ID to distinguish projector from other clients
chunksize 		= (8192 - 1)		-- size of the datagram when sending binary file
fullBinary		= false			-- if true, the server will systematically send binary files instead of local references

-- various mouse movements
mouseMove		= false			-- a window is being moved
pawnMove 		= nil			-- pawn currently moved by mouse movement

-- drag & drop data
dragMove		= false
dragObject		= { originWindow = nil, object = nil, snapshot = nil }

-- pawns and PJ snapshots
defaultPawnSnapshot	= nil		-- default image to be used for pawns
pawnMaxLayer		= 1
pawnMovingTime		= 2		-- how many seconds to complete a movement on the map ?

-- current text input
-- A window or widget waiting for input should set these functions
textActiveCallback		= nil			-- if set, function to call with keyboard input (argument: one char)
textActiveBackspaceCallback	= nil			-- if set, function to call on a backspace 
textActivePasteCallback		= nil			-- if set, function to call on a paste clipboard
textActiveCopyCallback		= nil			-- if set, function to call on a copy clipboard 
textActiveLeftCallback		= nil			-- if set, function to call on left arrow 	
textActiveRightCallback		= nil			-- if set, function to call on right arrow	

-- array of PJ and PNJ characters
-- Only PJ at startup (PNJ are created upon user request)
-- Maximum number is PNJmax
-- A Dead PNJ counts as 1, except if explicitely removed from the list
PNJTable 	= {}		

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

-- get filename without path. depends on separator, which depends itself on OS (windows or OS X)
function splitFilename(strFilename)
	return string.match (strFilename,"[^" .. sep .. "]+$")
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
	if __WINDOWS__ then filename = codepage.utf8tocp1252(filename) end
  	file = assert( io.open( filename, 'rb' ) )
  	local data = file:read(chunksize)
 	while data do
       		c:send(data) -- send chunk
		io.write("sending " .. string.len(data) .. " bytes. \n")
        	data = file:read( chunksize )
 	end
 end
 file:close()
 c:close()
 end

-- capture text input, by calling active callback function if any
-- it may happen that a key should be ignored, because part of an existing command 
-- (eg. when pressing CTRL+z to zoom a scenario, 'z' should be discarded for search input)
function love.textinput(t)
	if not textActiveCallback then return end
	if ignoreLastChar then ignoreLastChar = false; return end
	textActiveCallback( t )
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

		local snap = Snapshot:new{ file = file, size=layout.snapshotSize }
		if is_a_pawn then 
			table.insert( layout.snapshotWindow.snapshots[4].s , snap )
			snap.kind = "pawn"	-- FIXME is it still useful ?
		else
			table.insert( layout.snapshotWindow.snapshots[1].s , snap )
			snap.kind = "image"	
	  		-- set the local image
	  		layout.pWindow.currentImage = snap.im 
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

	  elseif is_a_map then 
	    local m = Map:new()
	    m:load{ file=file, layout=layout } -- no filename, and file object means local 
	    layout:addWindow( m , false )
	    table.insert( layout.snapshotWindow.snapshots[2].s , m )

	  end

	end

-- LOVE basic functions
function love.update(dt)

	-- update all windows
	layout:update(dt)

	-- all code below does not take place until the environement is fully initialized (ie baseDirectory is defined)
	if not initialized then return end

	-- listening to anyone calling on our port 
	local tcp = server:accept()
	if tcp then
		-- add it to the client list, we don't know who is it for the moment
		table.insert( clients , { tcp = tcp, id = nil } )
		local ad,ip = tcp:getpeername()
		layout.notificationWindow:addMessage("receiving connection from " .. tostring(ad) .. " " .. tostring(ip))
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
		layout.notificationWindow:addMessage("receiving projector call")
		clients[i].id = projectorId
		projector = clients[i].tcp
		if love.system.getOS() == "OS X" then
	    		tcpsend(projector,"CONN MAC")
		else
	    		tcpsend(projector,"CONN WIN")
		end
	
	      elseif data == "CONNECTB" then 
		io.write("receiving projector call, binary mode\n")
		layout.notificationWindow:addMessage("Receiving projector call")
		layout.notificationWindow:addMessage("Projector is requesting full binary mode")
		fullBinary = true
		clients[i].id = projectorId
		projector = clients[i].tcp
		if love.system.getOS() == "OS X" then
	    		tcpsend(projector,"CONN MAC")
		else
	    		tcpsend(projector,"CONN WIN")
		end
	
	      end

	   else -- identified client
		
		-- this is the projector

		-- allowed commands from projector are:
		--
		-- TARG id1 id2 	Pawn with id1 attacks pawn with id2
		-- MPAW id x y		Pawn with id moves to x,y in the map
		--

	      if command == "TARG" then

		local map = atlas:getVisible()
		if map and map.pawns then
		  local str = string.sub(data , 6)
                  local _,_,id1,id2 = string.find( str, "(%a+) (%a+)" )
		  local indexP = findPNJ( id1 )
		  local indexT = findPNJ( id2 )
		  rpg.updateTargetByArrow( indexP, indexT )
		else
		  io.write("inconsistent TARG command received while no map or no pawns\n")
		end

	      elseif command == "MPAW" then

		local map = atlas:getVisible()
		if map and map.pawns then
		  local str = string.sub(data , 6)
                  local _,_,id,x,y = string.find( str, "(%a+) (%d+) (%d+)" )
		  -- the innocent line below is important: x and y are returned as strings, not numbers, which is quite inocuous
		  -- except that tween() functions really expect numbers. Here we force x and y to be numbers.
		  x, y = x + 0, y + 0
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

	  end -- end of identified/unidentified

	 end -- end of data

	end -- end of client loop

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
		local target, _ = map:isInsidePawn(arrowX,arrowY)

		if target and target ~= pawnMove then
			-- we are targeting someone, draw the target in red color !
			target.color = theme.color.red
		end
	end

	end

-- this function draws the fog of war on maps. As it is a function called automatically by love engine without arguments,
-- it must rely on a global variable 'currentWindowDraw' to know which map is currently to be drawn.
function myStencilFunction( )
	local map = currentWindowDraw
	local x,y,mag,w,h = map.x, map.y, map.mag, map.w, map.h
        local zx,zy = -( x * 1/mag - layout.W / 2), -( y * 1/mag - layout.H / 2)
	love.graphics.rectangle("fill",zx,zy,w/mag,h/mag)
	for k,v in pairs(map.mask) do
		local _,_,shape = string.find( v , "(%a+)" )
		if shape == "RECT" then 
			local _,_,_,x,y,wm,hm = string.find( v , "(%a+) (%-?%d+) (%-?%d+) (%d+) (%d+)" )
			x = zx + x/mag - map.translateQuadX/mag
			y = zy + y/mag - map.translateQuadY/mag
			love.graphics.rectangle( "fill", x, y, wm/mag, hm/mag) 
		elseif shape == "CIRC" then
			local _,_,_,x,y,r = string.find( v , "(%a+) (%-?%d+) (%-?%d+) (%d+%.?%d+)" )
			x = zx + x/mag - map.translateQuadX/mag
			y = zy + y/mag - map.translateQuadY/mag
			love.graphics.circle( "fill", x, y, r/mag ) 
		end
	end
	end

-- global draw function
function love.draw() 

  local alpha = 80

  -- draws screen background
  love.graphics.setColor(255,255,255,200)
  love.graphics.draw( theme.backgroundImage , 0, 0, 0, layout.W / theme.backgroundImage:getWidth(), layout.H / theme.backgroundImage:getHeight() )

  love.graphics.setLineWidth(2)

  -- draw all windows
  layout:draw() 

  -- all code below does not take place until the environement is fully initialized (ie baseDirectory is defined)
  if not initialized then return end

  -- if drag & drop, draw a small snapshot at mouse position
  if dragMove then
  	love.graphics.setColor(255,255,255)
	local x,y = love.mouse.getPosition()
	local s = dragObject.snapshot
	love.graphics.draw(s.thumb, x, y)
  end

  -- draw arrow eventually
  if arrowMode then

      -- draw arrow and arrow head
      love.graphics.setColor(unpack(theme.color.red))
      love.graphics.line( arrowStartX, arrowStartY, arrowX, arrowY )
      local x3, y3, x4, y4 = computeTriangle( arrowStartX, arrowStartY, arrowX, arrowY)
      if x3 then
        love.graphics.polygon( "fill", arrowX, arrowY, x3, y3, x4, y4 )
      end

      if arrowPawn then
        -- draw a pawn at cursor position (to determine the size on this particular map)
	local map = layout:getFocus()
	local w = distanceFrom(arrowX,arrowY,arrowStartX,arrowStartY)
	love.graphics.setColor(255,255,255,180)
	local s = defaultPawnSnapshot
	if (s) then 
		local f = w / s.im:getWidth() 
		love.graphics.draw( s.im, arrowStartX, arrowStartY, 0, f, f )
	end
      end
 
      if arrowModeMap == "RECT" then 
        -- draw circle or rectangle itself
		love.graphics.rectangle("line",arrowStartX, arrowStartY,(arrowX - arrowStartX),(arrowY - arrowStartY)) 
      elseif arrowModeMap == "CIRC" then 
		love.graphics.circle("line",(arrowStartX+arrowX)/2, (arrowStartY+arrowY)/2, distanceFrom(arrowX,arrowY,arrowStartX,arrowStartY) / 2) 
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

-- handle all possible actions when mouse is released 
function love.mousereleased( x, y )   

	layout:mousereleased(x,y)

	-- check if we must close a window (ie. we were pressing the 'close' icon)
	local x,y = love.mouse.getPosition()
	local w = layout:getWindow(x,y)
	if w and w.markForClosure then 
		w.markForClosure = false
		layout:setDisplay(w,false)
		-- if it's a map, we release image memory. Image will be eventually reloaded if needed
		if w.class == "map" then io.write("releasing memory for map " .. w.title .. "\n"); w.im = nil end 
	end

	-- we were dragging an object, we drop it 
	if dragMove then
		dragMove = false
		if w then w:drop( dragObject ) end
	end

	-- we were moving or resizing the window. We stop now
	if mouseResize then 
		mouseResize = false
		mouseMove = false 
		-- we were resizing a map. Send the result to the projector eventually
		local window = layout:getFocus()
		if window and window.class == "map" and atlas:getVisible() == window and not window.sticky then
  			tcpsend( projector, "MAGN " .. 1/window.mag)
  			tcpsend( projector, "CHXY " .. math.floor(window.x+window.translateQuadX) .. " " .. math.floor(window.y+window.translateQuadY) )
		end
		return 
	end
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
  				local zx,zy = -( map.x * 1/map.mag - layout.W / 2), -( map.y * 1/map.mag - layout.H / 2)
				local px, py = (x - zx) * map.mag - p.sizex / 2 , (y - zy) * map.mag - p.sizey / 2

				-- now it is created, set it to correct position
				p.x, p.y = px + map.translateQuadX, py + map.translateQuadY

				-- the pawn will popup, no tween
				pawnMaxLayer = pawnMaxLayer + 1
				pawnMove.layer = pawnMaxLayer
				table.sort( map.pawns , function (a,b) return a.layer < b.layer end )
	
				-- we must stay within the limits of the map	
				if p.x < 0 then p.x = 0 end
				if p.y < 0 then p.y = 0 end
				local w,h = map.w, map.h
				if map.quad then w,h = map.im:getDimensions() end
				if p.x + p.sizex + 6 > w then p.x = math.floor(w - p.sizex - 6) end
				if p.y + p.sizey + 6 > h then p.y = math.floor(h - p.sizey - 6) end
	
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
						--math.floor(p.sizex * PNJTable[i].sizefactor) .. " " .. flag .. " " .. f .. "\n")
						math.floor(p.sizex) .. " " .. flag .. " " .. f .. "\n")
	  				tcpsend( projector, "PAWN " .. p.id .. " " .. math.floor(p.x) .. " " .. math.floor(p.y) .. " " .. 
						--math.floor(p.sizex * PNJTable[i].sizefactor) .. " " .. flag .. " " .. f)
						math.floor(p.sizex) .. " " .. flag .. " " .. f)
				end

			end
		--
		-- we stay on same map: it may be a move or an attack
		--
		else

		  -- check if we are just stopping on another pawn
		  local target, _ = map:isInsidePawn(x,y)
		  if target and target ~= pawnMove then

			-- we have a target
			local indexP = findPNJ( pawnMove.id )
			local indexT = findPNJ( target.id )
			rpg.updateTargetByArrow( indexP, indexT )
			
		  else

			-- it was just a move, change the pawn position
			-- we consider that the mouse position is at the center of the new image
  			local zx,zy = -( map.x * 1/map.mag - layout.W / 2), -( map.y * 1/map.mag - layout.H / 2)
			pawnMove.moveToX, pawnMove.moveToY = (x - zx) * map.mag - pawnMove.sizex / 2 , (y - zy) * map.mag - pawnMove.sizey / 2
			pawnMove.moveToX = pawnMove.moveToX + map.translateQuadX
			pawnMove.moveToY = pawnMove.moveToY + map.translateQuadY
			
			pawnMaxLayer = pawnMaxLayer + 1
			pawnMove.layer = pawnMaxLayer
			table.sort( map.pawns , function (a,b) return a.layer < b.layer end )
	
			-- we must stay within the limits of the (unquad) map	
			if pawnMove.moveToX < 0 then pawnMove.moveToX = 0 end
			if pawnMove.moveToY < 0 then pawnMove.moveToY = 0 end
			local w,h = map.w, map.h
			if map.quad then w,h = map.im:getDimensions() end
			
			if pawnMove.moveToX + pawnMove.sizex + 6 > w then pawnMove.moveToX = math.floor(w - pawnMove.sizex - 6) end
			if pawnMove.moveToY + pawnMove.sizey + 6 > h then pawnMove.moveToY = math.floor(h - pawnMove.sizey - 6) end

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
		if map.basePawnSize then
			map:createPawns( arrowX, arrowY, w )
			table.sort( map.pawns, function(a,b) return a.layer < b.layer end )
		else
			map:setPawnSize(w)
		end
		arrowPawn = false
		return
	end

	-- if we were drawing a mask shape as well, we terminate it now (even if we are outside the map)
	if arrowModeMap and not arrowQuad then
	
		local map = layout:getFocus()
		assert( map and map.class == "map" )

	  	local command = nil

		local maxX, maxY, minX, minY = 0,0,0,0

	  	if arrowModeMap == "RECT" then

	  		if arrowStartX > arrowX then arrowStartX, arrowX = arrowX, arrowStartX end
	  		if arrowStartY > arrowY then arrowStartY, arrowY = arrowY, arrowStartY end
	  		local sx = math.floor( (arrowStartX + ( map.x / map.mag  - layout.W / 2)) *map.mag )
	  		local sy = math.floor( (arrowStartY + ( map.y / map.mag  - layout.H / 2)) *map.mag )
	  		local w = math.floor((arrowX - arrowStartX) * map.mag)
	  		local h = math.floor((arrowY - arrowStartY) * map.mag)

			-- if quad, apply current translation
			sx, sy = sx + map.translateQuadX, sy + map.translateQuadY

	  		command = "RECT " .. sx .. " " .. sy .. " " .. w .. " " .. h 
		
			maxX = sx + w
			minX = sx
			maxY = sy + h
			minY = sy
			if minX > maxX then minX, maxX = maxX, minX end
			if minY > maxY then minY, maxY = maxY, minY end

	  	elseif arrowModeMap == "CIRC" then

			local sx, sy = math.floor((arrowX + arrowStartX) / 2), math.floor((arrowY + arrowStartY) / 2)
	  		sx = math.floor( (sx + ( map.x / map.mag  - layout.W / 2)) *map.mag )
	  		sy = math.floor( (sy + ( map.y / map.mag  - layout.H / 2)) *map.mag )
			local r = distanceFrom( arrowX, arrowY, arrowStartX, arrowStartY) * map.mag / 2

			-- if quad, apply current translation
			sx, sy = sx + map.translateQuadX, sy + map.translateQuadY

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
	
	elseif arrowQuad then
		-- drawing a Quad on a map
		local map = layout:getFocus()
		assert( map and map.class == "map" )
	
		map:setQuad(arrowStartX, arrowStartY, arrowX, arrowY)
	
      		-- this stops the arrow mode
      		arrowMode = false
		arrowQuad = false
		arrowModeMap = nil

	else 
		-- not drawing a mask, so maybe selecting a PNJ
	   	-- depending on position on y-axis
  	  	for i=1,#PNJTable do
    		  if (y >= PNJtext[i].y-5 and y < PNJtext[i].y + 42) then
      			-- this stops the arrow mode
      			arrowMode = false
			arrowModeMap = nil
      			arrowStopIndex = i
      			-- set new target
      			if arrowStartIndex ~= arrowStopIndex then 
        			rpg.updateTargetByArrow(arrowStartIndex, arrowStopIndex) 

      			end
    		  end
		end	

	end

	end

-- handle all actions when the mouse is pressed	
function love.mousepressed( x, y , button )   

	local window = layout:click(x,y)

	-- clicking somewhere in the map, this starts either a Move or a Mask	
	if window and window.class == "map" then

		local map = window

		local p, hitClicked = map:isInsidePawn(x,y)

		if p and not hitClicked then
		  -- clicking on a pawn will start an arrow that will represent
		  -- * either an attack, if the arrow ends on another pawn
		  -- * or a move, if the arrow ends somewhere else on the map
		  pawnMove = p
	   	  arrowMode = true
	   	  arrowStartX, arrowStartY = x, y
	   	  mouseMove = false 
		  arrowModeMap = nil 

		elseif p and hitClicked then
		  -- if hit symbol was clicked, we decrease it...
		  local i = findPNJ( p.id )
		  if i then 
			is_dead = rpg.hitPNJ( i ) 
			if is_dead and atlas:isVisible( map ) then tcpsend( projector , "KILL " .. p.id ) end
			end		 
 
		elseif button == 1 then --Left click
		  -- not clicking a pawn, it's either a map move or an rect/circle mask...
	  		if not love.keyboard.isDown("lshift") and not love.keyboard.isDown("lctrl") 
				and not love.keyboard.isDown("lalt") then 
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
			elseif love.keyboard.isDown("lalt") then
				-- want to create a quad, but only if none already
				if not map.quad then
				  arrowMode = true
				  arrowQuad = true
	   			  arrowStartX, arrowStartY = x, y
	   			  mouseMove = false 
				  arrowModeMap = "RECT" 
				end
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

end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- return the index of the 1st character of a class, or nil if not found
function findPNJByClass( class )
  if not class then return nil end
  class = string.lower( trim(class) )
  for i=1,#PNJTable do if string.lower(PNJTable[i].class) == class then return i end end
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
  for i=1,#PNJTable do if PNJTable[i].id == id then return i end end
  return nil
  end

function love.mousemoved(x,y,dx,dy)

layout:mousemoved(x,y,dx,dy)

local w = layout:getFocus()
if not w then return end

if mouseResize then

	local zx,zy = w:WtoS(0,0)
	local mx,my = w:WtoS(w.w, w.h)

	-- check we are still within the window limits
	if x >= zx + 40 and y >= zy +40 then
		if w.whResizable then
		  assert(w.class == "map")
		  --local ratio = w.w / w.h
		  local projected = (x - mx)+(y - my)
		  local neww= w.w + projected * w.mag
		  local originalw, originalh = w.im:getDimensions()
		  if w.quad then _,_,originalw, originalh = w.quad:getViewport() end
		  local oldmag = originalw / w.w
		  local newmag = originalw / neww
		  if w.class == "map" then 
			w.mag = w.mag + (newmag - oldmag) 
			local cx,cy = w:WtoS(0,0)
			w:translate(zx-cx,zy-cy)
		  end
		else
		  if not w.wResizable then dx = 0 end
		  if not w.hResizable then dy = 0 end
		  w.w = w.w + dx * w.mag
		  w.h = w.h + dy * w.mag
		end
	end
 
elseif mouseMove then

	-- store old values, in case we need to rollback because we get outside limits
	local oldx, oldy = w.x, w.y

	-- check changes
	local newx = w.x - dx * w.mag 
	local newy = w.y - dy * w.mag 

	-- check we are still within margins of the screen
  	local zx,zy = -( newx * 1/w.mag - layout.W / 2), -( newy * 1/w.mag - layout.H / 2)
	
	if zx > layout.W - layout.screenMargin or zx + w.w / w.mag < layout.screenMargin then newx = oldx end	
	if zy > layout.H - layout.screenMargin or zy + w.h / w.mag < layout.screenMargin then newy = oldy end	

	local deltax, deltay = newx - oldx, newy - oldy

	-- move the map 
	if (newx ~= oldx or newy ~= oldy) then
		w:move( newx, newy )
		if w == layout.storyWindow then layout.actionWindow:move( layout.actionWindow.x + deltax, layout.actionWindow.y + deltay ) end
		if w == layout.actionWindow then layout.storyWindow:move( layout.storyWindow.x + deltax, layout.storyWindow.y + deltay ) end
	end

end

end

-- handle all actions when a key is pressed
function love.keypressed( key, isrepeat )

-- check if a callback is set and must be activated
if textActiveBackspaceCallback 	and key == "backspace" 	then textActiveBackspaceCallback(); return end
if textActiveLeftCallback 	and key == "left" 	then textActiveLeftCallback(); return end
if textActiveRightCallback 	and key == "right" 	then textActiveRightCallback(); return end
if textActivePasteCallback 	and key == "v" 	and love.keyboard.isDown(keyPaste) then textActivePasteCallback(); return end
if textActiveCopyCallback 	and key == "c" 	and love.keyboard.isDown(keyPaste) then textActiveCopyCallback(); return end

-- code below is executed only if server is initialized
if not initialized then return end

-- keys applicable in any context
-- we expect:
-- 'lctrl + d' : open dialog window
-- 'lctrl + f' : open setup window
-- 'lctrl + h' : open help window
-- 'lctrl + g' : open graph scenario window
-- 'lctrl + r' : restore all windows to initial state
-- 'lctrl + tab' : give focus to the next window if any
-- 'escape' : hide or restore all windows 

-- 'lctrl + b' : display bar (snapshots) window 
-- 'lctrl + p' : display projector window 

if key == "g" and love.keyboard.isDown("lctrl") then
  layout:toggleWindow( layout.sWindow )
  return
end
if key == "d" and love.keyboard.isDown("lctrl") then
  layout:toggleWindow( layout.dialogWindow )
  return
end
if key == "h" and love.keyboard.isDown("lctrl") then 
  layout:toggleWindow( layout.helpWindow )
  return
end
if key == "f" and love.keyboard.isDown("lctrl") then 
  layout:toggleWindow( layout.dataWindow )
  return
end
if key == "b" and love.keyboard.isDown("lctrl") then 
  layout:setDisplay( layout.snapshotWindow, true )
  layout:setFocus( layout.snapshotWindow )
  return
end
if key == "p" and love.keyboard.isDown("lctrl") then 
  layout:setDisplay( layout.pWindow, true )
  layout:setFocus( layout.pWindow )
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
if key == "r" and love.keyboard.isDown("lctrl") then
	if layout.actionWindow.open then
		layout:hideAll()	
		layout:restoreBase(layout.pWindow)
		layout:restoreBase(layout.snapshotWindow)
	elseif layout.storyWindow.open then
		layout:hideAll()	
		layout:restoreBase(layout.pWindow)
		layout:restoreBase(layout.snapshotWindow)
		layout:restoreBase(layout.scenarioWindow)
	end
end

-- other keys applicable 
local window = layout:getFocus()

if window then
  -- a window is selected. Keys applicable to any window:
  --[[ 'lctrl + C' : recenter window ]]
  -- 'lctrl + x' : close window
  if not window.alwaysVisible and inTable(window.buttons,'close') and key == "x" and love.keyboard.isDown("lctrl") then
	layout:setDisplay( window, false )
	return
  end
  if key == "c" and love.keyboard.isDown("lctrl")
  and love.keyboard.isDown("lshift") then
	window:move( window.w / 2, window.h / 2 )
	return
  end
  if window.class == "snapshot" then
  
  	-- 'space' to change snapshot list
	if key == 'space' then
		window:getNext()
	  	return
  	end

  elseif window.class == "map" and window.kind == "map" then

	local map = window

	-- keys for map. We expect:
	-- Zoom in and out
	-- 'tab' to get to circ or rect mode
	-- 'lctrl + p' : remove all pawns
	-- 'lctrl + v' : toggle visible / not visible
	-- 'lctrl + z' : zoom in / out
	-- 'lctrl + s' : stick map
	-- 'lctrl + u' : unstick map

  	if key == "s" and love.keyboard.isDown("lctrl") then
		map:sticky()
		return
  	end

  	if key == "u" and love.keyboard.isDown("lctrl") then
		map:unsticky()
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
		if not atlas:isVisible( map ) then map.sticky = false else 
		  layout.notificationWindow:addMessage("Map '" .. map.displayFilename .. "' is now visible to players. All your changes will be relayed to them")
		  if not map.mask or #map.mask <= 1 then
		    layout.notificationWindow:addMessage("Map '" .. map.displayFilename .. "' is fully covered by Fog of War. Players will see nothing !")
		  end
		end
    	end

   	if key == "p" and love.keyboard.isDown("lctrl") then
	   map.pawns = {} 
	   map.basePawnSize = nil
	   tcpsend( projector, "ERAS" )    
   	end
   	if key == "z" and love.keyboard.isDown("lctrl") then
		map:fullSize()
	end

   	if key == "tab" then
	  if maskType == "RECT" then maskType = "CIRC" else maskType = "RECT" end
   	end
	
  end
  end

  end

-- some cleanup when leaving
function leave()
	if server then server:close() end
	for i=1,#clients do clients[i].tcp:close() end
	if tcpbin then tcpbin:close() end
	if logFile then logFile:close() end
	end

-- load initial data from file at startup
function parseDirectory( t )

    -- call with kind == "all" or "pawn", and path
    local path = assert(t.path)
    local kind = t.kind or "all"

    -- list all files in that directory, by executing a command ls or dir
    local allfiles = {}, command
    if love.system.getOS() == "OS X" then
	    io.write("ls '" .. path .. "' > .temp\n")
	    os.execute("ls '" .. path .. "' > .temp0 && iconv -f utf8-mac -t utf-8 .temp0 > .temp")
    elseif __WINDOWS__ then
	    local pathcp1252 = codepage.utf8tocp1252(path)
	    io.write("dir /b \"" .. pathcp1252 .. "\" > temp\n")
	    local cf = io.open("cmdfs.bat","w")
	    os.execute("chcp 65001 & cmd.exe /c dir /b \"" .. pathcp1252 .. "\" > .temp & chcp 850\n")
	    cf:close()
    end

    -- store output
    for line in io.lines (".temp") do table.insert(allfiles,line) end

    -- remove temporary file
    os.remove (".temp")

    for k,f in pairs(allfiles) do

      io.write("scanning file '" .. f .. "'\n")

      if kind == "maps" then

	-- all (image) files are considered as maps 
	if string.sub(f,-4) == '.jpg' or string.sub(f,-4) == '.png'  then
		local s = Map:new()
          	s:load{ filename= path .. sep .. f, layout=layout }
          	layout:addWindow( s , false )
          	table.insert( layout.snapshotWindow.snapshots[2].s, s )
	end

      elseif kind == "pawns" then

	-- all (image) files are considered as pawn images
	if string.sub(f,-4) == '.jpg' or string.sub(f,-4) == '.png'  then

		local s = Snapshot:new{ filename = path .. sep .. f, size=layout.snapshotSize }

        	if string.sub(f,1,4) == 'pawn' then
		-- check if corresponds to a known PJ
			local pjname = string.sub(f,5, f:len() - 4 )
			io.write("Looking for a PJ named " .. pjname .. "\n")
			for i=1,#RpgClasses do
			if RpgClasses[i].class == pjname then 
				RpgClasses[i].snapshot = s 
				templateArray[pjname].snapshot = s
				io.write("store image '" .. f .. "' as Snapshot for PJ " .. RpgClasses[i].class .. "\n")
			end
			end
  		end
 
		--table.insert( layout.snapshotWindow.snapshots[4].s, s )

		-- check if default image 
      		if f == 'pawnDefault.jpg' or f == 'pawnDefault.png' or 
      		   f == 'defaultPawn.jpg' or f == 'defaultPawn.png' 
		then
			defaultPawnSnapshot = s 
		end

		-- check if corresponds to a PNJ template as well, either as snapshot or as popup
		for i=1,#RpgClasses do
			if RpgClasses[i].image == f then 
				RpgClasses[i].snapshot = s 
				templateArray[RpgClasses[i].class].snapshot = s
				io.write("store image '" .. f .. "' as Snapshot for class " .. RpgClasses[i].class .. "\n")
			end
			if RpgClasses[i].popup == f then 
				RpgClasses[i].snapshotPopup = s 
				templateArray[RpgClasses[i].class].snapshotPopup = s
				io.write("store image '" .. f .. "' as Popup for class " .. RpgClasses[i].class .. "\n")
			end
		end

	end

      elseif f == 'pawnDefault.jpg' then

	defaultPawnSnapshot = Snapshot:new{ filename = path .. sep .. f , size=layout.snapshotSize }
	--table.insert( layout.snapshotWindow.snapshots[4].s, defaultPawnSnapshot ) 

      elseif string.sub(f,-4) == '.jpg' or string.sub(f,-4) == '.png'  then

        if string.sub(f,1,4) == 'pawn' then

		local s = Snapshot:new{ filename = path .. sep .. f, size=layout.snapshotSize }
		--table.insert( layout.snapshotWindow.snapshots[4].s, s ) 
		
		local pjname = string.sub(f,5, f:len() - 4 )
		io.write("Looking for a PJ named " .. pjname .. "\n")
		for i=1,#RpgClasses do
			if RpgClasses[i].class == pjname then 
				RpgClasses[i].snapshot = s 
				templateArray[RpgClasses[i].class].snapshot = s
				io.write("store image '" .. f .. "' as Snapshot for PJ " .. RpgClasses[i].class .. "\n")
			end
		end

	elseif string.sub(f,1,3) == 'map' then

	  local s = Map:new()
	  s:load{ filename= path .. sep .. f, layout=layout } 
	  layout:addWindow( s , false )
	  table.insert( layout.snapshotWindow.snapshots[2].s, s ) 

 	else
	 
	  io.write("loading " .. f .. "\n")
	  local s = Snapshot:new{ filename = path .. sep .. f, size=layout.snapshotSize } 
	  assert(s)
	  table.insert( layout.snapshotWindow.snapshots[1].s, s ) 
	  
        end

      end

    end



end

function init() 

    -- create basic windows
    local pWindow = projectorWindow:new{ w=layout.W1, h=layout.H1, x=-(layout.WC+layout.intW+3)+layout.W/2,
					y=-(layout.H - 3*iconSize - layout.snapshotSize - 2*layout.intW - layout.H1 - 2 )+layout.H/2 
					- 2*theme.iconSize 
					,layout=layout}

    local storyWindow = iconWindow:new{ mag=2.1, text = "L'Histoire", image = theme.storyImage, w=theme.storyImage:getWidth(), 
				  h=theme.storyImage:getHeight() , x=-1220, y=400,layout=layout}

    local actionWindow = iconWindow:new{ mag=2.1, text = "L'Action", image = theme.actionImage, w=theme.actionImage:getWidth(), 
				   h=theme.actionImage:getHeight(), x=-1220,y=700,layout=layout} 

    local notifWindow = notificationWindow:new{ w=500, h=120, x=-layout.W/2,y=layout.H/2-60,layout=layout } 

    local dialogWindow = Dialog:new{w=800,h=220,x=400,y=110,layout=layout}

    local helpWindow = Help:new{w=1000,h=580,x=500,y=240,layout=layout}

    local dataWindow = setupWindow:new{ w=600, h=400, x=300,y=layout.H/2-100, init=true,layout=layout} 

    local snapshotWindow = snapshotBar:new{ w=layout.W-6*layout.intW, h=layout.snapshotSize+2, x=-layout.intW+layout.W/2, 
					y=-(layout.H-layout.snapshotSize)+layout.H/2 ,
					layout=layout }

    -- do not display them yet
    -- basic windows (as opposed to maps, for instance) are also stored by name, so we can retrieve them easily elsewhere in the code
    layout:addWindow( pWindow , 	true, "pWindow" )
    layout:addWindow( snapshotWindow , 	true, "snapshotWindow" )
    layout:addWindow( notifWindow , 	false, "notificationWindow" )
    layout:addWindow( dialogWindow , 	false, "dialogWindow" )
    layout:addWindow( helpWindow , 	false, "helpWindow" ) 
    layout:addWindow( dataWindow , 	false, "dataWindow" )

    layout:addWindow( storyWindow , 	false, "storyWindow" )
    layout:addWindow( actionWindow , 	false, "actionWindow" )

    io.write("base directory   : " .. baseDirectory .. "\n") ; layout.notificationWindow:addMessage("base directory : " .. baseDirectory .. "\n")
    io.write("scenario directory : " .. fadingDirectory .. "\n") ; layout.notificationWindow:addMessage("scenario : " .. fadingDirectory .. "\n")

    if __WINDOWS__ then

      -- all filenames are stored in UTF8 encoding, but on windows we need to pass paths and names encoded properly in case
      -- of special characters (accentuated, symbols etc.). Properly means UTF16 or Unicode, but these encodings are not directly 
      -- possible thru io.open() layer (thru C api). So, we use a (somehow) degraded encoding CP1252, which corresponds more or
      -- less to Extended ASCII, far from complete but enough for western usual lingual plane...
      --
      -- We use this CP1252 encoding on 2 occasions:
      -- * when we search the filesystem, in loadClasses() and parseDirectory() 
      -- * each time we call io.open()
      --
      baseDirectoryCp1252 =   codepage.utf8tocp1252( baseDirectory )
      io.write("cp1252 base directory : " .. baseDirectoryCp1252 .. "\n")
      fadingDirectoryCp1252 =   codepage.utf8tocp1252( fadingDirectory )
      io.write("cp1252 scenario directory : " .. fadingDirectoryCp1252 .. "\n")

      local uWindow = urlWindow:new{w=1000,h=38,x=1000-layout.W/2,layout=layout, path=baseDirectoryCp1252..sep..fadingDirectoryCp1252..sep,
					y= -layout.H/2+theme.iconSize+layout.intW+2*layout.snapshotSize }
      layout:addWindow( uWindow , false, "uWindow" )

    else

      local uWindow = urlWindow:new{w=1000,h=38,x=1000-layout.W/2,layout=layout, path=baseDirectory..sep..fadingDirectory..sep,
					y= -layout.H/2+theme.iconSize+layout.intW+2*layout.snapshotSize }
      layout:addWindow( uWindow , false, "uWindow" )

    end

    -- create a new empty atlas (a reference for maps), and tell it where to project the maps
    atlas = Atlas.new( layout.pWindow )

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

    -- initialize PNJ class list 
    -- later on, we might attach some images (snapshots) to these classes if we find them.
    -- try 2 locations to find class data. The loadClasses() function is assumed to merge all results if 2 files are present 
    local directory, scenarioDirectory = baseDirectory, fadingDirectory
    if __WINDOWS__ then directory, scenarioDirectory = baseDirectoryCp1252, fadingDirectoryCp1252 end

    RpgClasses = rpg.loadClasses{ 	directory .. sep .. "data" , 
			         	directory .. sep .. scenarioDirectory .. sep .. "data" } 

    if not RpgClasses or #RpgClasses == 0 then 
	    
    	layout.notificationWindow:addMessage("Warning: No data file found! No PC or NPC can be created") -- not blocking, but severe

    else

    	-- create PJ automatically (1 instance of each!)
    	-- later on, an image might be attached to them, if we find one
    	--rpg.createPJ()

    end

    -- load rest of data files (ie. images and maps)
    parseDirectory{ path = baseDirectory .. sep .. fadingDirectory }
    parseDirectory{ path = baseDirectory .. sep .. "pawns" , kind = "pawns" }
    parseDirectory{ path = baseDirectory .. sep .. "maps" , kind = "maps" }

    -- all classes are loaded with a snapshot
    -- add them to snapshotBar
    for i=1,#RpgClasses do
	if not RpgClasses[i].snapshot then 
		io.write("-- No snapshot for class " .. RpgClasses[i].class .. ", setting default one.\n"); 
		RpgClasses[i].snapshot = defaultPawnSnapshot
		templateArray[RpgClasses[i].class].snapshot = defaultPawnSnapshot 
	 end
	table.insert( layout.snapshotWindow.snapshots[3].s, RpgClasses[i].snapshot ) 
    end

    -- before returning, sort the class snapshot bar: PJ first, then PNJ, all in alphabetical order
    -- Comparison function
    function compare(x, y)
      if x[1].PJ and not y[1].PJ then return true end
      if not x[1].PJ and y[1].PJ then return false end
      return x[1].class < y[1].class 
    end

    -- Step 1: Merge in pairs
    for i,v in ipairs(RpgClasses) do
      RpgClasses[i] = {RpgClasses[i], layout.snapshotWindow.snapshots[3].s[i]}
    end

    -- Step 2: Sort
    table.sort(RpgClasses, compare)

    -- Step 3: Unmerge pairs
    for i, v in ipairs(RpgClasses) do
      RpgClasses[i] = v[1]
      layout.snapshotWindow.snapshots[3].s[i] = v[2]
    end

    io.write("loaded " .. #RpgClasses .. " classes.\n")

end

--
-- Main function
--
function love.load( args )

    -- load config file
    dofile( "dwconf.lua" )    

    -- GUI initializations...
    love.window.setTitle( "Dungeon World Tabletop" )
    love.keyboard.setKeyRepeat(true)
    yui.UI.registerEvents()

    -- some adjustments on different systems
    if __WINDOWS__ then
	keyZoomIn, keyZoomOut = ':', '!'
	keyPaste = 'lctrl'
    	sep = '\\'
    end

    -- maximize screen size and store these dimensions  
    love.window.setMode( 0  , 0  , { fullscreen=false, resizable=true, display=1} )
    love.window.maximize()
    layout.W, layout.H = love.window.getMode()

    -- adjust some windows accordingly
    layout.snapshotH = layout.H - layout.snapshotSize - layout.snapshotMargin
    layout.HC = layout.H - 4 * layout.intW - 2 * iconSize - layout.snapshotSize
    layout.WC = 1290 - 2 * layout.intW

    -- launch further init procedure if possible,
    -- or display setup window to require missing information
    if baseDirectory and baseDirectory ~= "" then
      init()
      initialized = true
    else
      dataWindow = setupWindow:new{ w=600, h=400, x=300,y=layout.H/2-100, init=false,layout=layout} 
      layout:addWindow( dataWindow , true, "dataWindow" )
      initialized = false
    end

    end

