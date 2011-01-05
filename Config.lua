do
    local db, altRanks, waitlistedPlayers
    
    -- Default saved variables
    local defaults = {
	char = {
	    offlineTimeout = 300,
	    waitlistedPlayers = {},
	    altRanks = {},
	}
    }
    
    -- Description:	Private function to check if an alt rank alread exists
    -- Parameters:	Rank number counting up from 0
    -- Created:		01/05/2011
    local function HasAltRank(self, rankNum)
	for idx,rank in ipairs(altRanks) do
	    if rank == rankNum then
	        return true
	    end
	end
	return false
    end
    
    --	Description:	Add an alt rank to the list
    --	Parameters:	addRank - can be string or number
    --	Modified:	01/05/2011
    local function AddAltRank(self, addRank)
	-- Check if the rank is a number
	if tonumber(addRank) ~= nil then
	    -- Ensure that rank isn't already in there
	    addRank = tonumber(addRank)
	    local rankName = GuildControlGetRankName(addRank+1)
	    if self.HasAltRank(self, addRank) then
		EPGPWaitlist:Print('Rank ' .. rankName ..'(' .. addRank .. ') already exists in the list of alt ranks.')
		return
	    end
	    tinsert(altRanks, addRank)
	    EPGPWaitlist:Print('Rank ' .. rankName ..'(' .. addRank .. ') has been added to list of alt ranks.')
	    return
	else
	    -- Assume addRank is a string and look up the rank name
	    local numRanks = GuildControlGetNumRanks()
	    local rankName
	    addRank = addRank:lower()
	    for rankNum = 1, numRanks do
		rankName = GuildControlGetRankName(rankNum)
		if rankName:lower() == addRank then
		    -- Insert rankNum-1 because GetGuildRosterInfo() will return rank ID
			-- counting up from 0, where as GuildControlGetRankName returns
			-- counting up from 1.
		    if self.HasAltRank(self, rankNum-1) then
			EPGPWaitlist:Print('Rank ' .. rankName .. '(' .. rankNum-1 .. ') already exists in the list of alt ranks.')
			return
		    end
		    
		    tinsert(altRanks, rankNum-1)
		    EPGPWaitlist:Print('Rank ' .. rankName .. '(' .. rankNum-1 .. ') has been added to list of alt ranks.')
		    return -- No need to proceed looping
		end
	    end
	end
	-- At this point, that rank does not exist
	EPGPWaitlist:Print('Rank ' .. addRank .. ' does not exist.')
    end
    
    --	Description:	Remove an alt rank from the list
    --	Parameters:	removeRank - can be string or number
    --	Modified:	01/05/2011
    local function RemoveAltRank(self, removeRank)
	local rankNum, rankName
	-- Check if the rank is a string
	if tonumber(removeRank) == nil then
	    removeRank = removeRank:lower()
	    -- Get the correspondong rank number
	    local numRanks = GuildControlGetNumRanks()
	    for i = 1, numRanks do
		rankName = GuildControlGetRankName(i)
		if rankName:lower() == removeRank then
		    rankNum = i-1
		    break
		end
	    end
	else
	    rankNum = tonumber(removeRank)
	    rankName = GuildControlGetRankName(rankNum+1)
	end
	
	-- Check if we have a rank number
	if rankNum == nil then
	    EPGPWaitlist:Print('Rank ' .. removeRank .. ' does not exist.')
	    return
	end
	
	-- Remove the corresponding rank
        for idx,rank in ipairs(altRanks) do
            if rank == rankNum then
		EPGPWaitlist:Print('Rank ' .. rankName .. '(' .. rankNum .. ') has been removed from the list of alt ranks.')
                tremove(altRanks, idx)
		return
            end
        end
	EPGPWaitlist:Print('Rank ' .. rankName .. '(' .. rankNum .. ') is not in the list of alt ranks.')
    end
    
    --	Description:	Checks if a rank is in the list of alt ranks
    --	Parameters:	searchRank - rank number counting up from 0
    local function IsAltRank(self, searchRank)
	for idx,rank in ipairs(altRanks) do
            if rank == searchRank then
                return true
            end
        end
	return false
    end
    
    --	Description:	Configure the offline timeout
    --	Parameters:	timeout - number in seconds
    local function SetOfflineTimeout(self, timeout)
	db.char.offlineTimeout = timeout
    end
    
    function EPGPWaitlist:Config()
	-- Get the database variables
	-- TODO: Do this on a guild basis instead of character
        db = LibStub("AceDB-3.0"):New("EPGPWaitlistDB", defaults)
	altRanks = db.char.altRanks
	waitlistedPlayers = db.char.waitlistedPlayers
	
        if(#altRanks == 0) then
	    EPGPWaitlist:Print("You have not configured an alt rank yet, please do so with /ewl addaltrank <rank>")
	end
        
    	local obj = {
	    HasAltRank = HasAltRank,
            AddAltRank = AddAltRank,
            RemoveAltRank = RemoveAltRank,
	    IsAltRank = IsAltRank,
	    SetOfflineTimeout = SetOfflineTimeout,
	    offlineTimeout = db.char.offlineTimeout,
	    waitlistedPlayers = waitlistedPlayers
    	}

	return obj
    end
end