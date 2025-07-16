local _G = _G or getfenv();
RoundRobinhood_UI = RoundRobinhood_UI or {};

function RoundRobinhood_UI.SelectAboutSubTab(id)
    PanelTemplates_SetTab(RoundRobinhood_TabAbout_Content, id);

    local textWidget = RoundRobinhood_About_Text;
    if id == 1 then
        textWidget:SetText(RoundRobinhood_L.ABOUT_AUTHOR_TEXT);
    elseif id == 2 then
        textWidget:SetText(RoundRobinhood_L.ABOUT_COMMANDS_TEXT);
    end
    RoundRobinhood_About_ScrollFrame:UpdateScrollChildRect();
end

function RoundRobinhood_UI.TabAbout_OnLoad(frame)
    PanelTemplates_SetNumTabs(frame, 2);
    frame.selectedTab = 1;
    PanelTemplates_UpdateTabs(frame);

    RoundRobinhood_TabAbout_ContentTab1:SetText("Author");
    RoundRobinhood_TabAbout_ContentTab2:SetText("Commands");

    RoundRobinhood_UI.SelectAboutSubTab(frame.selectedTab);
end