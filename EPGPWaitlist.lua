-- Create addon as Ace3, AceConsole and AceEvent
EPGPWaitlist = LibStub("AceAddon-3.0"):NewAddon("EPGPWaitlist", "AceConsole-3.0", "AceEvent-3.0")
do
    local waitlist, guildlist, raidlist, config
    
    function EPGPWaitlist:OnInitialize()
            -- Register the slash command
            EPGPWaitlist:RegisterChatCommand("ewl", "SlashCommandHandler")
            
            -- Create the list objects
            waitlist = EPGPWaitlist:Waitlist()
            guildlist = EPGPWaitlist:Guildlist()
            raidlist = EPGPWaitlist:Raidlist()
            config = EPGPWaitlist:Config()
            
            -- Make the objects accessible externally
            EPGPWaitlist['waitlist'] = waitlist
            EPGPWaitlist['guildlist'] = guildlist
            EPGPWaitlist['raidlist'] = raidlist
            EPGPWaitlist['config'] = config
    end
    
    function EPGPWaitlist:OnEnable()
            -- Register event handlers
            EPGPWaitlist:RegisterEvent("CHAT_MSG_WHISPER", "WhisperEventHandler")
            EPGPWaitlist:RegisterEvent("GUILD_ROSTER_UPDATE", "GuildRosterUpdateEventHandler")
            EPGPWaitlist:RegisterEvent("RAID_ROSTER_UPDATE", "RaidRosterUpdateEventHandler")
            
            -- Register callback with EPGP for Mass EP Awards
            EPGP.RegisterCallback(self, "MassEPAward")
            
            -- Since the addon was just enabled, update the Guild and raid roster tables
            guildlist:GuildRosterUpdate()
            raidlist:RaidRosterUpdate() -- Depends on guildRoster being current
            
            -- Load stored waitlisted players
            for idx,player in ipairs(config.waitlistedPlayers) do
                waitlist:AddPlayer(player)
            end
            
            EPGPWaitlist:Print("EPGPWaitlist loaded!")
    end
    
    function EPGPWaitlist:OnDisable()
            EPGP.UnregisterCallback(EPGPWaitlist, "MassEPAward")
            
            EPGPWaitlist:Print("EPGPWaitlist disabled!")
    end
    
    function EPGPWaitlist:WhisperEventHandler(eventName, ...)
            local msg, name = ...
            name = name:lower()
            msg = msg:lower()
            
            if(msg == "waitlist add" or msg == "waitlist remove") then
                if(GetNumGroupMembers() == 0) then
                        SendChatMessage("There is currently no raid in progress.", "WHISPER", nil, name);
                        return
                end
            end
            
            if msg == "waitlist add" then
                    waitlist:AddPlayer(name, true)
            elseif msg == "waitlist remove" then
                    waitlist:RemovePlayer(name, true)
            end
    end

    function EPGPWaitlist:GuildRosterUpdateEventHandler()
            guildlist:GuildRosterUpdate()
    end
    
    function EPGPWaitlist:RaidRosterUpdateEventHandler()
        if(GetNumGroupMembers() > 0) then
            raidlist:RaidRosterUpdate()
        else -- Not in a raid group, wipe waitlist
            waitlist:RemoveAll()
        end
    end
    
    function EPGPWaitlist:Capitalize(word)
        return word:sub(1, 1):upper() .. word:sub(2):lower()
    end
    
    function EPGPWaitlist:Round(num, idp)
        local mult = 10^(idp or 0)
        return math.floor(num * mult + 0.5) / mult
    end
    
    function EPGPWaitlist:MassEPAward(event_name, names, reason, amount, ...)
	    waitlist:MassEPAward(event_name, names, reason, amount)
    end
    
    function EPGPWaitlist:SlashCommandHandler(input)
            input = input:lower() -- make it all lowercase
            
            -- Get all the arguments
            local cmd, args = input:match("([^ ]+) ?(.*)") 
            
            if cmd == "add" then
                waitlist:AddPlayer(args)
            elseif cmd == "remove" then
                waitlist:RemovePlayer(args)
            elseif cmd == "removeall" then
                waitlist:RemoveAll()
            elseif cmd == "list" then
                waitlist:List()
            elseif cmd == "addaltrank" then
                config:AddAltRank(args)
            elseif cmd == "removealtrank" then
                config:RemoveAltRank(args)
            elseif cmd == "offlinetimeout" then
                config:SetOfflineTimeout(args)
            else
                EPGPWaitlist:Print("Usage: /ewl {add, remove, removeall, list, addaltrank, removealtrank, offlinetimeout}")
            end
    end	
end
