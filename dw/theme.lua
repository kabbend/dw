
local theme = {}

theme.iconSize = 32 
theme.size= 19 		-- base font size
theme.color = { masked = {220,240,210}, black = {0,0,0}, red = {250,80,80}, darkblue = {66,66,238}, purple = {127,0,255}, selected = {0,128,128}, 
  orange = {255,165,0},   darkgreen = {0,102,0},   white = {255,255,255} , green = {0,240,0} , darkgrey = {96,96,96} , grey = { 211, 211, 211} } 
theme.fontTitle 	= love.graphics.newFont("yui/yaoui/fonts/georgia.ttf",20)
theme.fontDice 		= love.graphics.newFont("yui/yaoui/fonts/georgia.ttf",90)
theme.fontRound 	= love.graphics.newFont("yui/yaoui/fonts/georgia.ttf",12)
theme.fontSearch 	= love.graphics.newFont("yui/yaoui/fonts/georgia.ttf",16)
theme.backgroundImage 	= love.graphics.newImage( "images/background.png" )
theme.actionImage 	= love.graphics.newImage( "images/action.jpg" )
theme.storyImage 	= love.graphics.newImage( "images/histoire.jpg" )
theme.iconClose 	= love.graphics.newImage( "icons/close32x32.png" )
theme.iconResize 	= love.graphics.newImage( "icons/minimize32x32.png" )
theme.iconOnTopInactive	= love.graphics.newImage( "icons/up-arrow.32x32.png" )
theme.iconOnTopActive 	= love.graphics.newImage( "icons/up-arrow-red.32x32.png" )
theme.iconFullSize 	= love.graphics.newImage( "icons/fullsize32x32.png" )
theme.iconReduce 	= love.graphics.newImage( "icons/reduce32x32.png" )
theme.iconExpand 	= love.graphics.newImage( "icons/enlarge32x32.png" )
theme.iconWWWInactive 	= love.graphics.newImage( "icons/wwwblack16x16.png" )
theme.iconWWWActive	= love.graphics.newImage( "icons/wwwred16x16.png" )
theme.iconPencil	= love.graphics.newImage( "icons/pencil.png" )
theme.iconNew		= love.graphics.newImage( "icons/new.png" )
theme.iconCentre	= love.graphics.newImage( "icons/centre.png" )
theme.iconStop		= love.graphics.newImage( "icons/stop.png" )
theme.iconLink		= love.graphics.newImage( "icons/link.png" )
theme.iconWipe		= love.graphics.newImage( "icons/wipe32x32.png" )
theme.iconKill		= love.graphics.newImage( "icons/kill32x32.png" )
theme.iconVisible	= love.graphics.newImage( "icons/eye32x32.png" )
theme.iconInvisible	= love.graphics.newImage( "icons/eyeblocked32x32.png" )
theme.iconSticky	= love.graphics.newImage( "icons/scotch32x32.png" )
theme.iconUnSticky	= love.graphics.newImage( "icons/scotchblack32x32.png" )

return theme

