do
    local players = {}

    local function RaidRosterUpdate(self)
        -- TODO: Disable when not in raid
        -- TODO: Enable if in raid

        wipe(players) -- Clear the raid roster

        -- Loop through each raid member
        for i = 1, MAX_RAID_MEMBERS, 1 do	
            local playerName = GetRaidRosterInfo(i)

            -- Player exists for that raid spot and the player is a guild member
            if type(playerName) == "string" then
                playerName = playerName:lower()
                if EPGPWaitlist.guildlist:IsGuildMember(playerName) then
                    -- Player is an alt, remove their main from waitlist and add their main to the raidRoster
                    if EPGPWaitlist.guildlist:IsAlt(playerName) then
                        players[EPGPWaitlist.guildlist:GetAltsMain(playerName)] = true
                        EPGPWaitlist.waitlist:RemovePlayer(EPGPWaitlist.guildlist:GetAltsMain(playerName))
                    else
                        players[playerName] = true
                        EPGPWaitlist.waitlist:RemovePlayer(playerName)
                    end
                end
            end
        end
    end

    local function IsInRaid(self, name)
        if players[name] ~= nill then
            return true
        end

        return false
    end

    function EPGPWaitlist:Raidlist()
        local obj = {
            RaidRosterUpdate = RaidRosterUpdate,
            IsInRaid = IsInRaid
        }

        return obj
    end
end
