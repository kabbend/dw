
local theme = require 'theme'

--
-- code related to the RPG itself (here, Fading Suns)
-- how do we roll dices, how to we inflict damages, etc.
--

-- array of PNJ templates (loaded from data file)
templateArray   = {}

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

-- for a given PNJ at index i, hit him !
function rpg.hitPNJ( i )
         if not i then return end
         if not PNJTable[ i ] then return end
	 PNJTable[ i ].hits = PNJTable[ i ].hits - 1
	 if (PNJTable[ i ].hits <= 0) then
		PNJTable[ i ].is_dead = true
	 	PNJTable[ i ].hits = 0
	 end 
 end

-- for a given PNJ at index i, return true if Attack or Armor button should be clickable
-- false otherwise
function rpg.isAttorArm( i )
         if not i then return false end
         if not PNJTable[ i ] then return false end
         -- when a PJ is selected, we do not roll for him but for it's enemy, provided
         -- there is one and only one
         if (PNJTable[ i ].PJ) then
                 local count = 0
                 local oneid = nil
                 for k,v in pairs(PNJTable[i].attackers) do
                         if v then oneid = k; count = count + 1 end
                 end
                 if (count ~= 1) or (not oneid) then return false end
         end
         -- if it's a PNJ, return true
         return true
 end

 -- Compute dices to roll when "roll attack" or "roll armor" is pressed
 -- Roll is made for the character with current focus, provided it is a PNJ and not a PJ
 -- If it is a PJ, the roll is made not for him, but for it's opponent, provided there is
 -- one and only one (otherwise, do nothing)
 -- Return nothing, but activate the corresponding draw flag and timer so it is used in
 -- draw()
 -- return the number of dices actually sent (may be zero)
 --
 -- DEPRECATED, will be deleted
 -- 
 function rpg.rollAttack( rollType )
	 return 0 
	 end

 --
 -- DEPRECATED, will be deleted
 -- 
function launchDices( kind, num )
         end

	 
--[[ d20 Roll object --]]
local Roll = {}
Roll.__index = Roll
function Roll:getRoll() return self.roll; end
function Roll:isSuccess() return self.success; end
function Roll:isPassDefense() return self.passDefense; end
function Roll:getVP() return self.VP; end
function Roll:getDamage() return self.damage; end
function Roll.new(goal,defense,basedmg) 
  
  local new = {}
  setmetatable(new,Roll)
  
  new.goal = goal
  new.defense = defense
  new.basedmg = basedmg
  new.VP        = 0
  new.damage    = 0
  new.success   = false
  new.passDefense = false

  new.roll = math.random(1,20)
  
  -- 20 always a failure (or fumble)
  if (new.roll == 20) then 
    new.success = false;
    return new;
  end
  
  -- must roll below the goal, but 1 is always a sucess so we let it pass the test
  if (new.roll > goal and new.roll ~= 1) then 
    new.success = false;
    return new;
  end

  -- base success (we determine PV without taking into account the defense of the target)
  new.VP = math.ceil((new.roll-1)/2)

  -- is it a critical roll?
  if (new.roll == goal) then 
    local newRoll = Roll.new( goal, defense, basedmg )
    if newRoll:isSuccess() then new.VP = new.VP + newRoll:getVP() end
  end

  local success = new.VP

  if defense then
    -- we know the target's defense (not always the case)
    -- reduce PV accordingly
    success = success - defense

    -- sometimes does not pass the defense...
    if success < 0 then 
      new.success = true
      new.passDefense = false 
    else
      new.success = true
      new.passDefense = true
      new.damage = success + basedmg
    end
    
  else -- don't know who is the target...

      new.success = true
      new.passDefense = false -- we don't know
    
  end
  
  return new
  
end
  
function Roll:getVPText()
  if self.roll == 20 then return "(F.)" end
  if not self.success then return "( X )" end
  return "(" .. self.VP .. " VP)" 
  end

function Roll:getDamageText()
  if not self.success then return "( X )" end
  if self.defense then
    if not self.passDefense then return "( X )" end
    return "(".. self.damage .. " D)" 
  else
    return "( ? )"
  end
  end

function Roll:changeDefense( newDefense )
  
  if not self.success then return end -- was not a success anyway, do nothing...
  
  self.defense = newDefense
  
  if not newDefense then
    -- VP does not change
    self.passDefense = false
    self.damage = 0
  else
    local success = self.VP
    success = success - newDefense
    if success < 0 then
      self.passDefense = false
      self.damage = 0
    else
      self.passDefense = true
      self.damage = self.basedmg + success
    end
    
  end
end

-- return an iterator which generates new unique ID, 
-- from "A", "B" ... thru "Z", then "AA", "AB" etc.
local function UIDiterator() 
  local UID = ""
  local incrementAlphaID = function ()
    if UID == "" then UID = "A" return UID end
    local head=UID:sub( 1, UID:len() - 1)
    local tail=UID:byte( UID:len() )
    local id
    if (tail == 90) then 
	local u = UIDiterator()
	id = u(head) .. "A" 
    else 
	id = head .. string.char(tail+1) 
    end
    UID = id
    return UID
    end
  return incrementAlphaID 
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
  aNewPNJ.image	  	  = template.image or ''	-- image (and some other information) for the character 
  aNewPNJ.snapshot	  = template.snapshot		-- image (and some other information) for the character 
  aNewPNJ.sizefactor	  = template.size or 1.0

  aNewPNJ.ip	  	  = nil				-- for PJ only: ip, if the player is using udp remote communication 
  aNewPNJ.port	  	  = nil				-- for PJ only: port, if the player is using udp remote communication 

  -- GRAPHICAL INTERFACE (focus, timers...)
  aNewPNJ.focus	  	  = false			-- has the focus currently ?

  aNewPNJ.lasthit	  = 0			        -- time when last attacked or lost hit points. This starts a timer of 3 seconds during which
							-- the character cannot loose DEFense value again
  aNewPNJ.acceptDefLoss   = true			-- linked to the timer above: In general a character should accept to loose DEFense
							-- at anytime (acceptDefLoss = true), except that each time DEF is lost, we must wait 3 seconds
							-- before another DEF point can be lost again (and during that time, acceptDefLoss = false) 

  aNewPNJ.initTimerLaunched = false
  aNewPNJ.lastinit	  = 0				-- time when initiative last changed. This starts a timer before the PNJ list is sorted and 
							-- printed to screen again

  -- BASE CHARACTERISTICS
  aNewPNJ.class	      	= template.class or ""
  aNewPNJ.intelligence 	= template.intelligence or 3
  aNewPNJ.perception   	= template.perception or 3
  aNewPNJ.endurance    	= template.endurance or 5    
  aNewPNJ.force        	= template.force or 5        
  aNewPNJ.dex          	= template.dex or 5     	-- Characteristic DEXTERITY

  aNewPNJ.fight        	= template.fight or 5        
  	-- 'fight' is a generic skill that represents all melee/missile capabilities at the same time
  	-- here we avoid managing separate and detailed skills depending on each weapon...

  aNewPNJ.weapon    	= template.weapon or ""
  aNewPNJ.defense      	= template.defense or 1 
  aNewPNJ.dmg          	= template.dmg or 2		-- default damage is 2 (handfight)
  aNewPNJ.armor        	= template.armor or 1      	-- number of dices (eg 1 means 1D armor)

  -- OPPONENTS
  aNewPNJ.target   	= nil 				-- ID of its current target, or nil if not attacking anyone
  aNewPNJ.attackers    	= {}				-- list of IDs of all opponents attacking him 

  -- DERIVED CHARACTERISTICS
  aNewPNJ.initiative    	= aNewPNJ.intelligence + aNewPNJ.dex -- Base initiative. for PNJ, a d6 is added during combat 
  aNewPNJ.final_initiative 	= 0  -- for the moment, will be fixed later

  -- We apply some basic maluses for PNJ (not for PJ for whom we take literal values)
  if not aNewPNJ.PJ then
    -- damage bonus (we apply it without consideration of melee or missile weapon)
    if (aNewPNJ.force >= 9) then aNewPNJ.dmg = aNewPNJ.dmg + 2 elseif (aNewPNJ.force >= 6) then aNewPNJ.dmg = aNewPNJ.dmg + 1 end

    -- maluses due to armor
    -- we apply very simple rules, as follows
    -- Armor >= 2, malus -1 to INIT
    -- Armor >= 3, malus -1 to INIT and DEX
    -- Armor >= 4, malus -3 to INIT, and -1 to DEX and FOR 
    if (aNewPNJ.armor >= 4) then aNewPNJ.initiative = aNewPNJ.initiative -3; aNewPNJ.dex = aNewPNJ.dex - 1; aNewPNJ.force = aNewPNJ.force -1
    elseif (aNewPNJ.armor >= 3) then  aNewPNJ.initiative = aNewPNJ.initiative - 1; aNewPNJ.dex = aNewPNJ.dex - 1 
    elseif (aNewPNJ.armor >= 2) then aNewPNJ.initiative = aNewPNJ.initiative -1;  end
  end

  aNewPNJ.hits        	= aNewPNJ.endurance + aNewPNJ.force + 5
  aNewPNJ.goal         	= aNewPNJ.dex + aNewPNJ.fight
  aNewPNJ.malus	        = 0
	-- generic malus due to low hits (-2 to -10)

  aNewPNJ.defmalus       = 0
	-- malus to defense for the current round, due to attacks
	-- this malus is reinitialized each round

  aNewPNJ.stance         = "neutral" -- by default
  aNewPNJ.defstancemalus = 0
	-- malus to defense due to stance (-2 to +2) 

  aNewPNJ.goalstancebonus= 0
	-- bonus (or malus) to goal due to stance (-3 to +3) 

  aNewPNJ.final_defense = aNewPNJ.defense
  aNewPNJ.final_goal    = aNewPNJ.goal

  -- roll a D20
  aNewPNJ.roll	= Roll.new(
    aNewPNJ.final_goal,   -- current goal
    nil, 		  -- no target yet, so no defense to pass
    aNewPNJ.dmg 	  -- weapon's damage
    )			  -- dice roll for this round

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


-- For an opponent (at index k) attacking a PJ (at index i), return
-- an "average touch" value ( a number of hits ) which is an average
-- number of damage points weighted with an average probability to hit
-- in this round
function rpg.averageTouch( i, k )
  if PNJTable[k].PJ then return 0 end -- we compute only for PNJ
  local dicemin = PNJTable[i].final_defense*2 - 1
  if dicemin < 0 then dicemin = 0 end
  local dicemax = PNJTable[k].final_goal
  local diceinterval = dicemax - dicemin
  if diceinterval < 0 then diceinterval = 0 end
  local chanceToTouch = diceinterval / 20 
  local damage = PNJTable[k].dmg + (diceinterval / 2)
  return chanceToTouch * (damage - PNJTable[i].armor) * (2/3)
  end

-- the dangerosity, for a PJ at index i, is an average calculation
-- based on its current hits and values of its opponents, which
-- represents an estimated (and averaged) number of rounds before dying.
-- Return the dangerosity value (an integer), or -1 if cannot be computed 
-- (eg. no opponent )
function rpg.computeDangerosity( i )
  local potentialTouch = 0
  for k,v in pairs(PNJTable[i].attackers) do
    if v then
      local index = findPNJ( k )
      if index then potentialTouch = potentialTouch + averageTouch( i , index ) end
    end
  end
  if potentialTouch ~= 0 then return math.ceil( PNJTable[i].hits / potentialTouch ) else return -1 end
  end

-- compute dangerosity for the whole group
function rpg.computeGlobalDangerosity()
  local potentialTouch = 0
  local hits = 0
  for i=1,#PNJTable do
   if PNJTable[i].PJ then
    hits = hits + PNJTable[i].hits
    for k,v in pairs(PNJTable[i].attackers) do
     if v then
      local index = findPNJ( k )
      if index then potentialTouch = potentialTouch + averageTouch( i , index ) end
     end
    end
   end
  end
  if potentialTouch ~= 0 then return math.ceil( hits / potentialTouch ) else return -1 end
  end

-- add n to the current defense malus of the i-th character (n can be positive or negative)
-- set to m the defense stance malus of the i-th character. If m is nil, does not alter the current stance malus
-- This will result in 2 effects:
-- a) alter the current total DEFENSE of the character
-- b) if another character is targeting this one, then modify damage roll result accordingly
function rpg.changeDefense( i, n, m )

  -- lower defense
  PNJTable[i].defmalus = PNJTable[i].defmalus + n
  if m then PNJTable[i].defstancemalus = m end
  PNJTable[i].final_defense = PNJTable[i].defense + PNJTable[i].defmalus + PNJTable[i].defstancemalus;

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

-- Check if all PNJs have played (the "done" checkbox is checked for all, 
-- including dead PNJs as well)
-- If so, calls the nextRound() function.
-- Return true or false depending on what was done 
function rpg.checkForNextRound()
  	local goNextRound = true -- a priori, might change below
  	for i=1,#PNJTable do if not PNJTable[i].done then goNextRound = false end end
  	return goNextRound
	end

-- create one instance of each PJ
function rpg.createPJ()

    for classname,t in pairs(templateArray) do
      if t.PJ then rpg.generateNewPNJ(classname) end
    end

    end

return rpg

