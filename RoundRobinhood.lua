local _G = _G or getfenv()

RoundRobinhood = {}

RoundRobinhood.itemRollState = {}; -- Stores state for items currently being rolled, keyed by item name.

-- Create a new frame to register events for the addon.
RoundRobinhood.frame = CreateFrame("Frame", "RoundRobinFrame", WorldFrame);
-- Register events that the addon needs to listen to.
RoundRobinhood.frame:RegisterEvent("START_LOOT_ROLL");       -- Triggered when a loot roll starts.
RoundRobinhood.frame:RegisterEvent("CHAT_MSG_LOOT");         -- Triggered when a loot message appears in chat (e.g., someone wins a roll).
RoundRobinhood.frame:RegisterEvent("PLAYER_ENTERING_WORLD"); -- Triggered when the player logs in or enters a new zone.

-- Default Round Robin items and their initial player counts.
-- This structure stores how many times each player has won a specific item.
RoundRobinhood.DEFAULT_RR_RECORDS_ITEMS_V1 = {
    ["Righteous Orb"] = {
        WarrCroc = 99,
        MageCroc = 98,
        LockCroc = 97
    }
};

-- Default auto-roll settings for items and item qualities.
-- 0: Pass, 1: Need, 2: Greed, 4: Round Robin (auto-decide based on lowest count), 5: Manual (no auto-roll).
RoundRobinhood.DEFAULT_AUTO_ITEMS_V1 = {
    ["White Items"] = 5,
    ["Green Items"] = 5,
    ["Blue Items"] = 5,
    ["Purple Items"] = 5,
    ["Corruptor's Scourgestone"] = 1,
    ["Righteous Orb"] = 4
};
-- Prints a message to the default chat frame.
function RoundRobinhood.Print(msg)
    if not DEFAULT_CHAT_FRAME then
        return;
    end;
    DEFAULT_CHAT_FRAME:AddMessage(msg);
end;

-- Prints an auto-roll related message to the default chat frame.
function RoundRobinhood.PrintAuto(msg)
    if not RR_SETTINGS_V1.muteAutoNotification then
        RoundRobinhood.PrintColor(msg);
    end
end;

-- Prints a colored message to the default chat frame.
function RoundRobinhood.PrintColor(msg)
    local r, g, b = 0.96, 0.55, 0.73;
    local hexColor = string.format("|cFF%02X%02X%02X", r * 255, g * 255, b * 255);
    RoundRobinhood.Print(hexColor .. msg);
end;

-- Returns the string name for a given numeric item quality.
function RoundRobinhood.GetQualityName(quality)
    if quality == 0 then
        return "Poor Items";
    elseif quality == 1 then
        return "White Items";
    elseif quality == 2 then
        return "Green Items";
    elseif quality == 3 then
        return "Blue Items";
    elseif quality == 4 then
        return "Purple Items";
    elseif quality == 5 then
        return "Orange Items"; -- Legendary
    elseif quality == 6 then
        return "Artifact Items";
    elseif quality == 7 then
        return "Heirloom Items";
    end
    return "Unknown Quality";
end;

-- Counts the number of keys (elements) in a table.
function RoundRobinhood.CountKeys(t)
    local count = 0;
    for _ in pairs(t) do
        count = count + 1;
    end;
    return count;
end;

-- Sends a message to the appropriate chat channel (RAID, PARTY, or SAY).
-- Respects the addon's mute setting.
function RoundRobinhood.SendMsg(msg)
    if RR_SETTINGS_V1 and RR_SETTINGS_V1.isMute then
        if not RR_SETTINGS_V1.muteNotificationShown then
            RoundRobinhood.PrintColor("RoundRobinhood is muted. Type '/rrh mute' to unmute.");
            RR_SETTINGS_V1.muteNotificationShown = true;
        end;
        return;
    end;
    local channel;
    if GetNumRaidMembers() > 0 then
        channel = "RAID";
    elseif GetNumPartyMembers() > 0 then
        channel = "PARTY";
    else
        channel = "SAY";
    end;

    if channel == "SAY" then
        RoundRobinhood.Print(msg);
    else
        SendChatMessage(msg, channel);
    end;
end;

-- Initializes addon's saved variables (RR_RECORDS_ITEMS_V1, RR_AUTO_ITEMS_V1, RR_SETTINGS_V1).
-- Ensures default values are set if variables are not yet loaded or are nil.
function RoundRobinhood.Initialize()
    -- Initialize RR_RECORDS_ITEMS_V1 (Round Robin item tracking) if not already set.
    if not RR_RECORDS_ITEMS_V1 or next(RR_RECORDS_ITEMS_V1) == nil then
        RR_RECORDS_ITEMS_V1 = RoundRobinhood.DEFAULT_RR_RECORDS_ITEMS_V1;
    end

    -- Initialize RR_AUTO_ITEMS_V1 (auto-roll settings) if not already set.
    if not RR_AUTO_ITEMS_V1 or next(RR_AUTO_ITEMS_V1) == nil then
        RR_AUTO_ITEMS_V1 = RoundRobinhood.DEFAULT_AUTO_ITEMS_V1;
    end

    -- Initialize RR_SETTINGS_V1 (general addon settings) if not already set.
    if not RR_SETTINGS_V1 then
        RR_SETTINGS_V1 = {};
    end
    -- Set default mute status.
    if RR_SETTINGS_V1.isMute == nil then
        RR_SETTINGS_V1.isMute = false;
    end
    -- Set default notification flags.
    if RR_SETTINGS_V1.muteNotificationShown == nil then
        RR_SETTINGS_V1.muteNotificationShown = false;
    end
    if RR_SETTINGS_V1.muteAutoNotification == nil then
        RR_SETTINGS_V1.muteAutoNotification = false;
    end
    -- Set default auto-roll enabled status.
    if RR_SETTINGS_V1.autoRollEnabled == nil then
        RR_SETTINGS_V1.autoRollEnabled = true; -- Enabled by default
    end
    if RR_SETTINGS_V1.lastTab == nil then
        RR_SETTINGS_V1.lastTab = 2;
    end

    RoundRobinhood.PrintColor("RoundRobinhood loaded, '/rrh' to start.")
end;

-- Retrieves the names of all current raid or party members, including the player.
-- Returns a sorted table of names.
function RoundRobinhood.GetMembersNames()
    local currNames = {};
    local currnumPartyMembers = GetNumPartyMembers();
    local currnumRaidMembers = GetNumRaidMembers();
    local myName;
    if currnumRaidMembers > 0 then
        for i = 1, 40 do
            local name = UnitName("raid" .. i);
            if name then
                table.insert(currNames, name);
            end;
        end;
    elseif currnumPartyMembers > 0 then
        for i = 1, currnumPartyMembers do
            local name = UnitName("party" .. i);
            if name then
                table.insert(currNames, name);
            end;
        end;
        myName = UnitName("player");
        if myName then
            table.insert(currNames, myName);
        end;
    else
        myName = UnitName("player");
        if myName then
            table.insert(currNames, myName);
        end;
    end;
    table.sort(currNames);
    return currNames;
end;

-- Outputs the current counts for a specific item by player.
-- 'method' determines how the message is formatted and sent (e.g., "roll", "won", "show", "send").
function RoundRobinhood.OutputCountsByItem(itemName, method)
    local currPlayerNames = RoundRobinhood.GetMembersNames();
    local msgCurrentResult = {};
    for _, currName in ipairs(currPlayerNames) do
        -- Initialize player count to 0 if not already present for the item.
        if not RR_RECORDS_ITEMS_V1[itemName][currName] then
            RR_RECORDS_ITEMS_V1[itemName][currName] = 0;
        end;
        table.insert(msgCurrentResult, currName .. " " .. RR_RECORDS_ITEMS_V1[itemName][currName]);
    end;
    local textTemp1 = "";
    local textTemp2 = table.concat(msgCurrentResult, ", ");
    if method == "roll" then
        textTemp1 = "[" .. itemName .. "] dropped! Currently:";
        RoundRobinhood.SendMsg(textTemp1);
        RoundRobinhood.SendMsg(textTemp2);
    elseif method == "won" then
        RoundRobinhood.SendMsg(textTemp2);
    elseif method == "show" then
        textTemp1 = "[" .. itemName .. "] currently:";
        RoundRobinhood.Print(textTemp1);
        RoundRobinhood.Print(textTemp2);
    elseif method == "send" then
        textTemp1 = "[" .. itemName .. "] results are:";
        RoundRobinhood.SendMsg(textTemp1);
        RoundRobinhood.SendMsg(textTemp2);
    end;
end;

-- Helper function to get all item names currently tracked in RR_RECORDS_ITEMS_V1.
function RoundRobinhood.GetAllItemNames()
    local itemNames = {};
    for itemName in pairs(RR_RECORDS_ITEMS_V1) do
        table.insert(itemNames, itemName);
    end;
    return itemNames;
end;

-- Handles the START_LOOT_ROLL event.
-- Determines if the rolled item is tracked and applies auto-roll logic if enabled.
function RoundRobinhood.StartRollHandler(rollID)
    local qualityName = "unknown"
    local itemLink = GetLootRollItemLink(rollID);
    if not itemLink then
        return;
    end;

    local texture, name, count, quality = GetLootRollItemInfo(rollID);

    -- Check if the rolled item is one of the tracked items in RR_RECORDS_ITEMS_V1.
    for itemName, players in pairs(RR_RECORDS_ITEMS_V1) do
        if itemName == name then
            RoundRobinhood.OutputCountsByItem(itemName, "roll");
            break;
        end;
    end;

    -- Master switch for auto-roll functionality.
    if RR_SETTINGS_V1.autoRollEnabled then
        local autoRollAction = nil;

        -- AUTO deal with items by Name (specific item auto-roll rules).
        for itemName, action in pairs(RR_AUTO_ITEMS_V1) do
            if itemName == name then
                autoRollAction = action;
                break;
            end;
        end;

        -- If no specific rule by name, check by Quality
        if autoRollAction == nil then
            qualityName = RoundRobinhood.GetQualityName(quality);
            autoRollAction = RR_AUTO_ITEMS_V1[qualityName];
        end

        -- Only proceed if there's an auto-roll action defined and it's not Manual (5)
        if autoRollAction ~= nil and autoRollAction ~= 5 then
            if autoRollAction == 4 then -- This is the Round Robin case
                -- Initialize or update itemRollState for the current item
                if not RoundRobinhood.itemRollState[name] then
                    RoundRobinhood.itemRollState[name] = { lastDropTime = 0, pendingCount = 0 };
                end
                local state = RoundRobinhood.itemRollState[name];
                state.lastDropTime = GetTime(); -- Always update lastDropTime for RR items

                local canAutoRoll = false;
                -- Condition 1: No pending rolls
                if state.pendingCount == 0 then
                    canAutoRoll = true;
                    -- Condition 2: Pending rolls exist, but last drop was more than 65 seconds ago (timeout)
                elseif (GetTime() - state.lastDropTime > 65) then
                    canAutoRoll = true;
                    state.pendingCount = 0; -- Reset pending count on timeout
                end

                if canAutoRoll then
                    -- Perform Round Robin specific logic and RollOnLoot
                    local myName = UnitName("player");
                    local myCount = RR_RECORDS_ITEMS_V1[name] and RR_RECORDS_ITEMS_V1[name][myName] or 0;
                    local lowestCount = myCount;
                    local isLowest = true;
                    local currPlayerNames = RoundRobinhood.GetMembersNames();

                    for _, currName in ipairs(currPlayerNames) do
                        local playerCount = RR_RECORDS_ITEMS_V1[name] and RR_RECORDS_ITEMS_V1[name][currName] or 0;
                        if playerCount < lowestCount then
                            lowestCount = playerCount;
                            isLowest = false; -- Found someone with less than me
                        end
                    end

                    local finalAction = 0; -- Default to pass
                    if isLowest then
                        RoundRobinhood.PrintAuto("auto need on RR-item: " .. itemLink);
                        finalAction = 1; -- Need
                    else
                        RoundRobinhood.PrintAuto("auto pass on RR-item: " .. itemLink)
                        finalAction = 0; -- Pass
                    end
                    RollOnLoot(rollID, finalAction);
                    state.pendingCount = 1; -- Mark this roll as pending
                else
                    RoundRobinhood.PrintAuto("Another [" ..
                        name .. "] roll is in process. Skipping auto-roll, please make decision manually.");
                    state.pendingCount = state.pendingCount + 1;
                end
            else -- For other autoRollAction values (0, 1, 2 - Pass, Need, Greed)
                local actionText = "unknown";
                if autoRollAction == 0 then
                    actionText = "pass";
                elseif autoRollAction == 1 then
                    actionText = "need";
                elseif autoRollAction == 2 then
                    actionText = "greed";
                end
                local printTarget = "item";
                if qualityName == "White Items" or qualityName == "Green Items" or qualityName == "Blue Items" then
                    printTarget = qualityName;
                end
                RoundRobinhood.PrintAuto("auto " .. actionText .. " on " .. printTarget .. ": " .. itemLink);
                RollOnLoot(rollID, autoRollAction);
            end
        end
    end
end;

-- Handles the CHAT_MSG_LOOT event.
-- Updates item counts for players who win tracked items.
function RoundRobinhood.LootResultHandler(msg)
    -- Ignore messages that are just roll announcements.
    if string.find(msg, "Roll -") then
        return;
    end;
    for itemName in pairs(RR_RECORDS_ITEMS_V1) do
        -- Check if the loot message contains a tracked item and indicates a win.
        if string.find(msg, itemName) and string.find(msg, "won: ") then
            local startIndex, endIndex = string.find(msg, " won: ");
            if startIndex then
                local winnerName = string.sub(msg, 1, startIndex - 1);
                -- Adjust winner name if it's the player themselves.
                if winnerName == "You" then
                    winnerName = UnitName("player");
                end;
                local msg1 = winnerName .. " won: [" .. itemName .. "]";
                RoundRobinhood.SendMsg(msg1);

                -- Update itemRollState pendingCount
                if RoundRobinhood.itemRollState[itemName] then
                    local state = RoundRobinhood.itemRollState[itemName];
                    if state.pendingCount > 0 then
                        state.pendingCount = state.pendingCount - 1;
                    end
                    -- Ensure pendingCount doesn't go below zero
                    if state.pendingCount < 0 then
                        state.pendingCount = 0;
                    end
                end

                -- Increment the winner's count for the item.
                if RR_RECORDS_ITEMS_V1[itemName][winnerName] then
                    RR_RECORDS_ITEMS_V1[itemName][winnerName] = RR_RECORDS_ITEMS_V1[itemName][winnerName] + 1;
                else
                    RR_RECORDS_ITEMS_V1[itemName][winnerName] = 1;
                end;
                RoundRobinhood.OutputCountsByItem(itemName, "won");
            end;
        end;
    end;
end;

-- Main event handler function for the RRFrame.
-- Dispatches events to appropriate handler functions.
function RoundRobinhood.OnEventFunc()
    if event == "START_LOOT_ROLL" then
        RoundRobinhood.StartRollHandler(arg1);
    elseif event == "CHAT_MSG_LOOT" then
        RoundRobinhood.LootResultHandler(arg1);
    elseif event == "PLAYER_ENTERING_WORLD" then
        RoundRobinhood.Initialize(); -- Initialize saved variables when entering the world.
    end;
end;

RoundRobinhood.frame:SetScript("OnEvent", RoundRobinhood.OnEventFunc);
SLASH_ROUNDROBINHOOD1 = "/rrh";
-- Command Handlers
-- Each function handles a specific slash command.
-- This makes the code cleaner and easier to maintain.

-- Handles '/rrh show <number>' or '/rrh send <number>' commands.
-- Displays or sends the current counts for a specified item.
function RoundRobinhood.HandleItemDisplayCommand(commandlist, method)
    local action2 = commandlist[2];
    local itemNames = RoundRobinhood.GetAllItemNames();
    if not tonumber(action2) then
        local msg1 = "Incorrect input. please try like: '/rrh " .. method .. " 1'";
        RoundRobinhood.PrintColor(msg1);
        for index, name in ipairs(itemNames) do
            RoundRobinhood.Print(index .. ". [" .. name .. "]");
        end;
    elseif itemNames[tonumber(action2)] then
        RoundRobinhood.OutputCountsByItem(itemNames[tonumber(action2)], method);
    else
        local msg2 = "The number you input: " .. action2 .. ", is not found.";
        RoundRobinhood.Print(msg2);
    end;
end

-- Handles '/rrh reset' command.
-- Resets all item counts for all players in RR_RECORDS_ITEMS_V1.
function RoundRobinhood.HandleResetCommand(commandlist)
    for itemName in pairs(RR_RECORDS_ITEMS_V1) do
        RR_RECORDS_ITEMS_V1[itemName] = {}; -- Clear player data for each item.
    end;
    RoundRobinhood.PrintColor("All items records have been reset. Try checking by '/rrh show'");
end

-- Handles '/rrh set <player_index> <item_index> <count>' command.
-- Manually sets a player's count for a specific item.
function RoundRobinhood.HandleSetCommand(commandlist)
    local action2 = commandlist[2]; -- Player index
    local action3 = commandlist[3]; -- Item index
    local action4 = commandlist[4]; -- Count to set
    local itemNames = RoundRobinhood.GetAllItemNames();
    local currPlayerNames = RoundRobinhood.GetMembersNames();

    -- Prepare player and item lists for error messages
    local msgItems = {};
    for index, name in ipairs(itemNames) do
        table.insert(msgItems, "[" .. index .. "]" .. " " .. name);
    end;
    local textItems = table.concat(msgItems, ", ");

    local msgPlayers = {};
    for index, name in ipairs(currPlayerNames) do
        table.insert(msgPlayers, "[" .. index .. "]" .. " " .. name);
    end;
    local textPlayers = table.concat(msgPlayers, ", ");

    -- Validate argument count
    if table.getn(commandlist) ~= 4 then
        RoundRobinhood.PrintColor("Usage: /rrh set <player_index> <item_index> <count>");
        RoundRobinhood.PrintColor("Example: /rrh set 2 1 3 (Sets 2nd player's 1st item count to 3)");
        RoundRobinhood.Print("Player: " .. textPlayers);
        RoundRobinhood.Print("Item: " .. textItems);
        return;
    end;

    local playerIndex = tonumber(action2);
    local itemIndex = tonumber(action3);
    local newCount = tonumber(action4);

    -- Validate player index
    if not playerIndex or playerIndex < 1 or playerIndex > table.getn(currPlayerNames) then
        RoundRobinhood.PrintColor("Invalid player index: " .. (action2 or "nil"));
        RoundRobinhood.Print("Player: " .. textPlayers);
        return;
    end;

    -- Validate item index
    if not itemIndex or itemIndex < 1 or itemIndex > table.getn(itemNames) then
        RoundRobinhood.PrintColor("Invalid item index: " .. (action3 or "nil"));
        RoundRobinhood.Print("Item: " .. textItems);
        return;
    end;

    -- Validate new count
    if not newCount or newCount < 0 then -- Assuming count should be non-negative
        RoundRobinhood.PrintColor("Invalid count: " .. (action4 or "nil") .. ". Count must be a non-negative number.");
        return;
    end;

    local pName = currPlayerNames[playerIndex];
    local iName = itemNames[itemIndex];

    -- Ensure the item entry exists before trying to access its player counts
    if not RR_RECORDS_ITEMS_V1[iName] then
        RR_RECORDS_ITEMS_V1[iName] = {};
    end

    local pOldNumber = RR_RECORDS_ITEMS_V1[iName][pName] or 0;
    RR_RECORDS_ITEMS_V1[iName][pName] = newCount;

    local myName = UnitName("player");
    local msgtemp1 = myName ..
        " changed " .. pName .. "'s [" .. iName .. "] from " .. pOldNumber .. " to " .. newCount .. ".";
    RoundRobinhood.SendMsg(msgtemp1);
    RoundRobinhood.OutputCountsByItem(iName, "send");
end

-- Handles '/rrh item <add|remove> [Item Name]' command.
-- Adds or removes an item from the tracking list.
function RoundRobinhood.HandleItemCommand(commandlist, msg)
    local text1 = "To add a new item, the input must contain square brackets, Like: '/rrh item add [Righteous Orb]'";
    local text2 =
    "To remove an item, the input must contain square brackets, Like: '/rrh item remove [Righteous Orb]'";
    local text3 = "Incorrect input. please try: '/rrh item add' or '/rrh item remove' ";
    local action2 = commandlist[2];
    local extractedItemName = "";
    local startIndex, endIndex = string.find(msg, "%[(.+)%]");
    if action2 == "add" then
        if startIndex and endIndex then
            extractedItemName = string.sub(msg, startIndex + 1, endIndex - 1);
            RR_RECORDS_ITEMS_V1[extractedItemName] = {}; -- Initialize with an empty table for player counts.
            RoundRobinhood.PrintColor("New Item Added: [" .. extractedItemName .. "]");
        else
            RoundRobinhood.PrintColor(text1);
        end;
    elseif action2 == "remove" then
        if startIndex and endIndex then
            extractedItemName = string.sub(msg, startIndex + 1, endIndex - 1);
            if RR_RECORDS_ITEMS_V1[extractedItemName] then
                RR_RECORDS_ITEMS_V1[extractedItemName] = nil; -- Remove the item from tracking.
                RoundRobinhood.PrintColor("Item [" .. extractedItemName .. "] Removed");
            else
                RoundRobinhood.Print("Item [" .. extractedItemName .. "] Not Found.");
            end;
        else
            RoundRobinhood.PrintColor(text2);
        end;
    else
        RoundRobinhood.PrintColor(text3);
    end;
end

-- Handles '/rrh mute' command.
-- Toggles the addon's message sending (mute/unmute).
function RoundRobinhood.HandleMuteCommand()
    RR_SETTINGS_V1.isMute = not RR_SETTINGS_V1.isMute;
    RR_SETTINGS_V1.muteNotificationShown = false; -- Reset notification flag so mute message shows again if unmuted.
    if RR_SETTINGS_V1.isMute then
        RoundRobinhood.PrintColor("RoundRobinhood Muted.");
    else
        RoundRobinhood.PrintColor("RoundRobinhood Unmuted.");
    end;
end

-- Handles '/rrh auto mute' command.
-- Toggles the mute status for auto-roll notifications.
function RoundRobinhood.HandleAutoMuteCommand()
    RR_SETTINGS_V1.muteAutoNotification = not RR_SETTINGS_V1.muteAutoNotification;
    if RR_SETTINGS_V1.muteAutoNotification then
        RoundRobinhood.PrintColor("Auto-roll notifications Muted.");
    else
        RoundRobinhood.PrintColor("Auto-roll notifications Unmuted.");
    end
end

-- Handles '/rrh auto list' command.
-- Lists the current auto-roll settings for items and qualities.
function RoundRobinhood.HandleAutoListCommand()
    RoundRobinhood.PrintAutoMessage("Current Auto-Roll List:");
    local count = 0
    for name, value in pairs(RR_AUTO_ITEMS_V1) do
        local actionText = "Unknown"
        if value == 0 then
            actionText = "Pass"
        elseif value == 1 then
            actionText = "Need"
        elseif value == 2 then
            actionText = "Greed"
        elseif value == 4 then
            actionText = "RoundRobin"
        elseif value == 5 then
            actionText = "Manual"
        end
        RoundRobinhood.Print("[" .. name .. "] = " .. actionText .. " (" .. value .. ")");
        count = count + 1
    end
    if count == 0 then
        RoundRobinhood.PrintAutoMessage("The auto-roll list is empty.")
    end
end

-- Handles '/rrh auto set [Item Name] <0-5>' command.
-- Sets the auto-roll behavior for a specific item or quality.
function RoundRobinhood.HandleAutoSetCommand(commandlist, msg)
    local extractedItemName = "";
    local startIndex, endIndex = string.find(msg, "%[(.+)%]");
    if startIndex and endIndex then
        extractedItemName = string.sub(msg, startIndex + 1, endIndex - 1);
    end
    local valueString = commandlist[table.getn(commandlist)];
    local value = tonumber(valueString);

    if extractedItemName ~= "" and value ~= nil and (value >= 0 and value <= 5) then
        RR_AUTO_ITEMS_V1[extractedItemName] = value;
        local actionText = "Unknown";
        if value == 0 then
            actionText = "PASS";
        elseif value == 1 then
            actionText = "NEED";
        elseif value == 2 then
            actionText = "GREED";
        elseif value == 4 then
            actionText = "RoundRobin";
        elseif value == 5 then
            actionText = "Manual";
        end
        RoundRobinhood.PrintAutoMessage("Set [" .. extractedItemName .. "] to <" .. actionText .. ">");
    else
        RoundRobinhood.PrintColor("Usage: /rrh auto set [Item Name] <0-5>");
        RoundRobinhood.PrintColor("0:Pass, 1:Need, 2:Greed, 4:RR, 5:Manual");
    end
end

-- Handles '/rrh auto remove [Item Name]' command.
-- Removes a specific item from the auto-roll list.
function RoundRobinhood.HandleAutoRemoveCommand(commandlist, msg)
    local extractedItemName = "";
    local startIndex, endIndex = string.find(msg, "%[(.+)%]");
    if startIndex and endIndex then
        extractedItemName = string.sub(msg, startIndex + 1, endIndex - 1);
    end
    if extractedItemName ~= "" then
        if RR_AUTO_ITEMS_V1[extractedItemName] then
            RR_AUTO_ITEMS_V1[extractedItemName] = nil;
            RoundRobinhood.PrintAutoMessage("Removed [" .. extractedItemName .. "] from auto-roll list.");
        else
            RoundRobinhood.PrintAutoMessage("Item [" .. extractedItemName .. "] not found in auto-roll list.");
        end
    else
        RoundRobinhood.PrintColor("Usage: /rrh auto remove [Item Name]");
    end
end

-- Handles '/rrh auto on' command.
-- Enables the auto-roll functionality.
function RoundRobinhood.HandleAutoOnCommand()
    RR_SETTINGS_V1.autoRollEnabled = true;
    RoundRobinhood.PrintColor("Auto-roll functionality has been enabled.");
end

-- Handles '/rrh auto off' command.
-- Disables the auto-roll functionality.
function RoundRobinhood.HandleAutoOffCommand()
    RR_SETTINGS_V1.autoRollEnabled = false;
    RoundRobinhood.PrintColor("Auto-roll functionality has been disabled.");
end

-- Dispatch table for auto-roll related commands.
RoundRobinhood.autoCommandHandlers = {
    ["mute"] = RoundRobinhood.HandleAutoMuteCommand,
    ["list"] = RoundRobinhood.HandleAutoListCommand,
    ["set"] = RoundRobinhood.HandleAutoSetCommand,
    ["remove"] = RoundRobinhood.HandleAutoRemoveCommand,
    ["on"] = RoundRobinhood.HandleAutoOnCommand,
    ["off"] = RoundRobinhood.HandleAutoOffCommand,
};

-- Handles '/rrh auto ...' commands.
-- Dispatches to specific auto-roll command handlers.
function RoundRobinhood.HandleAutoCommand(commandlist, msg)
    local action2 = commandlist[2];
    local handler = RoundRobinhood.autoCommandHandlers[action2];

    if handler then
        handler(commandlist, msg);
    else
        RoundRobinhood.PrintColor("Unknown command for '/rrh auto'.");
        RoundRobinhood.Print("Try: /rrh auto list, set, remove, mute, on, off.");
    end
end

-- Handles '/rrh share' command.
-- Shares addon information and a link to the GitHub repository.
function RoundRobinhood.HandleShareCommand()
    local version = GetAddOnMetadata("RoundRobinhood", "Version") or "Unknown";
    local message = "Thanks for using RoundRobinhood v" .. version .. " https://github.com/ZenSociety/RoundRobinhood";
    RoundRobinhood.SendMsg(message);
end

-- Handles '/rrh test1' command.
-- Test function 1: Outputs counts for "Righteous Orb" as if a roll occurred.
function RoundRobinhood.HandleTest3Command()
    RoundRobinhood.PrintColor("Current RR_RECORDS_ITEMS_V1 content:");
    for itemName, players in pairs(RR_RECORDS_ITEMS_V1) do
        RoundRobinhood.Print("  Item: " .. itemName);
        for playerName, count in pairs(players) do
            RoundRobinhood.Print("    " .. playerName .. ": " .. count);
        end
    end
end

-- Dispatch table for slash commands.
-- Maps command strings to their respective handler functions.
RoundRobinhood.commandHandlers = {
    ["send"] = function(cmdlist, msg) RoundRobinhood.HandleItemDisplayCommand(cmdlist, "send") end,
    ["reset"] = RoundRobinhood.HandleResetCommand,
    ["set"] = RoundRobinhood.HandleSetCommand,
    ["item"] = RoundRobinhood.HandleItemCommand,
    ["mute"] = RoundRobinhood.HandleMuteCommand,
    ["auto"] = RoundRobinhood.HandleAutoCommand,
    ["share"] = RoundRobinhood.HandleShareCommand,
    ["test3"] = RoundRobinhood.HandleTest3Command,
};

-- Main slash command function for /rrh.
-- Parses user input and calls the appropriate handler function.
function RoundRobinhood.SlashCommand(msg)
    local commandlist = {};
    -- Split the input message into individual commands/arguments.
    for command in string.gfind(msg, "[^ ]+") do
        table.insert(commandlist, string.lower(command));
    end;

    local action = commandlist[1]; -- The primary command (e.g., "show", "reset").

    if msg == "" then
        RoundRobinhood_ToggleUI();
        return;
    end;

    local handler = RoundRobinhood.commandHandlers[action];

    if handler then
        handler(commandlist, msg);
    else
        RoundRobinhood.PrintColor("Unknown command.");
        RoundRobinhood.Print("Try: /rrh show, send, item, reset, set, mute, auto, share.");
    end;
end;

SlashCmdList.ROUNDROBINHOOD = RoundRobinhood.SlashCommand;
