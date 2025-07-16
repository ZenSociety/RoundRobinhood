if (GetLocale() == "enUS") then
    RoundRobinhood_L = {
        ABOUT_COMMANDS_TEXT =
            "|cFF00FF00/rrh|r\n" ..
            "Opens the main RoundRobinhood UI window, which displays the addon's help text.\n" ..
            "|cFF808080Example: /rrh|r\n\n" ..

            "|cFF00FF00/rrh show <item_number>|r\n" ..
            "Displays the current loot counts for a specific tracked item in your chat frame. The <item_number> refers to the numerical index of the item as listed by the addon (e.g., from /rrh item list).\n" ..
            "|cFF808080Example: /rrh show 1|r (If 'Righteous Orb' is the first item in your tracked list)\n\n" ..
            "|cFF00FF00/rrh send <item_number>|r\n" ..
            "Sends the current loot counts for a specific tracked item to your current group chat (raid or party).\n" ..
            "|cFF808080Example: /rrh send 1|r\n\n" ..

            "|cFF00FF00/rrh reset|r\n" ..
            "Resets all tracked item counts for all players to zero. Use with caution.\n" ..
            "|cFF808080Example: /rrh reset|r\n\n" ..

            "|cFF00FF00/rrh set <player_index> <item_index> <count>|r\n" ..
            "Manually sets the loot count for a specific player and item. This is useful for correcting errors or manually adjusting counts.\n" ..
            "  • player_index: The numerical index of the player in your current group (e.g., 1 for the first player listed).\n" ..
            "  • item_index: The numerical index of the item (as per /rrh item list).\n" ..
            "  • count: The new count to set for that player and item.\n" ..
            "|cFF808080Example: /rrh set 2 1 3|r (Sets the 2nd player's count for the 1st item to 3)\n\n" ..
            "|cFF00FF00/rrh mute|r\n" ..
            "Toggles whether the addon sends messages to your chat frame (e.g., notifications about auto-rolls, item wins). This does not affect messages sent to group chat.\n" ..
            "|cFF808080Example: /rrh mute|r\n\n" ..

            "|cFF00FF00/rrh share|r\n" ..
            "Displays the addon's version and a link to its GitHub repository in your chat frame.\n" ..
            "|cFF808080Example: /rrh share|r\n\n" ..

            "|cFF00FF00/rrh item add [Item Name]|r\n" ..
            "Adds a new item to the addon's tracking list. The item name must be enclosed in square brackets.\n" ..
            "|cFF808080Example: /rrh item add [Righteous Orb]|r\n\n" ..

            "|cFF00FF00/rrh item remove [Item Name]|r\n" ..
            "Removes an item from the addon's tracking list. The item name must be enclosed in square brackets.\n" ..
            "|cFF808080Example: /rrh item remove [Righteous Orb]|r\n\n" ..

            "|cFF00FF00/rrh auto on|r\n" ..
            "Enables the auto-roll functionality. The addon will automatically roll on items based on your configured settings.\n" ..
            "|cFF808080Example: /rrh auto on|r\n\n" ..

            "|cFF00FF00/rrh auto off|r\n" ..
            "Disables the auto-roll functionality. The addon will no longer automatically roll on items.\n" ..
            "|cFF808080Example: /rrh auto off|r\n\n" ..

            "|cFF00FF00/rrh auto mute|r\n" ..
            "Toggles muting of auto-roll notification messages in your chat frame.\n" ..
            "|cFF808080Example: /rrh auto mute|r\n\n" ..

            "|cFF00FF00/rrh auto list|r\n" ..
            "Displays a list of all currently configured auto-roll settings for items and item qualities.\n" ..
            "|cFF808080Example: /rrh auto list|r\n\n" ..

            "|cFF00FF00/rrh auto set [Item Name] <action_code>|r\n" ..
            "Sets the auto-roll behavior for a specific item or item quality. The item name must be in square brackets.\n" ..
            "  • action_code:\n" ..
            "    • 0: Pass\n" ..
            "    • 1: Need\n" ..
            "    • 2: Greed\n" ..
            "    • 4: Round Robin (auto-decide based on lowest count)\n" ..
            "    • 5: Manual (no auto-roll for this item/quality)\n" ..
            "|cFF808080Example: /rrh auto set [Righteous Orb] 4|r (Sets auto-roll for Righteous Orb to Round Robin)\n\n" ..
            "|cFF00FF00/rrh auto remove [Item Name]|r\n" ..
            "Removes a specific item or item quality from the auto-roll settings.\n" ..
            "|cFF808080Example: /rrh auto remove [Righteous Orb]|r\n" ..
            "\n" ..
            "[End]\n.</body></html>",
        ABOUT_AUTHOR_TEXT =
        "<html><body><p>This addon was created by Croc with the help of Gemini.</p></body></html>"
    };
end
