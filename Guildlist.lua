do
    -- table of players
    local players = {}

    local function GuildRosterUpdate(self)
        local time = GetTime()

        -- Loop through every member, online and offline
        for i = 1, GetNumGuildMembers(true), 1 do
            local name, _, rank, _, _, _, _, note, online = GetGuildRosterInfo(i)
            name = name:lower()

            -- Save the player's rank and officer note to the ranks table
            players[name] = {rank, note, online}

            -- Player is on waitlist
            if EPGPWaitlist.waitlist:IsWaitlisted(name) then
                if online then
                    EPGPWaitlist.waitlist:UpdatePlayerStatus(name, time, true)
                else
                    EPGPWaitlist.waitlist:UpdatePlayerStatus(name, time)
                end
                -- Player is on an alt and on waitlist
            elseif EPGPWaitlist.config:IsAltRank(rank) and EPGPWaitlist.waitlist:IsWaitlisted(note:lower()) and online then
                EPGPWaitlist.waitlist:UpdatePlayerStatus(note:lower(), time, true, true, name)
            end
        end
    end

    local function IsAlt(self, name)
        return EPGPWaitlist.config:IsAltRank(players[name][1])
    end

    local function IsGuildMember(self, name)
        if players[name] ~= nil then
            return true
        end

        return false
    end

    local function GetAltsMain(self, altName)
        -- Checks if alt is in the guild
        assert(players[altName], EPGPWaitlist:Capitalize(altName) .. " is not in the guild.")

        -- Checks if the player is an alt
        assert(self:IsAlt(altName), EPGPWaitlist:Capitalize(altName) .. " is not an alt.")

        -- Get the main player's name
        local note = players[altName][2]:lower()

        -- Checks if the main player is in the guild
        assert(players[note], EPGPWaitlist:Capitalize(note) .. " is not in the guild.")

        return note
    end

    local function GetOnlineStatus(self, name)
        return players[name][3]
    end

    function EPGPWaitlist:Guildlist()
        local obj = {
            GuildRosterUpdate = GuildRosterUpdate,
            IsAlt = IsAlt,
            IsGuildMember = IsGuildMember,
            GetAltsMain = GetAltsMain,
            GetOnlineStatus = GetOnlineStatus
        }

        return obj
    end
end
