# BagSorter - WoW TBC Classic Anniversary Edition Addon

A World of Warcraft: The Burning Crusade Classic Anniversary Edition addon that allows you to sort your inventory bags by right-clicking on them.

## Features

- **Right-click sorting**: Ctrl+Right-click on bag slots to open the sort menu
- **Multiple sorting methods**:
  - **Category**: Groups items by type (Quest, Armor/Weapon, Food/Drink, Materials, Other)
  - **Price**: Sorts items by vendor price (highest to lowest)
  - **Alphabetical**: Sorts items alphabetically by name
- **Persistent settings**: Your preferred sort method is saved between sessions
- **Easy access**: Sort buttons appear on bag frames when opened
- **Slash commands**: Quick commands to change sort methods

## Installation

1. Download or clone this repository
2. Copy the `BagSorter` folder to your WoW TBC Classic AddOns directory:
   - **Windows**: `C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns\`
   - **Mac**: `/Applications/World of Warcraft/_classic_/Interface/AddOns/`
3. Restart WoW or reload UI (`/reload`)
4. The addon should appear in your AddOns list at character selection

## Usage

### Method 1: Right-Click Menu
1. Hold **Ctrl** and **Right-Click** on any bag slot in your bag bar
2. Select your desired sorting method from the menu
3. The bag will be sorted according to your selection

### Method 2: Sort Button
1. Open a bag by clicking on it
2. Click the **Sort** button that appears in the top-right corner of the bag frame
3. Choose your sorting method from the menu

### Method 3: Slash Commands
Use these commands in the chat to set your default sorting method:

- `/bagsorter category` or `/bs cat` - Sort by category
- `/bagsorter price` or `/bs p` - Sort by price
- `/bagsorter alphabetical` or `/bs a` - Sort alphabetically
- `/bagsorter help` - Show help information

## Sorting Methods Explained

### Category Sort
Groups items into categories in this order:
1. **Quest**: Quest items and quest-related materials
2. **Armor/Weapon**: All armor pieces and weapons
3. **Food/Drink**: Consumable food and drinks
4. **Materials**: Trade goods, reagents, and crafting materials
5. **Other**: Everything else

Within each category, items are sorted alphabetically.

### Price Sort
Sorts all items by their vendor sell price from highest to lowest. Items with the same price are then sorted alphabetically.

### Alphabetical Sort
Sorts all items alphabetically by their name (A to Z).

## Important Notes

Due to WoW API security restrictions, the addon cannot automatically move items in your bags. Instead, it:
1. Analyzes your bag contents
2. Determines the optimal sort order
3. Displays the recommended order in the chat window

You can then manually rearrange items according to the suggested order, or use the built-in WoW bag sorting features in conjunction with this addon for best results.

## Compatibility

- **Version**: 1.0.0
- **Compatible with**: WoW TBC Classic Anniversary Edition (Interface 20504)
- **Language**: English
- **No known conflicts**: Should work with most other bag addons

## Troubleshooting

**Addon not loading?**
- Ensure the folder is named exactly `BagSorter`
- Check that both `BagSorter.toc` and `BagSorter.lua` are in the folder
- Type `/reload` in-game to reload the UI

**Sort menu not appearing?**
- Make sure you're holding **Ctrl** while right-clicking
- Try using the slash commands instead: `/bagsorter help`

**Items not moving automatically?**
- This is a WoW API limitation for security reasons
- Follow the recommended order shown in the chat window
- Consider using this addon alongside WoW's built-in cleanup button

## Credits

Created for the WoW TBC Classic Anniversary Edition community.

## License

Free to use and modify. Share with fellow adventurers!
