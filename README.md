# RoundRobinhood

## Description
**RoundRobinhood** is a simple WoW v1.12 addon designed to track round-robin loot distribution among party and raid members. It helps players keep track of item counts and ensures fair distribution during loot rolls.

## Features
- Tracks item counts for a specified target item.
- Automatically resets counts when party or raid members change.
- Sends messages to the group or raid chat to inform players of item counts and distribution.
- Supports commands for managing item counts and settings.

## Installation
1. Download the latest version of the addon.
2. Extract the contents of the zip file.
3. Place the `RoundRobinhood` folder into your WoW `/Interface/AddOns/` directory.
4. Launch WoW and enable the addon in the AddOns menu.

## Commands
Use the following commands in the chat to interact with the addon:

- `/rr show`: Displays the current item counts for the player.
- `/rr send`: Sends the current item counts to the group chat.
- `/rr reset`: Resets the item counts for all players.
- `/rr set <counts>`: Updates item counts based on the provided input (e.g., `/rr set 3,2,2,2,2`).
- `/rr item [Item Name]`: Sets the target item for tracking (e.g., `/rr item [Righteous Orb]`).
- `/rr mute`: Mutes the addon, pausing item tracking.
- `/rr unmute`: Unmutes the addon, resuming item tracking.
- `/rr test`: Tests the addon functionality with a simple message.

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
For issues or feature requests, please open an issue on the [GitHub repository](https://github.com/Croc/RoundRobinhood/issues) or contact the author directly.

## Acknowledgments
Thanks to the Turtle WoW Team.
