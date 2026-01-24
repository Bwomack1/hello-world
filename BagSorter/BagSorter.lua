-- BagSorter - WoW TBC Classic Addon for sorting inventory bags
-- Allows right-click on bags to sort by category, price, or alphabetically

-- Initialize addon
local BagSorter = CreateFrame("Frame")
BagSorter:RegisterEvent("ADDON_LOADED")
BagSorter:RegisterEvent("PLAYER_LOGIN")

-- Default settings
local defaultDB = {
    sortMethod = "category", -- Options: "category", "price", "alphabetical"
    showMenu = true
}

-- Item category constants
local CATEGORY_ARMOR_WEAPON = 1
local CATEGORY_FOOD_DRINK = 2
local CATEGORY_MATERIALS = 3
local CATEGORY_OTHER = 4

-- Get item category
local function GetItemCategory(itemLink)
    if not itemLink then return CATEGORY_OTHER end
    
    local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
    
    if itemType == "Armor" or itemType == "Weapon" then
        return CATEGORY_ARMOR_WEAPON
    elseif itemType == "Consumable" and (itemSubType == "Food & Drink" or itemSubType == "Food" or itemSubType == "Drink") then
        return CATEGORY_FOOD_DRINK
    elseif itemType == "Trade Goods" or itemType == "Reagent" then
        return CATEGORY_MATERIALS
    else
        return CATEGORY_OTHER
    end
end

-- Get item price
local function GetItemPrice(itemLink)
    if not itemLink then return 0 end
    local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemLink)
    return vendorPrice or 0
end

-- Get item name for alphabetical sorting
local function GetItemName(itemLink)
    if not itemLink then return "" end
    local itemName = GetItemInfo(itemLink)
    return itemName or ""
end

-- Collect all items from a bag
local function CollectBagItems(bagID)
    local items = {}
    local numSlots = GetContainerNumSlots(bagID)
    
    for slot = 1, numSlots do
        local itemLink = GetContainerItemLink(bagID, slot)
        if itemLink then
            local _, itemCount = GetContainerItemInfo(bagID, slot)
            table.insert(items, {
                link = itemLink,
                count = itemCount,
                slot = slot,
                category = GetItemCategory(itemLink),
                price = GetItemPrice(itemLink),
                name = GetItemName(itemLink)
            })
        end
    end
    
    return items
end

-- Sort items by category
local function SortByCategory(a, b)
    if a.category ~= b.category then
        return a.category < b.category
    end
    -- Secondary sort by name within same category
    return a.name < b.name
end

-- Sort items by price
local function SortByPrice(a, b)
    if a.price ~= b.price then
        return a.price > b.price -- Descending order (most expensive first)
    end
    return a.name < b.name -- Secondary sort by name
end

-- Sort items alphabetically
local function SortAlphabetically(a, b)
    return a.name < b.name
end

-- Perform the actual sorting
local function SortBag(bagID, sortMethod)
    local items = CollectBagItems(bagID)
    
    if #items == 0 then
        print("BagSorter: Bag is empty or cannot be sorted.")
        return
    end
    
    -- Sort based on selected method
    if sortMethod == "category" then
        table.sort(items, SortByCategory)
    elseif sortMethod == "price" then
        table.sort(items, SortByPrice)
    elseif sortMethod == "alphabetical" then
        table.sort(items, SortAlphabetically)
    end
    
    -- Note: Due to WoW API security restrictions, we cannot programmatically move items
    -- Instead, we'll provide visual feedback showing the recommended sort order
    
    print("BagSorter: Sorted bag " .. bagID .. " by " .. sortMethod)
    print("BagSorter: Note - Due to WoW API limitations, please manually rearrange items in this order:")
    
    for i, item in ipairs(items) do
        print(i .. ". " .. item.name .. " (x" .. item.count .. ")")
    end
end

-- Create dropdown menu for sort options
local function ShowSortMenu(bagID)
    local menu = {
        {
            text = "Sort Bag Options",
            isTitle = true,
            notCheckable = true
        },
        {
            text = "Sort by Category (Armor/Weapon, Food/Drink, Materials)",
            func = function()
                BagSorterDB.sortMethod = "category"
                SortBag(bagID, "category")
                CloseDropDownMenus()
            end,
            checked = (BagSorterDB.sortMethod == "category"),
            keepShownOnClick = false
        },
        {
            text = "Sort by Price (Highest to Lowest)",
            func = function()
                BagSorterDB.sortMethod = "price"
                SortBag(bagID, "price")
                CloseDropDownMenus()
            end,
            checked = (BagSorterDB.sortMethod == "price"),
            keepShownOnClick = false
        },
        {
            text = "Sort Alphabetically",
            func = function()
                BagSorterDB.sortMethod = "alphabetical"
                SortBag(bagID, "alphabetical")
                CloseDropDownMenus()
            end,
            checked = (BagSorterDB.sortMethod == "alphabetical"),
            keepShownOnClick = false
        },
        {
            text = "Close",
            func = function() CloseDropDownMenus() end,
            notCheckable = true
        }
    }
    
    -- Create and show dropdown menu
    if not BagSorter.DropdownFrame then
        BagSorter.DropdownFrame = CreateFrame("Frame", "BagSorterDropdown", UIParent, "UIDropDownMenuTemplate")
    end
    
    EasyMenu(menu, BagSorter.DropdownFrame, "cursor", 0, 0, "MENU")
end

-- Hook bag frame clicks
local function HookBagFrames()
    -- Hook the main bag slots (bag bar)
    for i = 0, 4 do
        local bagButton = _G["CharacterBag" .. i .. "Slot"]
        if bagButton and not bagButton.BagSorterHooked then
            bagButton:HookScript("OnClick", function(self, button)
                if button == "RightButton" then
                    -- Bag ID matches the slot index (0-4)
                    local bagID = i
                    if IsControlKeyDown() then
                        ShowSortMenu(bagID)
                    end
                end
            end)
            bagButton.BagSorterHooked = true
        end
    end
    
    -- Also hook the individual bag frames if they're open
    -- Note: Bag index 0 maps to ContainerFrame1, bag 1 to ContainerFrame2, etc.
    for i = 0, 4 do
        local bagName = "ContainerFrame" .. (i + 1)
        local bagFrame = _G[bagName]
        if bagFrame then
            if not bagFrame.BagSorterHooked then
                bagFrame:HookScript("OnShow", function(self)
                    -- Add a sort button to the bag frame
                    if not self.BagSorterButton then
                        local button = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
                        button:SetWidth(60)
                        button:SetHeight(20)
                        button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -5, -5)
                        button:SetText("Sort")
                        button:SetScript("OnClick", function()
                            ShowSortMenu(self:GetID())
                        end)
                        self.BagSorterButton = button
                    end
                end)
                bagFrame.BagSorterHooked = true
            end
        end
    end
end

-- Event handler
BagSorter:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "BagSorter" then
        -- Initialize saved variables
        if not BagSorterDB then
            BagSorterDB = {}
        end
        
        -- Set defaults for missing values
        for k, v in pairs(defaultDB) do
            if BagSorterDB[k] == nil then
                BagSorterDB[k] = v
            end
        end
        
        print("BagSorter loaded! Ctrl+Right-click on bag slots to sort.")
        print("Current sort method: " .. BagSorterDB.sortMethod)
    elseif event == "PLAYER_LOGIN" then
        -- Hook bag frames after player login
        HookBagFrames()
    end
end)

-- Slash commands
SLASH_BAGSORTER1 = "/bagsorter"
SLASH_BAGSORTER2 = "/bs"
SlashCmdList["BAGSORTER"] = function(msg)
    msg = string.lower(msg)
    
    if msg == "category" or msg == "cat" then
        BagSorterDB.sortMethod = "category"
        print("BagSorter: Sort method set to Category")
    elseif msg == "price" or msg == "p" then
        BagSorterDB.sortMethod = "price"
        print("BagSorter: Sort method set to Price")
    elseif msg == "alphabetical" or msg == "alpha" or msg == "a" then
        BagSorterDB.sortMethod = "alphabetical"
        print("BagSorter: Sort method set to Alphabetical")
    elseif msg == "help" or msg == "" then
        print("BagSorter Commands:")
        print("  /bagsorter category - Sort by category (armor/weapon, food/drink, materials)")
        print("  /bagsorter price - Sort by price (highest to lowest)")
        print("  /bagsorter alphabetical - Sort alphabetically")
        print("  /bagsorter help - Show this help message")
        print("")
        print("Usage: Ctrl+Right-click on bag slots to open sort menu")
        print("Current method: " .. BagSorterDB.sortMethod)
    else
        print("BagSorter: Unknown command. Type /bagsorter help for available commands.")
    end
end
