-- Player object (factory function)
do
	-- Set offline time
	local function updateOfflineTime(self, time)
		time = EPGPWaitlist:Round(time)
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
		time = EPGPWaitlist:Round(time)
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
	function EPGPWaitlist:Player(name, onlineStatus)
		-- TODO: Check if player is in the guild
		
		if type(name) ~= "string" or name == "" then
			error("Invalid player name: " .. name)
		end
		
		local obj = {
			name = EPGPWaitlist:Capitalize(name),
			updateOfflineTime = updateOfflineTime,
			updateOnlineTime = updateOnlineTime,
			updateOnlineTimeAlt = updateOnlineTimeAlt,
			online = onlineStatus,
			lastUpdated = EPGPWaitlist:Round(GetTime()),
			lastOnline = EPGPWaitlist:Round(GetTime()),
			alt = nil,
			offlinePeriods = {}
		}
		
		return obj
	end
end