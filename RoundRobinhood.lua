RRFrame = CreateFrame("Frame", "RoundRobinFrame", WorldFrame);
RRFrame:RegisterEvent("START_LOOT_ROLL");
RRFrame:RegisterEvent("CHAT_MSG_LOOT");
RRFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
local isMute = false;
local channelToSent = "SAY";
local gfind = string.gmatch or string.gfind;
local DEFAULT_RR_ITEMS = {
	["Righteous Orb"] = {
		WarrCroc = 99,
		MageCroc = 98,
		LockCroc = 97
	},
	["Arcane Essence"] = {
		WarrCroc = 96,
		MageCroc = 95
	},
	["Overcharged Ley Energy"] = {
		WarrCroc = 94
	}
};
local function Print(msg)
	if not DEFAULT_CHAT_FRAME then
		return;
	end;
	DEFAULT_CHAT_FRAME:AddMessage(msg);
end;
local function PrintColor(msg)
	local r, g, b = 0.96, 0.55, 0.73;
	local hexColor = string.format("|cFF%02X%02X%02X", r * 255, g * 255, b * 255);
	Print(hexColor .. msg);
end;
local function CountKeys(t)
	local count = 0;
	for _ in pairs(t) do
		count = count + 1;
	end;
	return count;
end;
local function SendMsg(msg)
	if isMute then
		return;
	end;
	if channelToSent == "SAY" then
		Print(msg);
	else
		SendChatMessage(msg, channelToSent);
	end;
end;
local function CheckVariableExpiration()
	local specificTimestamp = RR_TIMESTAMP;
	local currentTimestamp = time();
	local difference = currentTimestamp - specificTimestamp;
	if difference >= 86400 then
		RR_TIMESTAMP = currentTimestamp;
		for itemName in pairs(RR_ITEMS) do
			RR_ITEMS[itemName] = {};
		end;
	end;
end;
local function GetMembersNames()
	local currNames = {};
	local currnumPartyMembers = GetNumPartyMembers();
	local currnumRaidMembers = GetNumRaidMembers();
	local myName;
	if currnumRaidMembers ~= 0 then
		channelToSent = "RAID";
		for i = 1, 40 do
			local name = UnitName("raid" .. i);
			if name then
				table.insert(currNames, name);
			end;
		end;
	elseif currnumPartyMembers ~= 0 then
		channelToSent = "PARTY";
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
		channelToSent = "SAY";
		myName = UnitName("player");
		if myName then
			table.insert(currNames, myName);
		end;
	end;
	table.sort(currNames);
	return currNames;
end;
local function OutputCountsByItem(itemName, method)
	local currPlayerNames = GetMembersNames();
	local msgCurrentResult = {};
	for _, currName in ipairs(currPlayerNames) do
		if not RR_ITEMS[itemName][currName] then
			RR_ITEMS[itemName][currName] = 0;
		end;
		table.insert(msgCurrentResult, currName .. " " .. RR_ITEMS[itemName][currName]);
	end;
	local textTemp1 = "";
	local textTemp2 = table.concat(msgCurrentResult, ", ");
	if method == "roll" then
		textTemp1 = "[" .. itemName .. "] dropped! Currently:";
		SendMsg(textTemp1);
		SendMsg(textTemp2);
	elseif method == "won" then
		SendMsg(textTemp2);
	elseif method == "show" then
		textTemp1 = "[" .. itemName .. "] currently:";
		PrintColor(textTemp1);
		Print(textTemp2);
	elseif method == "send" then
		textTemp1 = "[" .. itemName .. "] results are:";
		SendMsg(textTemp1);
		SendMsg(textTemp2);
	end;
end;
local function PrintItems()
	local itemNames = {};
	for itemName in pairs(RR_ITEMS) do
		table.insert(itemNames, itemName);
	end;
	for index, name in ipairs(itemNames) do
		Print(index .. ". [" .. name .. "]");
	end;
end;
local function StartRollHandler(rollID)
	if not RR_ITEMS then
		RR_ITEMS = DEFAULT_RR_ITEMS;
	end;
	local itemLink = GetLootRollItemLink(rollID);
	if not itemLink then
		return;
	end;
	local texture, name, count = GetLootRollItemInfo(rollID);
	for itemName, players in pairs(RR_ITEMS) do
		if itemName == name then
			OutputCountsByItem(itemName, "roll");
			break;
		end;
	end;
end;
local function LootResultHandler(msg)
	if channelToSent == "SAY" or strfind(msg, "Roll -") then
		return;
	end;
	for itemName in pairs(RR_ITEMS) do
		if strfind(msg, itemName) and strfind(msg, "won: ") then
			local startIndex, endIndex = string.find(msg, " won: ");
			if startIndex then
				local winnerName = string.sub(msg, 1, startIndex - 1);
				if winnerName == "You" then
					winnerName = UnitName("player");
				end;
				local msg1 = winnerName .. " won: [" .. itemName .. "]";
				SendMsg(msg1);
				if RR_ITEMS[itemName][winnerName] then
					RR_ITEMS[itemName][winnerName] = RR_ITEMS[itemName][winnerName] + 1;
				else
					RR_ITEMS[itemName][winnerName] = 1;
				end;
				OutputCountsByItem(itemName, "won");
			else
				Print("'won:' not found.");
			end;
		end;
	end;
end;
local function OnEventFunc()
	if event == "START_LOOT_ROLL" then
		StartRollHandler(arg1);
	elseif event == "CHAT_MSG_LOOT" then
		LootResultHandler(arg1);
	elseif event == "PLAYER_ENTERING_WORLD" then
		if not RR_TIMESTAMP then
			RR_TIMESTAMP = 1640966400;
		else
			CheckVariableExpiration();
		end;
	end;
end;
local function AboutRR()
	Print("You are running:");
	PrintColor("RoundRobinhood Version 1.0");
end;
RRFrame:SetScript("OnEvent", OnEventFunc);
SLASH_ROUNDROBINHOOD1 = "/rrh";
SlashCmdList.ROUNDROBINHOOD = function(msg)
	if not RR_ITEMS then
		RR_ITEMS = DEFAULT_RR_ITEMS;
	end;
	local commandlist = {};
	for command in gfind(msg, "[^ ]+") do
		table.insert(commandlist, string.lower(command));
	end;
	local action = commandlist[1];
	if action == "show" then
		local action2 = commandlist[2];
		local itemNames = {};
		for itemName in pairs(RR_ITEMS) do
			table.insert(itemNames, itemName);
		end;
		if not action2 then
			local msg1 = "Incorrect input. please try like: '/rrh show 1'";
			PrintColor(msg1);
			for index, name in ipairs(itemNames) do
				Print(index .. ". [" .. name .. "]");
			end;
		elseif itemNames[tonumber(action2)] then
			OutputCountsByItem(itemNames[tonumber(action2)], "show");
		else
			local msg2 = "The number you input: " .. action2 .. ", is not found.";
			Print(msg2);
		end;
	elseif action == "send" then
		local action2 = commandlist[2];
		local itemNames = {};
		for itemName in pairs(RR_ITEMS) do
			table.insert(itemNames, itemName);
		end;
		if not tonumber(action2) then
			local msg1 = "Incorrect input. please try like: '/rrh send 1'";
			PrintColor(msg1);
			for index, name in ipairs(itemNames) do
				Print(index .. ". [" .. name .. "]");
			end;
		elseif itemNames[tonumber(action2)] then
			OutputCountsByItem(itemNames[tonumber(action2)], "send");
		else
			local msg2 = "The number you input: " .. action2 .. ", is not found.";
			Print(msg2);
		end;
	elseif action == "reset" then
		local action2 = commandlist[2];
		local itemNames = {};
		for itemName in pairs(RR_ITEMS) do
			table.insert(itemNames, itemName);
		end;
		local lengthTemp = CountKeys(RR_ITEMS);
		if not action2 then
			local msg1 = "Incorrect input. please try like: '/rrh reset 1'";
			PrintColor(msg1);
			for index, name in ipairs(itemNames) do
				Print(index .. ". [" .. name .. "]");
			end;
			Print(lengthTemp + 1 .. ". ALL");
		else
			local numAction2 = tonumber(action2);
			if not itemNames[numAction2] then
				for index, name in ipairs(itemNames) do
					RR_ITEMS[name] = {};
				end;
				PrintColor("All items records has been reset. try checking by '/rrh show'");
			else
				RR_ITEMS[itemNames[numAction2]] = {};
				PrintColor(itemNames[numAction2] .. " has been reset. try checking by '/rrh show'");
			end;
		end;
	elseif action == "set" then
		local action2 = commandlist[2];
		local action3 = commandlist[3];
		local action4 = commandlist[4];
		local action5 = commandlist[5];
		local itemNames = {};
		local msgItems = {};
		local msgPlayers = {};
		for itemName in pairs(RR_ITEMS) do
			table.insert(itemNames, itemName);
		end;
		for index, name in ipairs(itemNames) do
			table.insert(msgItems, "[" .. index .. "]" .. " " .. name);
		end;
		local textItems = table.concat(msgItems, ", ");
		local currPlayerNames = GetMembersNames();
		for index, name in ipairs(currPlayerNames) do
			table.insert(msgPlayers, "[" .. index .. "]" .. " " .. name);
		end;
		local textPlayers = table.concat(msgPlayers, ", ");
		local pName = currPlayerNames[tonumber(action2)];
		local iName = itemNames[tonumber(action3)];
		if action2 and action3 and action4 and tonumber(action2) and tonumber(action3) and tonumber(action4) and (not action5) and iName and pName then
			local pOldNumber = RR_ITEMS[iName][pName];
			RR_ITEMS[iName][pName] = tonumber(action4);
			local myName = UnitName("player");
			local msgtemp1 = myName .. " changed " .. pName .. "'s [" .. iName .. "] from " .. pOldNumber .. " to " .. tonumber(action4) .. ".";
			SendMsg(msgtemp1);
			OutputCountsByItem(iName, "send");
		else
			local text1 = "Incorrect input. please try like: '/rrh set 2 1 3' Which means set [2nd player] [1st item] into [3].";
			PrintColor(text1);
			Print("Player: " .. textPlayers);
			Print("Item: " .. textItems);
		end;
	elseif action == "item" then
		local text1 = "To add a new item, the input must contain square brackets, Like: '/rrh item add [Righteous Orb]'";
		local text2 = "To remove an item, the input must contain square brackets, Like: '/rrh item remove [Righteous Orb]'";
		local text3 = "Incorrect input. please try: '/rrh item add' or '/rrh item remove' ";
		local action2 = commandlist[2];
		local extractedItemName = "";
		local startIndex, endIndex = string.find(msg, "%[(.+)%]");
		if action2 == "add" then
			if startIndex and endIndex then
				extractedItemName = string.sub(msg, startIndex + 1, endIndex - 1);
				RR_ITEMS[extractedItemName] = {};
				PrintColor("New Item Added: [" .. extractedItemName .. "]");
			else
				PrintColor(text1);
			end;
		elseif action2 == "remove" then
			if startIndex and endIndex then
				extractedItemName = string.sub(msg, startIndex + 1, endIndex - 1);
				if RR_ITEMS[extractedItemName] then
					RR_ITEMS[extractedItemName] = nil;
					PrintColor("Item [" .. extractedItemName .. "] Removed");
				else
					Print("Item [" .. extractedItemName .. "] Not Found.");
				end;
			else
				PrintColor(text2);
			end;
		else
			PrintColor(text3);
		end;
		PrintItems();
	elseif action == "mute" then
		isMute = true;
		PrintColor("RoundRobinood Muted.");
	elseif action == "unmute" then
		isMute = false;
		PrintColor("RoundRobinood Unmuted.");
	elseif action == "about" then
		AboutRR();
	elseif action == "test1" then
		channelToSent = "RAID";
		OutputCountsByItem("Righteous Orb", "roll");
	elseif action == "test2" then
		channelToSent = "RAID";
		LootResultHandler("Croc won: [Righteous Orb]");
	elseif action == "test3" then
	else
		PrintColor("Unknown command.");
		Print("Try: /rrh show, send, item, reset, set, mute, unmute, about.");
	end;
end;
