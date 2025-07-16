# RoundRobinhood

An addon for World of Warcraft (Vanilla 1.12) to assist with Round Robin loot distribution and auto-rolling.

![RoundRobinhood](https://raw.githubusercontent.com/ZenSociety/ProjectImagesVault/refs/heads/main/v1.png)

## Features

*   **Round Robin Tracking:** Easily track who has received which items.
    *   Add/Remove items to track.
    *   Manually adjust player counts.
    *   Send current standings to party/raid chat.
    *   Reset all counts for a fresh start.
*   **Advanced Auto-Rolling:** Configure automatic rolling for specific items or item qualities.
    *   Set items to Need, Greed, Pass, or Manual.
    *   Special "Round Robin" setting automatically Needs if you have the lowest count and Passes otherwise.
    *   Enable/disable the entire auto-roll system with one click.
    *   Mute auto-roll messages to keep your chat clean.

## Installation

1.  Download the latest release of RoundRobinhood.
2.  Extract the contents into your `World of Warcraft/Interface/AddOns/` directory.
3.  Ensure the folder structure is `Interface/AddOns/RoundRobinhood/` with all the `.toc`, `.xml`, and `.lua` files directly inside.

## Usage
typing `/rrh` to open the main interface.

The interface is divided into four tabs:

### 1. Records Tab

This is where you manage the items you want to track for Round Robin distribution.

*   **Item Dropdown:** Select the item you want to view or manage.
*   **Add/Delete:** Add a new item to the list or delete the currently selected one.
*   **Player List:** Shows all players in your group/raid and their current count for the selected item. You can manually adjust counts with the `+` and `-` buttons.
*   **Mute/Unmute:** Toggles addon messages in your chat.
*   **Send:** Sends the current list for the selected item to your party/raid chat.
*   **Reset:** Resets the counts for **all** tracked items to zero.

### 2. AUTO Tab

Configure your automatic rolling preferences here.

*   **Start/Stop:** Globally enables or disables the auto-rolling feature.
*   **Mute/Unmute:** Toggles the auto-roll notification messages in chat.
*   **Add:** Add a new item or item quality to the auto-roll list.
*   **Item List:** Click on any item to edit its auto-roll setting (Need, Greed, Pass, Round Robin, or Manual).

### 3. General Tab

This tab is reserved for future features.

### 4. About Tab

Contains information about the addon, the author, and a list of all available slash commands.

## Contributing

Feel free to contribute by submitting issues or pull requests on the GitHub repository.

## License

[MIT License](LICENSE)
