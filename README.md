# RoundRobinhood

## Description
**RoundRobinhood** is a simple WoW v1.12 addon designed to track round-robin loot distribution among party and raid members. It helps players keep track of item counts and ensures fair distribution during loot rolls.

## Features
- Tracks item counts for a specified target item.
- Automatically resets counts when party or raid members change.
- Sends messages to the group or raid chat to inform players of item counts and distribution.
- Supports commands for managing item counts and settings.

![preview](https://raw.githubusercontent.com/ZenSociety/ProjectImagesVault/refs/heads/main/rr1.png)

## Installation (Vanilla, 1.12)
1. Download **[Latest Version](https://github.com/ZenSociety/RoundRobinhood/archive/master.zip)**
2. Unpack the Zip file
3. Rename the folder "RoundRobinhood-main" to "RoundRobinhood"
4. Copy "RoundRobinhood" into Wow-Directory\Interface\AddOns
5. Restart WoW game client.

## Commands
Use the following commands in the chat to interact with the addon:

- `/rrh show`: Displays the current item counts for the player.
- `/rrh send`: Sends the current item counts to the group chat.
- `/rrh reset`: Resets the item counts for all players.
- `/rrh set <counts>`: Updates item counts based on the provided input (e.g., `/rrh set 3,2,2,2,2`).
- `/rrh item [Item Name]`: Sets the target item for tracking (e.g., `/rrh item [Righteous Orb]`).
- `/rrh mute`: Mutes the addon, pausing item tracking.
- `/rrh unmute`: Unmutes the addon, resuming item tracking.
- `/rrh test`: Tests the addon functionality with a simple message.

## Saved Variables
The addon saves item counts per character, allowing you to maintain your progress across sessions.

## Author
**Croc**

## Version
**0.01**

## Date
**Created in 2024**

## License
This addon is released under the MIT License.

## Support
For issues or feature requests, please open an issue on the [GitHub repository](https://github.com/ZenSociety/RoundRobinhood/issues) or contact the author directly.

## Acknowledgments
Thanks to the Turtle WoW Team.
