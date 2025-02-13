RRFrame = CreateFrame("Frame", "RoundRobinFrame", WorldFrame);
RRFrame:RegisterEvent("START_LOOT_ROLL");
RRFrame:RegisterEvent("CHAT_MSG_LOOT");
local targetItemName = "";
local playerItems = {};
local playerName = "";
local tbGroupRollChoices = {};
local isMute = false;
local channelToSent = "SAY";
local gfind = string.gmatch or string.gfind;
local function Print(msg)
	if not DEFAULT_CHAT_FRAME then
		return;
	end;
	DEFAULT_CHAT_FRAME:AddMessage(msg);
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
local function SendGroupCount(des)
	if isMute then
		return;
	end;
	groupCountResult = "";
	for name, count in pairs(playerItems) do
		local memberCountResult = name .. " " .. count .. ", ";
		groupCountResult = groupCountResult .. memberCountResult;
	end;
	groupCountResult = string.sub(groupCountResult, 1, -3);
	if des == "members" then
		SendMsg(groupCountResult);
	elseif des == "player" then
		Print(groupCountResult);
	end;
end;
local function ResetGroup()
	local currnumPartyMembers = GetNumPartyMembers();
	local currnumRaidMembers = GetNumRaidMembers();
	if channelToSent == "RAID" then
		playerItems = {};
		for i = 1, 40 do
			local name = UnitName("raid" .. i);
			if name then
				playerItems[name] = 0;
			end;
		end;
	elseif channelToSent == "PARTY" then
		playerItems = {};
		for i = 1, currnumPartyMembers do
			local name = UnitName("party" .. i);
			if name then
				playerItems[name] = 0;
			end;
		end;
		playerName = UnitName("player");
		if playerName then
			playerItems[playerName] = 0;
		end;
	else
		playerItems = {};
		playerName = UnitName("player");
		if playerName then
			playerItems[playerName] = 0;
		end;
	end;
end;
local function HandleRollBegin(rollID)
	local itemLink = GetLootRollItemLink(rollID);
	if not itemLink then
		return;
	end;
	local texture, name, count = GetLootRollItemInfo(rollID);
	if name == targetItemName then
		Print(name .. "-rollID->" .. rollID);
		SendMsg("Before this roll:");
		SendGroupCount("members");
	end;
end;
local function UpdateGroupStatus(rollID)
	if not RR_ITEM then
		RR_ITEM = "Righteous Orb";
	end;
	if targetItemName == "" then
		targetItemName = RR_ITEM;
	end;
	local currentMembers = {};
	local index = 1;
	local currnumPartyMembers = GetNumPartyMembers();
	local currnumRaidMembers = GetNumRaidMembers();
	if currnumRaidMembers ~= 0 then
		channelToSent = "RAID";
		for i = 1, 40 do
			local name = UnitName("raid" .. i);
			if name then
				currentMembers[index] = name;
				index = index + 1;
			end;
		end;
	elseif currnumPartyMembers ~= 0 then
		channelToSent = "PARTY";
		for i = 1, currnumPartyMembers do
			local name = UnitName("party" .. i);
			if name then
				currentMembers[index] = name;
				index = index + 1;
			end;
		end;
		playerName = UnitName("player");
		if playerName then
			currentMembers[index] = playerName;
			index = index + 1;
		end;
	else
		channelToSent = "SAY";
		playerName = UnitName("player");
		if playerName then
			currentMembers[index] = playerName;
			index = index + 1;
		end;
	end;
	local storedMembers = {};
	local index2 = 1;
	for name, _ in pairs(playerItems) do
		storedMembers[index2] = name;
		index2 = index2 + 1;
	end;
	table.sort(currentMembers);
	table.sort(storedMembers);
	if table.getn(currentMembers) > table.getn(storedMembers) then
		Print("Group changed: Members increased from " .. table.getn(storedMembers) .. " to " .. table.getn(currentMembers));
		ResetGroup();
	elseif table.getn(currentMembers) < table.getn(storedMembers) then
		local leftMembers = {};
		for i, name in ipairs(storedMembers) do
			local found = false;
			for j, currentName in ipairs(currentMembers) do
				if name == currentName then
					found = true;
					break;
				end;
			end;
			if not found then
				table.insert(leftMembers, name);
			end;
		end;
		local leftMembersStr = table.concat(leftMembers, ", ");
		Print("Group changed: " .. leftMembersStr .. " left. Members decreased from " .. table.getn(storedMembers) .. " to " .. table.getn(currentMembers));
		for i, name in ipairs(leftMembers) do
			playerItems[name] = nil;
		end;
	end;
	if rollID then
		HandleRollBegin(rollID);
	end;
end;
local function ProcessWinner(msg, wName)
	local winnerName = wName;
	local itemName = "";
	local itemNameBracket = "";
	local startPos, endPos = strfind(msg, " won: ");
	itemNameBracket = strsub(msg, endPos + 1);
	local startPos2 = strfind(itemNameBracket, "%[");
	local endPos2 = strfind(itemNameBracket, "%]");
	itemName = strsub(itemNameBracket, startPos2 + 1, endPos2 - 1);
	if winnerName and itemName and itemName == targetItemName then
		playerItems[winnerName] = playerItems[winnerName] + 1;
		SendMsg(string.format("%s won %s!", winnerName, itemName));
		SendGroupCount("members");
	end;
end;
local function HandleRollResult(msg)
	if channelToSent == "SAY" and (not strfind(msg, targetItemName)) or strfind(msg, "Roll -") then
		return;
	end;
	if not RR_ITEM then
		RR_ITEM = "Righteous Orb";
	end;
	if targetItemName == "" then
		targetItemName = RR_ITEM;
	end;
	playerName = UnitName("player");
	if not tbGroupRollChoices then
		tbGroupRollChoices = {};
	end;
	for name, count in pairs(playerItems) do
		local tempName = name;
		if tempName == playerName then
			tempName = "You";
		end;
		local startPos2, endPos2 = strfind(msg, tempName);
		if endPos2 then
			if strfind(msg, "Need for") then
				tbGroupRollChoices[name] = "need";
			elseif strfind(msg, "Greed for") then
				tbGroupRollChoices[name] = "greed";
			elseif strfind(msg, "passed on") then
				tbGroupRollChoices[name] = "pass";
			elseif strfind(msg, "won: ") then
				ProcessWinner(msg, name);
			end;
		end;
	end;
end;
local function UpdateItemCountsFromInput(input)
	local numGroupMembers = 0;
	if channelToSent == "PARTY" then
		numGroupMembers = GetNumPartyMembers() + 1;
	elseif channelToSent == "RAID" then
		numGroupMembers = GetNumRaidMembers();
	else
		print("Error: You are not in a group.");
		return;
	end;
	local valueTable = {};
	for value in gfind(input, "%d+") do
		table.insert(valueTable, tonumber(value));
	end;
	if table.getn(valueTable) ~= numGroupMembers then
		print("Error: The input does not match the number of players.");
		return;
	end;
	local i = 1;
	for key, _ in pairs(playerItems) do
		playerItems[key] = valueTable[i];
		i = i + 1;
	end;
	playerName = UnitName("player");
	local tempMsg = "[" .. targetItemName .. "]" .. " updated by " .. playerName .. ":";
	SendMsg(tempMsg);
	SendGroupCount("members");
end;
local function OnEventFunc()
	if event == "START_LOOT_ROLL" then
		UpdateGroupStatus(arg1);
	elseif event == "CHAT_MSG_LOOT" then
		HandleRollResult(arg1);
	end;
end;
local function rrtest()
	Print("rrtest()");
end;
RRFrame:SetScript("OnEvent", OnEventFunc);
SLASH_ROUNDROBINHOOD1 = "/rr";
SlashCmdList.ROUNDROBINHOOD = function(msg)
	UpdateGroupStatus(false);
	local commandlist = {};
	for command in gfind(msg, "[^ ]+") do
		table.insert(commandlist, string.lower(command));
	end;
	local action = commandlist[1];
	if action == "show" then
		SendGroupCount("player");
	elseif action == "send" then
		local msg = "[" .. targetItemName .. "] currently are:";
		SendMsg(msg);
		SendGroupCount("members");
	elseif action == "reset" then
		ResetGroup();
	elseif action == "set" then
		local action2 = commandlist[2];
		if not action2 then
			local msg1 = "Incorrect input. please try like this: '/rr set 3,2,2,2,2'. Entries should match party members.";
			local msg2 = "[" .. targetItemName .. "] currently are:";
			SendMsg(msg1);
			SendMsg(msg2);
			SendGroupCount("player");
		else
			UpdateItemCountsFromInput(action2);
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
		print("RoundRobinood now MUTED.");
	elseif action == "unmute" then
		isMute = false;
		print("RoundRobinood now Unmuted.");
	elseif action == "test" then
		rrtest();
	else
		print("Unknown command. Try: /rr show, send, reset, set, mute, unmute.");
	end;
end;
