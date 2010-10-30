-- Create addon as Ace3, AceConsole and AceEvent
EPGPWaitlist = LibStub("AceAddon-3.0"):NewAddon("EPGPWaitlist", "AceConsole-3.0", "AceEvent-3.0")
do
    local waitlist, guildlist, raidlist
    
    function EPGPWaitlist:OnInitialize()
            -- Register the slash command
            EPGPWaitlist:RegisterChatCommand("wlp", "SlashCommandHandler")
            
            -- Register event handlers
            EPGPWaitlist:RegisterEvent("CHAT_MSG_WHISPER", "WhisperEventHandler")
            EPGPWaitlist:RegisterEvent("GUILD_ROSTER_UPDATE", "GuildRosterUpdateEventHandler")
            EPGPWaitlist:RegisterEvent("RAID_ROSTER_UPDATE", "RaidRosterUpdateEventHandler")
            
            -- Create the list objects
            waitlist = EPGPWaitlist:Waitlist()
            guildlist = EPGPWaitlist:Guildlist()
            raidlist = EPGPWaitlist:Raidlist()
            
            -- Make the objects accessible externally
            EPGPWaitlist['waitlist'] = waitlist
            EPGPWaitlist['guildlist'] = guildlist
            EPGPWaitlist['raidlist'] = raidlist
    end
    
    function EPGPWaitlist:OnEnable()
            -- Register callback with EPGP for Mass EP Awards
            EPGP.RegisterCallback(EPGPWaitlist, "MassEPAward")
            
            -- Since the addon was just enabled, update the Guild and raid roster tables
            guildlist.GuildRosterUpdate()
            raidlist:RaidRosterUpdate() -- Depends on guildRoster being current 
            
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
            
            if msg == "waitlist add" then
                    waitlist:AddPlayer(name)
            elseif msg == "waitlist remove" then
                    waitlist:RemovePlayer(name)
                    --zomg((^&(*&*)) -- wtf is this?
            end
    end

    function EPGPWaitlist:GuildRosterUpdateEventHandler()
            guildlist:GuildRosterUpdate()
    end
    
    function EPGPWaitlist:RaidRosterUpdateEventHandler()
            raidlist:RaidRosterUpdate()
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
            end
    end	
end
