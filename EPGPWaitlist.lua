-- Author:		Lozon

-- Future versions road map:
--		v1.0.5	- Listen for commands in guild chat.
--				- Listen for commands in officer chat.
--				- Allow players to "list" the waitlist and respond to the appropriate channel.
--		v1.1 - Enable/disable addon upong entering/leaving raid.
--		v1.2 - Export waitlist to saved variables.
--		v1.3 - Report AFK periods for selected player.
--		v2.0 - GUI

-- Create addon as Ace3, AceConsole and AceEvent
EPGPWaitlist = LibStub("AceAddon-3.0"):NewAddon("EPGPWaitlist", "AceConsole-3.0", "AceEvent-3.0")


--------------------------
-- ACE3 ADDON FUNCTIONS --
--------------------------

function EPGPWaitlist:OnInitialize()
	-- Register the slash command
	EPGPWaitlist:RegisterChatCommand("wlp", "SlashCommandHandler")
	
	-- Register event handlers
	EPGPWaitlist:RegisterEvent("CHAT_MSG_WHISPER", "WhisperEventHandler")
	EPGPWaitlist:RegisterEvent("GUILD_ROSTER_UPDATE", "GuildRosterUpdateEventHandler")
	EPGPWaitlist:RegisterEvent("RAID_ROSTER_UPDATE", "RaidRosterUpdateEventHandler")
end

function EPGPWaitlist:OnEnable()
	-- Register callback with EPGP for Mass EP Awards
	EPGP.RegisterCallback(EPGPWaitlist, "MassEPAward")
	
	-- Since the addon was just enabled, update the Guild and raid roster tables
	EPGPWaitlist:GuildRosterUpdateEventHandler()
	EPGPWaitlist:RaidRosterUpdateEventHandler() -- Depends on guildRoster being current 
	
	EPGPWaitlist:Print("EPGPWaitlist loaded!")
end

function EPGPWaitlist:OnDisable()
end


---------------------------
-- SLASH COMMAND HANDLER --
---------------------------

-- Name:		SlashCommandHandler
-- Desc:		Basic slash command handler.
function EPGPWaitlist:SlashCommandHandler(input)
	input = input:lower() -- make it all lowercase
	
	-- Get all the arguments
	local cmd, args = input:match("([^ ]+) ?(.*)") 
	
	if cmd == "add" then
		 EPGPWaitlist:AddPlayer(args)
	elseif cmd == "remove" then
		EPGPWaitlist:RemovePlayer(args)
	elseif cmd == "removeall" then
		EPGPWaitlist.players = {} -- Wipe the players table
		EPGPWaitlist:Print("Waitlist has been wiped.")
	elseif cmd == "list" then
		EPGPWaitlist:List()
	end
end


-------------
-- MEMBERS --
-------------

-- Players on the waitlist - stores the Players object. This will always be the player's main.
EPGPWaitlist["players"] = {}

-- All raid members - value is boolean. This will always be the player's main.
EPGPWaitlist["raidRoster"] = {}

-- All guild members' ranks and notes who are online.
EPGPWaitlist["guildRoster"] = {} -- Contains tables of note, rank and online status.


-------------
-- METHODS --
-------------

-- Name:		AddPlayer
-- Desc:		Add a player main to the waitlist if they are in the guild and not in the raid.
--					If the player is already on the waitlist, don't re-add them.
--					If the player is an Alt, add their main character. 
-- Parameters:	args (name of player)
function EPGPWaitlist:AddPlayer(name)
	name = name:lower()
	
	-- Check this player is in the guild
	if not EPGPWaitlist:IsGuildMember(name) then
		SendChatMessage("This player is not in the guild. Your alts and main must be in the guild to use the waitlist.", "WHISPER", nil, name);
		EPGPWaitlist:Print(EPGPWaitlist:capitalize(name) .." requested to be on the waitlist, but is not in the guild.")
		return false
	end
	
	local onlineStatus = EPGPWaitlist.guildRoster[name][3] -- The online status from last guild roster update
		
	-- Check if the player name is an alt, then get their main's name.
	if EPGPWaitlist:IsAlt(name) then
		name = EPGPWaitlist:GetAltsMain(name)
		-- Check that the main is in the guild
		if not EPGPWaitlist:IsGuildMember(name) then
			SendChatMessage(name .. " is not in the guild. Check that the spelling is correct in your public note.", "WHISPER", nil, name);
			EPGPWaitlist:Print(EPGPWaitlist:capitalize(name) .." requested to be on the waitlist, but is not in the guild.")
			return false
		end 
	end
	
	-- Check if player is already on waitlist
	if EPGPWaitlist:IsWaitlisted(name) then
		SendChatMessage(EPGPWaitlist:capitalize(name) .. " is already on the waitlist.", "WHISPER", nil, name);
		EPGPWaitlist:Print(EPGPWaitlist:capitalize(name) .." is already on the waitlist.")
		return false
	-- Check if this player is in the raid
	elseif EPGPWaitlist.raidRoster[name] then
		SendChatMessage("You are already on the waitlist.", "WHISPER", nil, name);
		EPGPWaitlist:Print(EPGPWaitlist:capitalize(name) .." is already on the waitlist.")
		return false
	end
	
	-- Add player
	EPGPWaitlist.players[name] = EPGPWaitlist.Player(name, onlineStatus) -- Creates a new player object
	SendChatMessage("You have been added to the waitlist.", "WHISPER", nil, name);
	EPGPWaitlist:Print(EPGPWaitlist:capitalize(name) .. " has been added to the waitlist.")
end

-- Desc:		Remove a player from the waitlist if they are on it.
--					If they aren't on waitlist, reply with appropriate message.
--					If player is an alt, then handle the removal as such.
-- Parameters:	args (name of player)
function EPGPWaitlist:RemovePlayer(args)
	local name = args:lower()
	local main = name -- Player to remove from waitlist
	local msg = "" -- Message to be whispered/printed
	
	-- Check if player is an alt
	if EPGPWaitlist:IsAlt(name) then
		-- Get their main's name
		main = EPGPWaitlist:GetAltsMain(name)
	-- Check if they are on the waitlist
	elseif EPGPWaitlist:IsWaitlisted(main) == nil then
		msg = EPGPWaitlist:capitalize(main) .." is not on the waitlist."
	-- Remove player
	else
		EPGPWaitlist:RemoveFromWaitlist(main)
		msg = EPGPWaitlist:capitalize(main) .. " has been removed from the waitlist."
	end	
	
	-- Send messages
	SendChatMessage(msg, "WHISPER", nil, name)
	EPGPWaitlist:Print(msg)
end

-- Name:		IsAlt
-- Desc:		Checks if the player is an alt
function EPGPWaitlist:IsAlt(name)
	-- Make sure the player is in the guild first
	if EPGPWaitlist.guildRoster[name][2] == "Alt" then
		return true
	end
	
	return false
end

-- Name:		IsGuildMember
-- Desc:		Checks if the player is a guild member using the guildRoster table
function EPGPWaitlist:IsGuildMember(name)
	if EPGPWaitlist.guildRoster[name] ~= nil then
		return true
	end
	
	return false
end

-- Name:		IsWaitlisted
-- Desc:		Checks if the player is on the waitlist
function EPGPWaitlist:IsWaitlisted(name)
	if EPGPWaitlist.players[name] ~= nil then
		return true
	end
	
	return false
end

-- Name:		RemoveFromWaitlist
-- Desc:		Removes the player from the waitlist
function EPGPWaitlist:RemoveFromWaitlist(name)
	EPGPWaitlist.players[name] = nil
end

-- Name:		GetAltsMain
-- Desc:		Will return the name of an alts main as all lower case
-- Asserts:		When name parameter is not in the guild.
--				When main (note) is not in the guild
--				When the name parameter is not an alt.
function EPGPWaitlist:GetAltsMain(altName)
	-- Checks if alt is in the guild
	assert(EPGPWaitlist.guildRoster[altName], EPGPWaitlist.capitalize(altName) .. " is not in the guild.")
	
	-- Checks if the player is an alt
	assert(EPGPWaitlist:IsAlt(altName), EPGPWaitlist.capitalize(note) .. " is not an alt.")
	
	-- Get the main player's name
	local note = EPGPWaitlist.guildRoster[altName][2]:lower()
	
	-- Checks if the main player is in the guild
	assert(EPGPWaitlist.guildRoster[note], EPGPWaitlist.capitalize(note) .. " is not in the guild.")
	
	return note
end

-- Name:		List()
-- Desc:		Simple output of waitlisted players.
function EPGPWaitlist:List()
	EPGPWaitlist:GuildRosterUpdateEventHandler() -- Update the guild roster before awarding so offline durations are current
	
	for idx,player in pairs(EPGPWaitlist.players) do
		local msg = ""
		
		msg = msg .. player.name .. "'s status is: "
		
		if player.online then
			msg = msg .. "Online" 
		else
			local timeSeconds = player.lastUpdated - player.lastOnline
			local timeHours = math.floor(timeSeconds / 60 / 60)
			local timeMinutes = math.floor(timeSeconds / 60) - timeHours * 60
			timeSeconds = timeSeconds % 60
			
			msg = msg .. "Offline" .. " ("
			
			if timeHours > 0 then
				msg = msg .. timeHours .. "h"
			end
			
			if timeMinutes > 0 then
				msg = msg .. timeMinutes .. "m"
			end
			
			if timeSeconds > 0 then
				msg = msg .. timeSeconds .. "s"
			end
			msg = msg .. ")"
		end
		
		if player.alt ~= nil then
			msg = msg .. " (" .. player.alt ..") "
		end
		
		EPGPWaitlist:Print(msg)
	end
end

-- Desc:		Capitalizes the first letter of the string parameter
function EPGPWaitlist:capitalize(word)
	return word:sub(1, 1):upper() .. word:sub(2):lower()
end

-- Desc:		Rounds supplied number to the supplied decimal places
function EPGPWaitlist:round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Name:		MassEPAward()
-- Desc:		Function registered with EPGP MassEPAward - will give every
--					player on waitlist the same awrd.
-- Note:		This function could be turned into a function hook and append all
--					the waitlist players to the names parameter, but I prefer to
--					keep the announce messages seperate.
function EPGPWaitlist:MassEPAward(event_name, names, reason, amount, ...)
	reason = "Waitlist - " .. reason
	local awarded = false -- Only announce if we actually award a player
	EPGPWaitlist:GuildRosterUpdateEventHandler() -- Update the guild roster before awarding so offline durations are current
		
	-- Generate announce message
	local msg = "EPGP: "
	if amount > -1 then
		msg = msg .. "+"
	else
		msg = msg .. "-"
	end
	msg = msg .. amount .. " EP (" .. reason .. ") to "
	
	-- Award EP to every member on the waitlist.
	-- WARNING: EPGP uses the LibGuildStorage to handle officer notes. This will prevent the
	--	IncEPBy from executing when the state of the GuildStorage object is not "CURRENT". I
	--	believe this signify's the officer notes as being "fresh". When EPGP rewards a Mass
	--	EP Award, it ignores the state of GuildStorage because "we know what we are doing"?
	--	Since we are tagging this with the Mass EP Award, it should be fine to do the same.
	for idx,player in pairs(EPGPWaitlist.players) do
		if player.online or (player.lastUpdated - player.lastOnline < 300) then
			EPGP:IncEPBy(EPGPWaitlist:capitalize(idx), reason, amount, true) -- Increment as a "mass" ep award
			msg = msg .. " " .. EPGPWaitlist:capitalize(idx) .. "," -- append the player name
			awarded = true
		else
			EPGPWaitlist:Print(idx .. " is offline and lost the EP Award.")
		end
	end
	
	-- Announce to the guild, removing the final comma
	if awarded then
		SendChatMessage(msg:sub(1,-2), "GUILD")
	end
end

----------------------
-- OBJECT FACTORIES --
----------------------

-- Player object (factory function)
do
	-- Set offline time
	local function updateOfflineTime(self, time)
		time = EPGPWaitlist:round(time)
		-- Only set offline if lastUpdated time is less than parameter time
			-- This prevents us from setting the player to offline when they are
			--	on an alt.
		if self.lastUpdated < time then
			self.lastUpdated = time
			self.online = false;
		end
	end
	
	-- Set online time
	local function updateOnlineTime(self, time)
		time = EPGPWaitlist:round(time)
		-- If the player was offline, find the duration and add it to the
			-- offlinePeriods array
		if self.online == false then
			local duration = time - self.lastOnline
			if duration > 300 then
				table.insert(self.offlinePeriods, {lastOnline, time, duration})
			end
		end
		
		self.lastUpdated = time
		self.lastOnline = time
		self.online = true;
		self.alt = nil;
	end
	
	local function updateOnlineTimeAlt(self, time, alt)
		self.updateOnlineTime(self, time)
		self.alt = alt
	end
	
	-- Return the new object
	EPGPWaitlist.Player = function(name, onlineStatus)
		-- TODO: Check if player is in the guild
		if type(name) ~= "string" or name == "" then
			error("Invalid player name: " .. name)
		end
		
		local obj = {
			name = EPGPWaitlist:capitalize(name),
			updateOfflineTime = updateOfflineTime,
			updateOnlineTime = updateOnlineTime,
			updateOnlineTimeAlt = updateOnlineTimeAlt,
			online = onlineStatus,
			lastUpdated = EPGPWaitlist:round(GetTime()),
			lastOnline = EPGPWaitlist:round(GetTime()),
			alt = nil,
			offlinePeriods = {}
		}
		
		return obj
	end
end


--------------------
-- EVENT HANDLERS --
--------------------

-- Name:		GuildRosterUpdateEventHandler
-- Desc:		GUILD_ROSTER_UPDATE callback - updates the guild roster rank table
--					and updates the status and time of each guild member on the waitlist.
function EPGPWaitlist:GuildRosterUpdateEventHandler()
	local time = GetTime()
	
	-- Loop through every member, online and offline
	for i = 1, GetNumGuildMembers(true), 1 do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i)
		name = name:lower()
		
		-- Save the player's rank and note to the ranks table
		EPGPWaitlist.guildRoster[name] = {rank, note, online}
		
		-- Player is on waitlist
		if EPGPWaitlist.players[name] ~= nil then
			if online then
				EPGPWaitlist.players[name]:updateOnlineTime(time)
			else
				EPGPWaitlist.players[name]:updateOfflineTime(time)
			end
		-- Player is on an alt and on waitlist
		elseif rank == "Alt" and EPGPWaitlist.players[note:lower()] ~= nil then
			-- Get player status and update accordingly
			if online then
				EPGPWaitlist.players[note:lower()]:updateOnlineTimeAlt(time, name:lower())
			end
		end
	end
end

-- Name:		RaidRosterUpdateEventHandler
-- Desc:		RAID_ROSTER_UPDATE callback - updates the roster list and removes
--					players from the waitlist if they are in the raid.
function EPGPWaitlist:RaidRosterUpdateEventHandler()
	-- TODO: Disable when not in raid
	-- TODO: Enable if in raid
	
	EPGPWaitlist.raidRoster = {} -- Clear the raid roster
	
	-- Loop through each raid member
	for i = 1, MAX_RAID_MEMBERS, 1 do	
		local playerName = GetRaidRosterInfo(i)
		
		-- No player found at that index or player is not a guild member.
		if not playerName or not EPGPWaitlist:IsGuildMember(name) then
			playerName = playerName:lower()
			-- Player is an alt, remove their main from waitlist and add their main to the raidRoster
			if EPGPWaitlist:IsAlt(playerName) then
				EPGPWaitlist.raidRoster[EPGPWaitlist:GetAltsMain(playerName)] = true
				EPGPWaitlist.players[EPGPWaitlist:GetAltsMain(playerName)] = nil -- remove main from list if they exist
			else
				EPGPWaitlist.raidRoster[playerName] = true
				EPGPWaitlist.players[playerName] = nil -- remove from list if they exist
			end
		end
	end
end

-- Name:		WhisperEventHandler
-- Desc:		CHAT_MSG_WHISPER callback - catch whispers requesting waitlist actions
function EPGPWaitlist:WhisperEventHandler(eventName, ...)
	local msg, name = ...
	name = name:lower()
	msg = msg:lower()
	
	if msg == "waitlist add" then
		EPGPWaitlist:AddPlayer(name)
	elseif msg == "waitlist remove" then
		EPGPWaitlist:RemovePlayer(name)
	end
end