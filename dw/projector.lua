
local Window 		= require 'window'	-- Window class & system
local theme		= require 'theme'	-- global theme

-- we write only in debug mode
local oldiowrite = io.write
function io.write( data ) if debug then oldiowrite( data ) end end

-- projectorWindow class
-- a projectorWindow is a window which displays images. it is not zoomable
local projectorWindow = Window:new{ class = "projector" , title = "PROJECTOR" , buttons = { 'always', 'close' } }

function projectorWindow:new( t ) -- create from w, h, x, y
  local new = t or {}
  setmetatable( new , self )
  self.__index = self
  self.currentImage = nil
  self.o = nil
  return new
end

function myStencilFunctionProjector()
        love.graphics.rectangle("fill",pzx,pzy,pw,ph)
        for k,v in pairs(pmask) do
                local _,_,shape = string.find( v , "(%a+)" )
                if shape == "RECT" then
                        local _,_,_,x,y,wm,hm = string.find( v , "(%a+) (%-?%d+) (%-?%d+) (%d+) (%d+)" )
                        x = pzx + x*pmag
                        y = pzy + y*pmag
                        love.graphics.rectangle( "fill", x, y, wm*pmag, hm*pmag)
                elseif shape == "CIRC" then
                        local _,_,_,x,y,r = string.find( v , "(%a+) (%-?%d+) (%-?%d+) (%d+%.?%d+)" )
                        x = pzx + x*pmag
                        y = pzy + y*pmag
                        love.graphics.circle( "fill", x, y, r*pmag )
                end
        end
        end

function projectorWindow:draw()

  self:drawBack()

  local W,H=self.layout.W, self.layout.H
  pzx,pzy = -( self.x - W / 2), -( self.y - H / 2)
  if self.currentImage then 
    pw, ph = self.currentImage:getDimensions()
    -- compute magnifying factor f to fit to screen, with max = 2
    local xfactor = (self.layout.W1) / pw
    local yfactor = (self.layout.H1) / ph
    local f = math.min( xfactor, yfactor )
    if f > 2 then f = 2 end
    pw , ph = f * pw , f * ph
    pmag = f

    if self.o.class == "map" and self.o.map.mask and #self.o.map.mask > 0 then

	io.write("proj: display map with mask")

		pmask = self.o.map.mask
                love.graphics.setColor(0,0,0)
                love.graphics.stencil( myStencilFunctionProjector, "increment" )
                love.graphics.setStencilTest("equal", 1)

        else

                love.graphics.setColor(255,255,255)

        end

    love.graphics.draw( self.currentImage , pzx +  (self.layout.W1 - pw) / 2, pzy + ( self.layout.H1 - ph ) / 2, 0 , f, f )

    if self.o.class == "map" and self.o.map.mask and #self.o.map.mask > 0 then

                love.graphics.setStencilTest("gequal", 2)
                love.graphics.setColor(255,255,255)
                love.graphics.draw( self.currentImage, pzx, pzy, 0, f, f )
    end

  end
  -- print bar
  self:drawBar()
  end

function projectorWindow:click(x,y)
  	Window.click(self,x,y)
	end

function projectorWindow:drop(o)

 	local s = o.snapshot

	-- replace the image locally
	self.currentImage = s.im	
	self.o = o.object 

	-- and send it remotely
	if  o.object.class == "pnjtable" or o.object.class == "image" or o.object.class == "pnj" or  o.object.class == "pawn" then
		-- image coming from the combat window (pnjtable) or from the snapshot bar
                -- remove the 'visible' flag from maps (eventually)
                atlas:removeVisible()
                tcpsend(projector,"ERAS")       -- remove all pawns (if any) 
                -- send the filename over the socket
                if s.is_local then
                        tcpsendBinary{ file = s.file }
                        tcpsend(projector,"BEOF")
                elseif fullBinary then
                        tcpsendBinary{ filename = s.filename }
                        tcpsend(projector,"BEOF")
                else
                        tcpsend( projector, "OPEN " .. s.baseFilename)
                end
                tcpsend( projector, "DISP")     -- display immediately

	elseif o.object.class == "map" then
		-- map coming from the snapshot bar. This is equivalent to open it and make it visible
		-- open the window map, put focus
                s.layout:setDisplay( s , true )
                s.layout:setFocus( s )
		-- make it visible
		atlas:toggleVisible( s )
                if not atlas:isVisible( s ) then s.sticky = false end
	end

	end

return projectorWindow

