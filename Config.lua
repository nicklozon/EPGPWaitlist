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
    
    local function AddAltRank(self, addRank)
	addRank = tonumber(addRank)
        for idx,rank in ipairs(altRanks) do
            if rank == addRank then
                return
            end
        end
	tinsert(altRanks, addRank)
    end
    
    local function RemoveAltRank(self, removeRank)
	removeRank = tonumber(removeRank)
        for idx,rank in ipairs(altRanks) do
            if rank == removeRank then
                tremove(altRanks, idx)
            end
        end
    end
    
    local function IsAltRank(self, searchRank)
	for idx,rank in ipairs(altRanks) do
            if rank == searchRank then
                return true
            end
        end
	return false
    end
    
    local function SetOfflineTimeout(self, timeout)
	db.char.offlineTimeout = timeout
    end
    
    function EPGPWaitlist:Config()
        db = LibStub("AceDB-3.0"):New("EPGPWaitlistDB", defaults)
	
	altRanks = db.char.altRanks
	waitlistedPlayers = db.char.waitlistedPlayers
	
        if(#altRanks == 0) then
	    EPGPWaitlist:Print("You have not configured an alt rank yet, please do so with /ewl addaltrank <rank>")
	end
        
    	local obj = {
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