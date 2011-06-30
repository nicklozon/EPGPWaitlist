do
	local players = {}
	
	local function AddPlayer(self, name, whispered)
		if(GetNumRaidMembers() == 0) then
                    EPGPWaitlist:Print("You must be in a raid to have a waitlist.")
                    return
		end
		name = name:lower()
		msgName = name:lower()
		
		-- Check this player is in the guild
		if not EPGPWaitlist.guildlist:IsGuildMember(name) then
			if(whispered) then
				SendChatMessage("This player is not in the guild. Your alts and main must be in the guild to use the waitlist.", "WHISPER", nil, name);
			end
			EPGPWaitlist:Print(EPGPWaitlist:Capitalize(name) .." requested to be on the waitlist, but is not in the guild.")
			return false
		end
		
		local onlineStatus = EPGPWaitlist.guildlist:GetOnlineStatus(name) -- The online status from last guild roster update
			
		-- Check if the player name is an alt, then get their main's name.
		if EPGPWaitlist.guildlist:IsAlt(name) then
			name = EPGPWaitlist.guildlist:GetAltsMain(name)
			-- Check that the main is in the guild
			if not EPGPWaitlist.guildlist:IsGuildMember(name) then
				if(whispered) then
					SendChatMessage(EPGPWaitlist:Capitalize(name) .. " is not in the guild. Check that the spelling is correct in your public note.", "WHISPER", nil, name);
				end
				EPGPWaitlist:Print(EPGPWaitlist:Capitalize(name) .." requested to be on the waitlist, but is not in the guild.")
				return false
			end 
		end
		
		-- Check if player is already on waitlist
		if self:IsWaitlisted(name) then
			if(whispered) then
				SendChatMessage(EPGPWaitlist:Capitalize(name) .. " is already on the waitlist.", "WHISPER", nil, name)
			end
			EPGPWaitlist:Print(EPGPWaitlist:Capitalize(name) .." is already on the waitlist.")
			return false
		-- Check if this player is in the raid
		elseif EPGPWaitlist.raidlist:IsInRaid(name) then
			if(whispered) then
				SendChatMessage("You are in the raid. You may not be on the waitlist while in the raid.", "WHISPER", nil, name)
			end
			EPGPWaitlist:Print(EPGPWaitlist:Capitalize(name) .." is already in the raid.")
			return false
		end
		
		-- Add player
		players[name] = EPGPWaitlist:Player(name, onlineStatus) -- Creates a new player object
		EPGPWaitlist:Print(EPGPWaitlist:Capitalize(name) .. " has been added to the waitlist.")
		
		-- Add player to save variables if it doesnt exist already
		local bool = false
		for idx,player in ipairs(EPGPWaitlist.config.waitlistedPlayers) do
			if(player == name) then
				bool = true
			end
		end
		if( not bool ) then
			tinsert(EPGPWaitlist.config.waitlistedPlayers, name) -- Add player to saved variables
		end
		
		if(whispered) then
			SendChatMessage(EPGPWaitlist:Capitalize(name) .. " has been added to the waitlist.", "WHISPER", nil, msgName)
		end
	end
	
	local function RemovePlayer(self, name, whispered)
		local name = name:lower()
		local main = name -- Player to remove from waitlist
		local msg = "" -- Message to be whispered/printed
		
		if(GetNumRaidMembers() == 0) then
			EPGPWaitlist:Print("You must be in a raid to have a waitlist.")
			return
		elseif players[name] == nil then
			if(whispered) then
				SendChatMessage("You are not on the waitlist.", "WHISPER", nil, name)
			end
			return
		end
		
		-- Check if player is an alt
		if EPGPWaitlist.guildlist:IsAlt(name) then
			-- Get their main's name
			main = EPGPWaitlist.guildlist:GetAltsMain(name)
		-- Check if they are on the waitlist
		elseif self:IsWaitlisted(main) == nil then
			msg = EPGPWaitlist:Capitalize(main) .." is not on the waitlist."
		-- Remove player
		else
			self:RemoveFromWaitlist(main)
			msg = EPGPWaitlist:Capitalize(main) .. " has been removed from the waitlist."
		end	
		
		-- Send messages
		if(whispered) then
			SendChatMessage(msg, "WHISPER", nil, name)
		end
	end
	
	function MassEPAward(self, event_name, names, reason, amount)
		reason = "Waitlist - " .. reason
		local awarded = false -- Only announce if we actually award a player
		EPGPWaitlist:GuildRosterUpdateEventHandler() -- Update the guild roster before awarding so offline durations are current
			
		-- Generate announce message
		local msg = "EPGP: "
		
		if amount > -1 then
			msg = msg .. "+"
		end

		msg = msg .. amount .. " EP (" .. reason .. ") to "
		
		-- Award EP to every member on the waitlist.
		-- WARNING: EPGP uses the LibGuildStorage to handle officer notes. This will prevent the
		--	IncEPBy from executing when the state of the GuildStorage object is not "CURRENT". I
		--	believe this signify's the officer notes as being "fresh". When EPGP rewards a Mass
		--	EP Award, it ignores the state of GuildStorage because "we know what we are doing"?
		--	Since we are tagging this with the Mass EP Award, it should be fine to do the same.
		for idx,player in pairs(players) do
			if player.online or (player.lastUpdated - player.lastOnline < EPGPWaitlist.config.offlineTimeout) then
				EPGP:IncEPBy(EPGPWaitlist:Capitalize(idx), reason, amount, true) -- Increment as a "mass" ep award
				msg = msg .. " " .. EPGPWaitlist:Capitalize(idx) .. "," -- append the player name
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
	
	local function IsWaitlisted(self, name)
		if players[name] ~= nil then
			return true
		end
		
		return false
	end
	
	local function RemoveFromWaitlist(self, name)
		if players[name] ~= nil then
			players[name] = nil
			if #EPGPWaitlist.config.waitlistedPlayers > 0 then
				for idx,player in ipairs(EPGPWaitlist.config.waitlistedPlayers) do
					if player == name then
						tremove(EPGPWaitlist.config.waitlistedPlayers, idx) -- Remove player from saved variables
					end
				end
			end
			return true
		end
		return false
	end
	
	local function List(self)
		EPGPWaitlist:GuildRosterUpdateEventHandler() -- Update the guild roster before awarding so offline durations are current
		
		for idx,player in pairs(players) do
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
	
	local function RemoveAll(self)
		wipe(players) -- Wipe the players table
		wipe(EPGPWaitlist.config.waitlistedPlayers) -- Wipe the saved variables
		EPGPWaitlist:Print("Waitlist has been wiped.")
	end
	
	local function UpdatePlayerStatus(self, name, time, isOnline, isAlt, altName)
		if isAlt then
			players[name]:updateOnlineTimeAlt(time, altName)
		elseif isOnline then
			players[name]:updateOnlineTime(time)
		else
			players[name]:updateOfflineTime(time)
		end
	end
	
	function EPGPWaitlist:Waitlist()
		local obj = {
			AddPlayer = AddPlayer,
			RemovePlayer = RemovePlayer,
			IsWaitlisted = IsWaitlisted,
			RemoveFromWaitlist = RemoveFromWaitlist,
			List = List,
			RemoveAll = RemoveAll,
			UpdatePlayerStatus = UpdatePlayerStatus,
			MassEPAward = MassEPAward
		}
		
		return obj
	end
end