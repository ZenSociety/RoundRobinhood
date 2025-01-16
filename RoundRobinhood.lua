RRFrame = CreateFrame("Frame", "RoundRobinFrame", WorldFrame);
RRFrame:RegisterEvent("CHAT_MSG_LOOT");
RRFrame:RegisterEvent("START_LOOT_ROLL");
RRFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
RRFrame:RegisterEvent("RAID_ROSTER_UPDATE");
local targetItemName = "";
local playerItems = {};
local isMute = false;
local flagSay = false;
local channelToSent = "SAY";
local numPartyMembers = 0;
local numRaidMembers = 0;
local gfind = string.gmatch or string.gfind;
local function Print(msg)
	if not DEFAULT_CHAT_FRAME then
		return;
	end;
	DEFAULT_CHAT_FRAME:AddMessage(msg);
end;
local function sendCurrItemCount(receiver)
	local sortedPlayerItems = {};
	for name, data in pairs(playerItems) do
		table.insert(sortedPlayerItems, {
			name = name,
			data = data
		});
	end;
	table.sort(sortedPlayerItems, function(a, b)
		return a.data.unitIndex < b.data.unitIndex;
	end);
	local messageParts = {};
	for _, playerData in ipairs(sortedPlayerItems) do
		table.insert(messageParts, string.format("%s %d", playerData.name, playerData.data.count));
	end;
	local tempMsg = table.concat(messageParts, ", ");
	if receiver == "player" then
		print("You are not in a party yet. " .. tempMsg);
	elseif receiver == "group" then
		SendChatMessage(tempMsg, channelToSent);
	end;
end;
local function ResetRaid(num)
	playerItems = {};
	for i = 1, num do
		local name = UnitName("raid" .. i);
		if name then
			playerItems[name] = {
				count = 0,
				unitIndex = i
			};
		end;
	end;
	if flagSay then
		local tempMsg = "New player joined, [" .. targetItemName .. "] counts have been reset";
		SendChatMessage(tempMsg, channelToSent);
	end;
end;
local function ResetParty(num)
	playerItems = {};
	for i = 1, num do
		local name = UnitName("party" .. i);
		if name then
			playerItems[name] = {
				count = 0,
				unitIndex = i
			};
		end;
	end;
	playerItems[UnitName("player")] = {
		count = 0,
		unitIndex = num + 1
	};
	if flagSay then
		local tempMsg = "New player joined, [" .. targetItemName .. "] counts have been reset";
		SendChatMessage(tempMsg, channelToSent);
	end;
end;
local function RemoveMemberFromParty()
	local tempPlayerItems = {};
	for i = 1, numPartyMembers do
		local name = UnitName("party" .. i);
		if name and playerItems[name] then
			tempPlayerItems[name] = playerItems[name];
		end;
	end;
	local playerName = UnitName("player");
	tempPlayerItems[playerName] = playerItems[playerName];
	playerItems = tempPlayerItems;
end;
local function RemoveMemberFromRaid()
	local tempPlayerItems = {};
	for i = 1, numRaidMembers do
		local name = UnitName("raid" .. i);
		if name and playerItems[name] then
			tempPlayerItems[name] = playerItems[name];
		end;
	end;
	playerItems = tempPlayerItems;
end;
local function OnGroupChanged()
	if not RR_ITEM then
		RR_ITEM = "Righteous Orb";
	end;
	if targetItemName == "" then
		targetItemName = RR_ITEM;
	end;
	local currnumPartyMembers = GetNumPartyMembers();
	local currnumRaidMembers = GetNumRaidMembers();
	if currnumRaidMembers ~= 0 then
		channelToSent = "RAID";
		if currnumRaidMembers > numRaidMembers then
			numRaidMembers = currnumRaidMembers;
			ResetRaid(currnumRaidMembers);
		elseif currnumRaidMembers < numRaidMembers then
			numRaidMembers = currnumRaidMembers;
			RemoveMemberFromRaid();
		end;
	elseif currnumPartyMembers ~= 0 then
		channelToSent = "PARTY";
		if currnumPartyMembers > numPartyMembers then
			numPartyMembers = currnumPartyMembers;
			ResetParty(currnumPartyMembers);
		elseif currnumPartyMembers < numPartyMembers then
			numPartyMembers = currnumPartyMembers;
			RemoveMemberFromParty();
		end;
	else
		channelToSent = "SAY";
		flagSay = false;
	end;
end;
local function HandleLootRoll(rollID)
	local itemLink = GetLootRollItemLink(rollID);
	if not itemLink then
		return;
	end;
	local texture, name, count = GetLootRollItemInfo(rollID);
	if name == targetItemName and (not ismute) then
		flagSay = true;
		SendChatMessage("Before this roll:", channelToSent);
		sendCurrItemCount("group");
	end;
end;
local function HandleChatMsgLoot(msg)
	local playerName = "";
	local itemName = "";
	local itemNameBracket = "";
	local startPos, endPos = strfind(msg, " won: ");
	if startPos and endPos then
		playerName = strsub(msg, 1, startPos - 1);
		itemNameBracket = strsub(msg, endPos + 1);
		local startPos2 = strfind(itemNameBracket, "%[");
		local endPos2 = strfind(itemNameBracket, "%]");
		itemName = strsub(itemNameBracket, startPos2 + 1, endPos2 - 1);
	else
		return;
	end;
	if playerName == "You" then
		playerName = UnitName("player");
	end;
	if playerName and itemName and itemName == targetItemName then
		playerItems[playerName].count = playerItems[playerName].count + 1;
		SendChatMessage(string.format("%s won %s!", playerName, itemName), channelToSent);
		sendCurrItemCount("group");
	end;
end;
local function UpdateItemCountsFromInput(input)
	local counts = {};
	for count in gfind(input, "%d+") do
		table.insert(counts, tonumber(count));
	end;
	if channelToSent == "PARTY" then
		if table.getn(counts) ~= numPartyMembers + 1 then
			print("Error: The input does not match the number of players.");
			return false;
		end;
		local index = 1;
		for i = 1, numPartyMembers do
			local name = UnitName("party" .. i);
			if name then
				playerItems[name].count = counts[index];
				index = index + 1;
			end;
		end;
		playerItems[UnitName("player")].count = counts[index];
		return true;
	elseif channelToSent == "RAID" then
		if table.getn(counts) ~= numRaidMembers then
			print("Error: The input does not match the number of players.");
			return false;
		end;
		local index = 1;
		for i = 1, numRaidMembers do
			local name = UnitName("raid" .. i);
			if name then
				playerItems[name].count = counts[index];
				index = index + 1;
			end;
		end;
		return true;
	end;
end;
local function OnEventFunc()
	if event == "START_LOOT_ROLL" then
		HandleLootRoll(arg1);
	elseif event == "CHAT_MSG_LOOT" then
		HandleChatMsgLoot(arg1);
	elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		OnGroupChanged();
	end;
end;
local function rrtest()
	Print("Round Robin is working great.");
end;
RRFrame:SetScript("OnEvent", OnEventFunc);
SLASH_ROUNDROBINHOOD1 = "/rr";
SlashCmdList.ROUNDROBINHOOD = function(msg)
	local commandlist = {};
	for command in gfind(msg, "[^ ]+") do
		table.insert(commandlist, string.lower(command));
	end;
	local action = commandlist[1];
	if action == "show" then
		sendCurrItemCount("player");
	elseif action == "send" then
		sendCurrItemCount("group");
	elseif action == "reset" then
		local playerName = UnitName("player");
		local tempMsg = "[" .. targetItemName .. "]" .. " counts have been reset by " .. playerName;
		SendChatMessage(tempMsg, channelToSent);
		numRaidMembers = 0;
		numPartyMembers = 0;
		OnGroupChanged();
	elseif action == "set" then
		if UpdateItemCountsFromInput(commandlist[2]) then
			local playerName = UnitName("player");
			local tempMsg = "[" .. targetItemName .. "]" .. " counts have been updated by " .. playerName;
			SendChatMessage(tempMsg, channelToSent);
			sendCurrItemCount("group");
		else
			print("Invalid input. Use: '/rr set 3,2,2,2,2'. Entries should match party members.");
		end;
	elseif action == "item" then
		if not RR_ITEM then
			RR_ITEM = "Righteous Orb";
		end;
		local extractedWord = string.match(msg, "%[(.-)%]");
		if extractedWord then
			targetItemName = extractedWord;
			RR_ITEM = extractedWord;
			print("Item is updated: " .. RR_ITEM);
		else
			print("Item currently is: " .. RR_ITEM);
			print("To change it, the input must contain square brackets i.e. /rr item [Righteous Orb].");
		end;
	elseif action == "mute" then
		isMute = true;
		print("RoundRobin program started.");
	elseif action == "unmute" then
		isMute = false;
		print("RoundRobin program paused.");
	elseif action == "test" then
		rrtest();
	else
		print("Unknown command. Try: /rr show, send, reset, set, mute, unmute.");
	end;
end;
