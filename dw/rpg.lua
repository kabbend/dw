
local theme 	= require 'theme'
local partial 	= require 'partial'
local partialS 	= require 'partialS'
local fail 	= require 'fail'
local danger 	= require 'danger'
local names 	= require 'names'
local magic 	= require 'magic'
local potions 	= require 'potions'
local trait 	= require 'trait'
--
-- code related to the RPG itself (here, Fading Suns)
-- how do we roll dices, how to we inflict damages, etc.
--

-- array of PNJ templates (loaded from data file)
templateArray   = {}

-- max number of actions per turn
PJMaxAction = 2

local rpg = {}

-- load PNJ templates from data file, return an array of classes
-- argument is a table (list) of paths to try
function rpg.loadClasses( paths )

   local array = {}
   Class = function( t )
  		if not t.class then error("need a class attribute (string value) for each class entry") end
		local already_exist = false
		if templateArray[t.class] then already_exist = true end
  		templateArray[t.class] = t
  		if not already_exist then 
			table.insert( array, t )
  		end
		end

   -- try all files
   for x=1,#paths do 
	local f = loadfile( paths[x] )
	if f then f() end 
   end

   return array
   end

-- Hit the PNJ at index i
-- return a boolean true if dead... 
function rpg.hitPNJ( i )
         if not i then return false end
         if not PNJTable[ i ] then return false end
	 PNJTable[ i ].hits = PNJTable[ i ].hits - 1
	 if (PNJTable[ i ].hits <= 0) then
		PNJTable[ i ].is_dead = true
	 	PNJTable[ i ].hits = 0
		return true
	 end 
	 return false
 end

-- return an iterator which generates new unique ID, 
-- from "A", "B" ... thru "Z", then "AA", "AB" etc.
local function UIDiterator() 
  UID = ""
  incrementID = function (id)
    if id == "" then return "A" end
    local head=string.sub(id, 1, string.len(id) - 1)
    local tail=string.byte(id, string.len(id) )
    if (tail == 90) then 
	return incrementID(head)  .. "A" 
    else 
	return head .. string.char(tail+1) 
    end
    end
  incrementAlpha = function()
    UID = incrementID(UID)
    return UID
    end
  return incrementAlpha 
  end

-- some initialization stuff
local generateUID = UIDiterator()

-- return a new PNJ object, based on a given template. 
-- Give him a new unique ID 
local function PNJConstructor( template ) 

  aNewPNJ = {}

  aNewPNJ.id 		  = generateUID() 		-- unique id
  aNewPNJ.PJ 		  = template.PJ or false	-- is it a PJ or PNJ ?
  aNewPNJ.done		  = false 			-- has played this round ?
  aNewPNJ.is_dead         = false  			-- so far 
  aNewPNJ.actions         = 0  				-- number of actions the PJ has done in that round 
  aNewPNJ.image	  	  = template.image or ''	-- image (and some other information) for the character 
  aNewPNJ.popup	  	  = template.popup or ''	-- popup image (and some other information) for the character 
  aNewPNJ.snapshot	  = template.snapshot		-- image (and some other information) for the character 
  aNewPNJ.snapshotPopup	  = template.snapshotPopup	-- image (and some other information) for the character 
  aNewPNJ.sizefactor	  = template.size or 1.0	-- snapshot size factor
  aNewPNJ.major	  	  = template.major		-- is it a major PNJ ? 

  aNewPNJ.ip	  	  = nil				-- for PJ only: ip, if the player is using udp remote communication 
  aNewPNJ.port	  	  = nil				-- for PJ only: port, if the player is using udp remote communication 

  -- GRAPHICAL INTERFACE (focus, timers...)
  aNewPNJ.focus	  	  = false			-- has the focus currently ?

  aNewPNJ.initTimerLaunched = false
  aNewPNJ.lastinit	  = 0				-- time when initiative last changed. This starts a timer before the PNJ list is sorted and 
							-- printed to screen again

  -- BASE CHARACTERISTICS
  aNewPNJ.class	      	= template.class or ""
  aNewPNJ.endurance    	= template.endurance or 5    
  aNewPNJ.dmg          	= template.dmg or 2		-- default damage is 2 (handfight)
  aNewPNJ.armor        	= template.armor or 1      	-- number of dices (eg 1 means 1D armor)

  -- OPPONENTS
  aNewPNJ.target   	= nil 				-- ID of its current target, or nil if not attacking anyone
  aNewPNJ.attackers    	= {}				-- list of IDs of all opponents attacking him 

  aNewPNJ.hits        	= aNewPNJ.endurance 

  if template.trait then
	aNewPNJ.trait = trait [ math.random( #trait ) ]
  end

  return aNewPNJ
  
  end 

-- set the target of i to j (i attacks j)
function rpg.updateTargetByArrow( i, j )

  -- check that the characters have not been removed from the list at some point in time...
  if (not PNJTable[i]) or (not PNJTable[j]) then return end

  -- set new target value
  if PNJTable[i].target == PNJTable[j].id then return end -- no change in target, do nothing
  
  -- set new target
  PNJTable[i].target = PNJTable[j].id
  
  -- remove i as attacker of anybody else
  PNJTable[j].attackers[ PNJTable[i].id ] = true
  for k=1,#PNJTable do
    if k ~= j then PNJTable[k].attackers[ PNJTable[i].id ] = false end
  end
  
end


-- create and store a new PNJ in PNJTable{}, based on a given class,
-- return the id of the new PNJ generated
-- The newly created PNJ is stored at the end of the PNJTable{} for
-- the moment
function rpg.generateNewPNJ(current_class)

  -- generate a new one, at current index, with new ID
  PNJTable[#PNJTable+1] = PNJConstructor( templateArray[current_class] )

  -- set a default image if needed
  local pnj = PNJTable[#PNJTable]
  if not pnj.snapshot then pnj.snapshot = defaultPawnSnapshot end
  io.write("generating a new character for class " .. current_class .. " with ID " .. pnj.id .. "\n")
  return pnj.id 
end


-- remove dead PNJs from the PNJTable{}, but keeps all other PNJs
-- in the same order. 
-- return true if a dead PNJ was actually removed, false if none was found.
-- Does not re-print the PNJ list on the screen. 
function rpg.removeDeadPNJ()

  local has_removed =  false
  local initialSize = #PNJTable
  local new = {}
  for i=1,#PNJTable do if not PNJTable[i].is_dead then table.insert( new, PNJTable[i] ) end end
  PNJTable = new
  --thereIsDead = false
  return initialSize ~= #PNJTable 
end

function rpg.nextRound()
  	for i=1,#PNJTable do if PNJTable[i].PJ then PNJTable[i].actions = 0 end end
	end

-- create one instance of each PJ
function rpg.createPJ()

    for classname,t in pairs(templateArray) do
      if t.PJ then rpg.generateNewPNJ(classname) end
    end

    end

function rpg.increaseAction( i )
    if (not PNJTable[i]) or (not PNJTable[i].PJ) then return end
    PNJTable[i].actions = PNJTable[i].actions + 1
    if PNJTable[i].actions > PJMaxAction then PNJTable[i].actions = 0 end
    end

function rpg.getPartialT()
    return partial[ math.random(#partial) ]
    end

function rpg.getPartialS()
    return partialS[ math.random(#partialS) ]
    end

function rpg.getFail()
    return fail[ math.random(#fail) ]
    end

function rpg.getHook()
    return '-- to be implemented -- ' 
    end

function rpg.getMagic()
    return magic[ math.random(#magic) ]
    end

function rpg.getPotion()
    return potions[ math.random(#potions) ]
    end

function rpg.getDanger()
    return danger[ math.random(#danger) ]
    end

function rpg.getTrait()
    return trait[ math.random(#trait) ]
    end

function rpg.getName()
    local t = "Humain: " .. names['Homme'][ math.random(#names['Homme']) ] .. " / " .. names['Femme'][ math.random(#names['Femme']) ] .. "\n"  	
    t = t .. "Nain: " .. names['Nain'][ math.random(#names['Nain']) ] .. " / " .. names['Naine'][ math.random(#names['Naine']) ] .. "\n" 	
    t = t .. "Orc: " .. names['Orc'][ math.random(#names['Orc']) ] .. " / " .. names['Clan'][ math.random(#names['Clan']) ] .. "\n" 	
    t = t .. "Ville: " .. names['Ville'][ math.random(#names['Ville']) ] .. " / " .. names['Taverne'][ math.random(#names['Taverne']) ]  	
    return t
    end

return rpg

