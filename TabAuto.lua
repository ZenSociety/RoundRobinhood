--[[-----------------------------------------------------------------------------
    TabAuto.lua

    This file handles the logic for the "Auto" tab in the RoundRobinhood addon.
    It manages:
    - A list of items and their associated auto-roll settings.
    - A dynamic scrollable list to display these items.
    - A pop-up frame for adding, editing, and removing items from the list.
-------------------------------------------------------------------------------]]

-- Use the global RR_AUTO_ITEMS_V1 table as the data source.
-- Ensure it exists if it hasn't been loaded yet.
RR_AUTO_ITEMS_V1 = RR_AUTO_ITEMS_V1 or {}

-- A map to convert roll choice values to their string representations.
local RRH_Auto_RollChoices_Map = {
    [0] = "Pass",
    [1] = "Need",
    [2] = "Greed",
    [4] = "Round Robin",
    [5] = "Manual",
}

-- A table to define the special items and their fixed sort order.
local RRH_Auto_SpecialSort = {
    ["Purple Items"] = 1,
    ["Blue Items"] = 2,
    ["Green Items"] = 3,
}

-- The number of frames to create for the scrollable list (the frame pool size).
local RRH_Auto_BarList_Count = 20;
-- The index of the currently selected bar for editing.
local RRH_Auto_MenuBar = 0; -- 0 means nothing selected, -1 means adding new
-- A temporary table to hold the keys of the RR_AUTO_ITEMS table for ordered display.
local RRH_Auto_BarList_Keys = {};

-- Custom sort function for the auto-roll list.
function RRH_Auto_SortFunction(a, b)
    local a_is_special = RRH_Auto_SpecialSort[a];
    local b_is_special = RRH_Auto_SpecialSort[b];

    if a_is_special and b_is_special then
        -- Both are special, sort by their predefined order.
        return a_is_special < b_is_special;
    elseif a_is_special then
        -- Only a is special, it comes first.
        return true;
    elseif b_is_special then
        -- Only b is special, it comes first.
        return false;
    else
        -- Neither is special, sort alphabetically.
        return a < b;
    end
end

function RRH_Auto_StartButton_OnClick()
    if RR_SETTINGS_V1.autoRollEnabled then
        RoundRobinhood.HandleAutoOffCommand();
    else
        RoundRobinhood.HandleAutoOnCommand();
    end
    RRH_Auto_UpdateStartButton();
end

function RRH_Auto_UpdateStartButton()
    if RR_SETTINGS_V1.autoRollEnabled then
        RoundRobinhood_TabAuto_ContentStartButton:SetText("Stop");
    else
        RoundRobinhood_TabAuto_ContentStartButton:SetText("Start");
    end
end

function RRH_Auto_MuteButton_OnClick()
    RoundRobinhood.HandleAutoMuteCommand();
    RRH_Auto_UpdateMuteButton();
end

function RRH_Auto_UpdateMuteButton()
    if RR_SETTINGS_V1.muteAutoNotification then
        RoundRobinhood_TabAuto_ContentMuteButton:SetText("Unmute");
    else
        RoundRobinhood_TabAuto_ContentMuteButton:SetText("Mute");
    end
end

-- OnLoad handler for the Auto tab.
function RRH_Auto_Tab_OnLoad(self)
    -- Set header text and disable it so it acts as a label.
    local header = RRH_Auto_Settings_BarLine0;
    RRH_Auto_Settings_BarLine0Name:SetText("Item Name");
    RRH_Auto_Settings_BarLine0Position:SetText("Auto Roll");
    RRH_Auto_Settings_BarLine0Name:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    RRH_Auto_Settings_BarLine0Position:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    header:Disable();

    -- Create and position the pool of frames for the scrollable list.
    -- This is done only once to improve performance.
    for i = 1, RRH_Auto_BarList_Count do
        local barLine = CreateFrame("BUTTON", "RRH_Auto_Settings_BarLine" .. i, RoundRobinhood_TabAuto_Content,
            "RRH_Auto_Settings_BarLine");
        barLine:SetID(i);
        if i == 1 then
            barLine:SetPoint("TOPLEFT", RRH_Auto_Settings_BarLine0, "BOTTOMLEFT", 0, -2);
        else
            barLine:SetPoint("TOPLEFT", getglobal("RRH_Auto_Settings_BarLine" .. (i - 1)), "BOTTOMLEFT", 0, 0);
        end
    end
end

-- Updates the content of the scrollable list.
function RRH_Auto_Settings_Layout_Update()
    -- Clear and rebuild the key list.
    RRH_Auto_BarList_Keys = {};
    for k, _ in pairs(RR_AUTO_ITEMS_V1) do
        table.insert(RRH_Auto_BarList_Keys, k);
    end

    -- Apply the custom sorting logic.
    table.sort(RRH_Auto_BarList_Keys, RRH_Auto_SortFunction);

    local scrollFrame = RRH_Auto_Settings_LayoutScrollBar;
    local offset = FauxScrollFrame_GetOffset(scrollFrame);
    local totalItems = table.getn(RRH_Auto_BarList_Keys);

    -- Update the scroll bar to reflect the total number of items.
    FauxScrollFrame_Update(scrollFrame, totalItems, RRH_Auto_BarList_Count, 16);

    -- Update the visible frames with the correct data.
    for i = 1, RRH_Auto_BarList_Count do
        local lineIndex = offset + i;
        local barLine = getglobal("RRH_Auto_Settings_BarLine" .. i);

        if lineIndex <= totalItems then
            local key = RRH_Auto_BarList_Keys[lineIndex];
            local value = RR_AUTO_ITEMS_V1[key];
            
            -- Truncate long item names.
            local nameFontString = getglobal(barLine:GetName() .. "Name");
            if string.len(key) > 30 then
                nameFontString:SetText(string.sub(key, 1, 30) .. "...");
            else
                nameFontString:SetText(key);
            end

            getglobal(barLine:GetName() .. "Position"):SetText(RRH_Auto_RollChoices_Map[value]);
            barLine:SetID(lineIndex); -- Set the ID to the actual data index for selection.
            barLine:Show();
        else
            barLine:Hide();
        end
    end
end

-- OnScroll handler for the scroll frame.
function RRH_Auto_Settings_Layout_OnScroll(self, arg1)
    FauxScrollFrame_OnVerticalScroll(16, RRH_Auto_Settings_Layout_Update);
end

-- OnShow handler for the scroll frame.
function RRH_Auto_Settings_Layout_OnShow(self)
    RRH_Auto_Settings_Layout_Update();
end

-- Handles clicks on the list items and the "Add" button.
function RRH_Auto_Settings_Layout_SelectBar(id)
    if id == 20 then -- A hardcoded ID for the "Add" button.
        RRH_Auto_MenuBar = -1;
        RRH_Auto_BarDetail_Header:SetText("Add Bar");
        RRH_Auto_BarDetail_ItemName:Hide();
        RRH_Auto_BarDetail_LabelEditBox:Show();
        RRH_Auto_BarDetail_LabelEditBox:SetText("");
        UIDropDownMenu_SetSelectedValue(RRH_Auto_BarDetail_OutputTarget, 5); -- Default to "Manual"
        UIDropDownMenu_SetText(RRH_Auto_RollChoices_Map[5], RRH_Auto_BarDetail_OutputTarget);
        RRH_Auto_BarDetail_Remove:Hide();
    else
        RRH_Auto_MenuBar = id; -- Use the actual data index from the list.
        local key = RRH_Auto_BarList_Keys[id];
        local value = RR_AUTO_ITEMS_V1[key];
        RRH_Auto_BarDetail_Header:SetText("Edit Bar");
        RRH_Auto_BarDetail_ItemName:SetText(key);
        RRH_Auto_BarDetail_ItemName:Show();
        RRH_Auto_BarDetail_LabelEditBox:Hide();
        UIDropDownMenu_SetSelectedValue(RRH_Auto_BarDetail_OutputTarget, value);
        UIDropDownMenu_SetText(RRH_Auto_RollChoices_Map[value], RRH_Auto_BarDetail_OutputTarget);

        -- Hide the remove button for special items, otherwise show it.
        if RRH_Auto_SpecialSort[key] then
            RRH_Auto_BarDetail_Remove:Hide();
        else
            RRH_Auto_BarDetail_Remove:Show();
        end
    end
    RRH_Auto_BarDetailFrame:Show();
end

-- Logic for the detail/edit frame.

-- Handles the "Save" button click.
function RRH_Auto_BarDetail_Accept()
    local output = UIDropDownMenu_GetSelectedValue(RRH_Auto_BarDetail_OutputTarget);

    if RRH_Auto_MenuBar == -1 then -- Adding a new bar
        local newItemName = RRH_Auto_BarDetail_LabelEditBox:GetText();
        if newItemName and newItemName ~= "" then
            RR_AUTO_ITEMS_V1[newItemName] = output;
        end
    else -- Editing existing bar
        local key = RRH_Auto_BarList_Keys[RRH_Auto_MenuBar];
        RR_AUTO_ITEMS_V1[key] = output;
    end
    RRH_Auto_Settings_Layout_Update();
end

-- Handles the "Remove" button click.
function RRH_Auto_BarDetail_RemoveBar()
    if RRH_Auto_MenuBar > 0 then
        local key = RRH_Auto_BarList_Keys[RRH_Auto_MenuBar];
        RR_AUTO_ITEMS_V1[key] = nil;
        RRH_Auto_Settings_Layout_Update();
    end
end

-- Logic for the roll choice dropdown menu.

function RRH_Auto_BarDetail_OutputTarget_OnLoad(self)
    UIDropDownMenu_Initialize(self, RRH_Auto_BarDetail_OutputTarget_Initialize);
    UIDropDownMenu_SetWidth(125, self);
end

function RRH_Auto_BarDetail_OutputTarget_Initialize()
    -- Use an ordered table to ensure dropdown items appear in a consistent order.
    local orderedChoices = {
        { text = "Pass",        value = 0 },
        { text = "Need",        value = 1 },
        { text = "Greed",       value = 2 },
        { text = "Round Robin", value = 4 },
        { text = "Manual",      value = 5 },
    }

    for _, choiceData in ipairs(orderedChoices) do
        local info = {};
        info.text = choiceData.text;
        info.value = choiceData.value;
        info.func = RRH_Auto_BarDetail_OutputTarget_OnClick;
        UIDropDownMenu_AddButton(info);
    end
end

function RRH_Auto_BarDetail_OutputTarget_OnClick()
    UIDropDownMenu_SetSelectedValue(RRH_Auto_BarDetail_OutputTarget, this.value);
    ToggleDropDownMenu(1, nil, RRH_Auto_BarDetail_OutputTarget);
end