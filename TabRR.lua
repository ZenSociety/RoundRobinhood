--[[-----------------------------------------------------------------------------
    TabRR.lua

    This file handles the logic for the "RR" (Round Robin) tab.
    It manages:
    - A dropdown to select a tracked item.
    - A list of players and their counts for the selected item.
-------------------------------------------------------------------------------]]

-- Ensure the global data table exists.
RR_RECORDS_ITEMS_V1 = RR_RECORDS_ITEMS_V1 or {}

-- The number of frames to create for the player list.
local RRH_RR_PlayerList_Count = 8;
-- The currently selected item from the dropdown.
local RRH_RR_SelectedItem = nil;
-- A temporary table to hold the keys (player names) for the selected item.
local RRH_RR_PlayerList_Keys = {};

-- Handler for the Mute/Unmute button.
function RRH_RR_MuteButton_OnClick()
    RoundRobinhood.HandleMuteCommand();
    RRH_RR_UpdateMuteButton();
end

-- Updates the text of the Mute/Unmute button based on the current setting.
function RRH_RR_UpdateMuteButton()
    if RR_SETTINGS_V1.isMute then
        RoundRobinhood_TabRR_ContentMuteButton:SetText("Unmute");
    else
        RoundRobinhood_TabRR_ContentMuteButton:SetText("Mute");
    end
end

function RRH_RR_ResetButton_OnClick()
    if not RRH_RR_SelectedItem then
        RoundRobinhood.PrintColor("The item list is empty. Please click the 'Add' button to add an item first.");
        return;
    end
    RoundRobinhood.HandleResetCommand();
    RRH_RR_PlayerList_Update();
end

function RRH_RR_DeleteButton_OnClick()
    if not RRH_RR_SelectedItem then
        RoundRobinhood.PrintColor("The item list is empty. Please click the 'Add' button to add an item first.");
        return;
    end
    -- Hide the add item frame if it's open
    RRH_RR_AddItemFrame:Hide();

    -- Set the confirmation text dynamically
    RRH_RR_DeleteItemFrameSubText:SetText("Delete [" .. RRH_RR_SelectedItem .. "] ?");

    -- Show the confirmation dialog
    RRH_RR_DeleteItemFrame:Show();
end

-- This function is called when the user confirms the deletion
function RRH_RR_DeleteItem_Confirm()
    if not RRH_RR_SelectedItem then
        -- This should not happen if the delete button was clicked correctly, but as a safeguard
        return;
    end

    local commandlist = { "item", "remove" };
    local msg = "item remove [" .. RRH_RR_SelectedItem .. "]";
    RoundRobinhood.HandleItemCommand(commandlist, msg);

    local newItemToSelect = nil;
    for itemName, _ in pairs(RR_RECORDS_ITEMS_V1) do
        newItemToSelect = itemName;
        break;
    end

    RRH_RR_SelectedItem = newItemToSelect;

    UIDropDownMenu_Initialize(RRH_RR_ItemDropdown, RRH_RR_ItemDropdown_Initialize);
    if RRH_RR_SelectedItem then
        UIDropDownMenu_SetSelectedValue(RRH_RR_ItemDropdown, RRH_RR_SelectedItem);
        UIDropDownMenu_SetText(RRH_RR_SelectedItem, RRH_RR_ItemDropdown);
    else
        UIDropDownMenu_SetText("No items", RRH_RR_ItemDropdown);
    end

    RRH_RR_PlayerList_Update();
end

function RRH_RR_SendButton_OnClick()
    if not RRH_RR_SelectedItem then
        RoundRobinhood.PrintColor("The item list is empty. Please click the 'Add' button to add an item first.");
        return;
    end
    RoundRobinhood.OutputCountsByItem(RRH_RR_SelectedItem, "send");
end

function RRH_RR_AddButton_OnClick()
    -- Hide the delete confirmation frame if it's open
    RRH_RR_DeleteItemFrame:Hide();
    RRH_RR_AddItemFrameInputBox:SetText("");
    RRH_RR_AddItemFrame:Show();
end

function RRH_RR_AddItem_Save()
    local newItemName = RRH_RR_AddItemFrameInputBox:GetText();

    -- Remove brackets as requested
    if newItemName then
        newItemName = string.gsub(newItemName, "%[", "");
        newItemName = string.gsub(newItemName, "%]", "");
    end

    if newItemName and newItemName ~= "" then
        local commandlist = { "item", "add" };
        local msg = "item add [" .. newItemName .. "]";
        RoundRobinhood.HandleItemCommand(commandlist, msg);

        -- Refresh the UI after adding
        RRH_RR_Initialize_Dropdown();
    end
end

-- OnLoad handler for the RR tab.
function RRH_RR_Tab_OnLoad(self)
    -- Create the pool of frames for the scrollable player list.
    -- This is a one-time setup and does not depend on saved variables.
    for i = 1, RRH_RR_PlayerList_Count do
        local playerLine = CreateFrame("BUTTON", "RRH_RR_PlayerLine" .. i, RoundRobinhood_TabRR_Content,
            "RRH_RR_PlayerLine");
        playerLine:SetID(i);
        if i == 1 then
            playerLine:SetPoint("TOPLEFT", RRH_RR_ItemDropdown, "BOTTOMLEFT", -25, -10);
        else
            playerLine:SetPoint("TOPLEFT", getglobal("RRH_RR_PlayerLine" .. (i - 1)), "BOTTOMLEFT", 0, 0);
        end
    end
end

-- Initializes the dropdown menu with the correct default item.
-- This should be called from OnShow to ensure RR_ITEMS is loaded.
function RRH_RR_Initialize_Dropdown()
    local selectedItemWithData = nil;
    local firstAvailableItem = nil;

    if RR_RECORDS_ITEMS_V1 then
        -- First pass: find an item with player data
        for itemName, players in pairs(RR_RECORDS_ITEMS_V1) do
            if firstAvailableItem == nil then -- Capture the very first item as a fallback
                firstAvailableItem = itemName;
            end

            local hasData = false;
            for _ in pairs(players) do
                hasData = true;
                break;
            end

            if hasData then
                selectedItemWithData = itemName;
                break; -- Found our preferred item, stop searching
            end
        end
    end

    -- Prioritize item with data, otherwise use the first available one
    RRH_RR_SelectedItem = selectedItemWithData or firstAvailableItem;

    -- Re-populate the dropdown choices every time
    UIDropDownMenu_Initialize(RRH_RR_ItemDropdown, RRH_RR_ItemDropdown_Initialize);

    -- Update the dropdown's appearance based on the selection.
    if RRH_RR_SelectedItem then
        UIDropDownMenu_SetSelectedValue(RRH_RR_ItemDropdown, RRH_RR_SelectedItem);
        UIDropDownMenu_SetText(RRH_RR_SelectedItem, RRH_RR_ItemDropdown);
    else
        UIDropDownMenu_SetText("No items", RRH_RR_ItemDropdown);
    end

    -- Refresh the player list based on the (new) selection
    RRH_RR_PlayerList_Update();
end

-- Updates the player list based on the selected item.
function RRH_RR_PlayerList_Update()
    if not RRH_RR_SelectedItem or not RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem] then
        for i = 1, RRH_RR_PlayerList_Count do
            local playerLine = getglobal("RRH_RR_PlayerLine" .. i);
            if playerLine then
                playerLine:Hide();
            end
        end
        RRH_RR_PlayerListScrollFrame:Hide();
        return;
    end

    RRH_RR_PlayerListScrollFrame:Show();

    -- Clear and rebuild the player list keys.
    RRH_RR_PlayerList_Keys = {};
    for k, _ in pairs(RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem]) do
        table.insert(RRH_RR_PlayerList_Keys, k);
    end
    table.sort(RRH_RR_PlayerList_Keys);

    local scrollFrame = RRH_RR_PlayerListScrollFrame;
    local offset = FauxScrollFrame_GetOffset(scrollFrame);
    local totalItems = table.getn(RRH_RR_PlayerList_Keys);

    FauxScrollFrame_Update(scrollFrame, totalItems, RRH_RR_PlayerList_Count, 32);

    for i = 1, RRH_RR_PlayerList_Count do
        local lineIndex = offset + i;
        local playerLine = getglobal("RRH_RR_PlayerLine" .. i);

        if lineIndex <= totalItems then
            local playerName = RRH_RR_PlayerList_Keys[lineIndex];
            local itemCount = RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem][playerName];
            getglobal(playerLine:GetName() .. "Name"):SetText(playerName);
            getglobal(playerLine:GetName() .. "Count"):SetText(itemCount);
            playerLine:SetID(lineIndex);
            playerLine:Show();
        else
            playerLine:Hide();
        end
    end
end

-- OnScroll handler for the player list.
function RRH_RR_PlayerList_OnScroll(self, arg1)
    FauxScrollFrame_OnVerticalScroll(32, RRH_RR_PlayerList_Update);
end

-- OnShow handler for the player list.
function RRH_RR_PlayerList_OnShow(self)
    RRH_RR_PlayerList_Update();
end

-- Increments the item count for a player.
function RRH_RR_IncrementPlayerCount(playerIndex)
    if not RRH_RR_SelectedItem or not RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem] then return; end

    local playerName = RRH_RR_PlayerList_Keys[playerIndex];
    if playerName and RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem][playerName] then
        RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem][playerName] = RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem][playerName] + 1;
        RRH_RR_PlayerList_Update();
    end
end

-- Decrements the item count for a player, ensuring it doesn't go below zero.
function RRH_RR_DecrementPlayerCount(playerIndex)
    if not RRH_RR_SelectedItem or not RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem] then return; end

    local playerName = RRH_RR_PlayerList_Keys[playerIndex];
    if playerName and RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem][playerName] then
        local currentCount = RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem][playerName];
        if currentCount > 0 then
            RR_RECORDS_ITEMS_V1[RRH_RR_SelectedItem][playerName] = currentCount - 1;
            RRH_RR_PlayerList_Update();
        end
    end
end

-- Logic for the item selection dropdown.

function RRH_RR_ItemDropdown_OnLoad(self)
    UIDropDownMenu_Initialize(self, RRH_RR_ItemDropdown_Initialize);
    UIDropDownMenu_SetWidth(150, self);
end

function RRH_RR_ItemDropdown_Initialize()
    local info = {};
    for itemName, _ in pairs(RR_RECORDS_ITEMS_V1) do
        info.text = itemName;
        info.value = itemName;
        info.func = RRH_RR_ItemDropdown_OnClick;
        info.checked = (itemName == RRH_RR_SelectedItem);
        UIDropDownMenu_AddButton(info);
    end
end

function RRH_RR_ItemDropdown_OnClick()
    RRH_RR_SelectedItem = this.value;
    UIDropDownMenu_SetSelectedValue(RRH_RR_ItemDropdown, this.value);
    RRH_RR_PlayerList_Update();
end
