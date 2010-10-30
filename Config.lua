do
    local db
    local altRanks
    
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
    
    function EPGPWaitlist:Config()
        db = LibStub("AceDB-3.0"):New("EPGPWaitlistDB")
        if(db.char.altRanks ~= nil) then
	    altRanks = db.char.altRanks
	    EPGPWaitlist:Print("You have not configured an alt rank yet, please do so with /ewl addaltrank <rank>")
	else
	    altRanks = {}
	end
        
    	local obj = {
            AddAltRank = AddAltRank,
            RemoveAltRank = RemoveAltRank,
	    IsAltRank = IsAltRank
    	}
		
	return obj
    end
end