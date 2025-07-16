-- RoundRobinhood_UI.lua
-- Handles the UI logic, adopting the Rabuffs native panel style.

local _G = _G or getfenv();

RoundRobinhood_UI = {};



-- A table to hold references to our UI elements for easy access.
local UI = {};

function RoundRobinhood_UI_OnLoad(self)
    -- Populate the UI table with references.
    UI.frame = self;
    UI.title = getglobal(self:GetName() .. "TitleText");
    UI.tabs = {};
    UI.contents = {};

    -- Handle Tab 1 (RR) specifically with its new global name
    UI.tabs[1] = getglobal(self:GetName() .. "Tab1");
    UI.contents[1] = RoundRobinhood_TabRR_Content;

    -- Handle Tab 2 (AUTO) specifically with its new global name
    UI.tabs[2] = getglobal(self:GetName() .. "Tab2");
    UI.contents[2] = RoundRobinhood_TabAuto_Content;

    -- Handle Tab 3 (General) specifically with its new global name
    UI.tabs[3] = getglobal(self:GetName() .. "Tab3");
    UI.contents[3] = RoundRobinhood_TabGeneral_Content;
    UI.tabs[4] = getglobal(self:GetName() .. "Tab4");
    UI.contents[4] = RoundRobinhood_TabAbout_Content;

    -- Set the text for our tabs
    UI.tabs[1]:SetText("Records");
    UI.tabs[2]:SetText("AUTO");
    UI.tabs[3]:SetText("General");
    UI.tabs[4]:SetText("About");

    -- Set the main frame title
    local version = GetAddOnMetadata("RoundRobinhood", "Version") or "";
    if version ~= "" then
        version = " v" .. version;
    end
    UI.title:SetText("RoundRobinhood" .. version);

    -- Register with the PanelTemplates system
    PanelTemplates_SetNumTabs(self, 4);
    PanelTemplates_UpdateTabs(self);
    tinsert(UISpecialFrames, self:GetName());
end

function RoundRobinhood_UI_OnShow()
    -- On show, select the last used tab, or default to 1.
    local lastTab = RR_SETTINGS_V1 and RR_SETTINGS_V1.lastTab or 2;
    RoundRobinhood_SelectTab(lastTab);

    -- Initialize data-dependent UI elements
    RRH_RR_Initialize_Dropdown();

    -- Update button states
    RRH_RR_UpdateMuteButton();
    RRH_Auto_UpdateStartButton();
    RRH_Auto_UpdateMuteButton();

    -- Ensure the correct sub-tab is displayed when the UI is shown.
end

-- Our custom function to handle which content panel to show.
function RoundRobinhood_SelectTab(tabIndex)
    -- Update the selectedTab property on the frame itself
    UI.frame.selectedTab = tabIndex;

    -- Use the PanelTemplates system to correctly update the visual state of all tabs.
    PanelTemplates_SetTab(UI.frame, tabIndex);

    -- Then, manually hide/show the correct content frame.
    for i = 1, 4 do
        if UI.contents[i] then
            UI.contents[i]:Hide();
        end
    end

    if UI.contents[tabIndex] then
        UI.contents[tabIndex]:Show();
    end
end

-- Function to toggle the main frame's visibility.
function RoundRobinhood_ToggleUI()
    if (UI.frame and UI.frame:IsVisible()) then
        UI.frame:Hide();
    elseif (UI.frame) then
        UI.frame:Show();
    end
end
