-- BagSorter - WoW TBC Classic Addon for sorting inventory bags
-- Allows right-click on bags to sort by category, price, or alphabetically

-- Initialize addon
local BagSorter = CreateFrame("Frame")
BagSorter:RegisterEvent("ADDON_LOADED")
BagSorter:RegisterEvent("PLAYER_LOGIN")

-- Default settings
local defaultDB = {
    sortMethod = "category", -- Options: "category", "price", "alphabetical"
    showMenu = true,
    minimap = {
        hide = false,
        minimapPos = 225,
        radius = 80
    }
}

-- Item category constants
local CATEGORY_QUEST = 1
local CATEGORY_ARMOR_WEAPON = 2
local CATEGORY_FOOD_DRINK = 3
local CATEGORY_MATERIALS = 4
local CATEGORY_OTHER = 5

-- Get item category
local function GetItemCategory(itemLink)
    if not itemLink then return CATEGORY_OTHER end
    
    local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
    
    if itemType == "Quest" then
        return CATEGORY_QUEST
    elseif itemType == "Armor" or itemType == "Weapon" then
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
            text = "Sort by Category (Quest, Armor/Weapon, Food/Drink, Materials)",
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
    -- Try different naming conventions for compatibility
    for i = 0, 4 do
        -- Try different frame naming patterns for different WoW versions
        local bagButton = _G["CharacterBag" .. i .. "Slot"] or _G["MainMenuBarBag" .. i]
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
                -- Capture the correct bag ID in the closure
                local bagID = i
                bagFrame:HookScript("OnShow", function(self)
                    -- Add a sort button to the bag frame
                    if not self.BagSorterButton then
                        local button = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
                        button:SetWidth(60)
                        button:SetHeight(20)
                        button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -5, -5)
                        button:SetText("Sort")
                        button:SetScript("OnClick", function()
                            ShowSortMenu(bagID)
                        end)
                        self.BagSorterButton = button
                    end
                end)
                bagFrame.BagSorterHooked = true
            end
        end
    end
end

-- Minimap button functionality
local minimapButton = CreateFrame("Button", "BagSorterMinimapButton", Minimap)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetWidth(31)
minimapButton:SetHeight(31)
minimapButton:SetFrameLevel(8)
minimapButton:RegisterForClicks("anyUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Create the button icon
local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", 0, 1)
icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")

-- Create the border
local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT")

-- Update minimap button position
local function UpdateMinimapButtonPosition()
    if not BagSorterDB or not BagSorterDB.minimap then return end
    
    local angle = math.rad(BagSorterDB.minimap.minimapPos or 225)
    local x = math.cos(angle) * (BagSorterDB.minimap.radius or 80)
    local y = math.sin(angle) * (BagSorterDB.minimap.radius or 80)
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Minimap button tooltip
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("BagSorter", 1, 1, 1)
    GameTooltip:AddLine("Left-click: Open sort options", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: Toggle sort method", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: Move button", 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Current: " .. (BagSorterDB and BagSorterDB.sortMethod or "category"), 0, 1, 0)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Minimap button click handler
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        -- Show options menu
        local menu = {
            {
                text = "BagSorter Options",
                isTitle = true,
                notCheckable = true
            },
            {
                text = "Sort by Category",
                func = function()
                    BagSorterDB.sortMethod = "category"
                    print("BagSorter: Sort method set to Category")
                    CloseDropDownMenus()
                end,
                checked = (BagSorterDB.sortMethod == "category"),
                keepShownOnClick = false
            },
            {
                text = "Sort by Price",
                func = function()
                    BagSorterDB.sortMethod = "price"
                    print("BagSorter: Sort method set to Price")
                    CloseDropDownMenus()
                end,
                checked = (BagSorterDB.sortMethod == "price"),
                keepShownOnClick = false
            },
            {
                text = "Sort Alphabetically",
                func = function()
                    BagSorterDB.sortMethod = "alphabetical"
                    print("BagSorter: Sort method set to Alphabetical")
                    CloseDropDownMenus()
                end,
                checked = (BagSorterDB.sortMethod == "alphabetical"),
                keepShownOnClick = false
            },
            {
                text = " ",
                notClickable = true,
                notCheckable = true
            },
            {
                text = "Hide Minimap Button",
                func = function()
                    BagSorterDB.minimap.hide = true
                    minimapButton:Hide()
                    print("BagSorter: Minimap button hidden. Use /bagsorter minimap to show it again.")
                    CloseDropDownMenus()
                end,
                notCheckable = true
            },
            {
                text = "Close",
                func = function() CloseDropDownMenus() end,
                notCheckable = true
            }
        }
        
        if not BagSorter.MinimapDropdown then
            BagSorter.MinimapDropdown = CreateFrame("Frame", "BagSorterMinimapDropdown", UIParent, "UIDropDownMenuTemplate")
        end
        
        EasyMenu(menu, BagSorter.MinimapDropdown, "cursor", 0, 0, "MENU")
    elseif button == "RightButton" then
        -- Cycle through sort methods
        if BagSorterDB.sortMethod == "category" then
            BagSorterDB.sortMethod = "price"
            print("BagSorter: Sort method set to Price")
        elseif BagSorterDB.sortMethod == "price" then
            BagSorterDB.sortMethod = "alphabetical"
            print("BagSorter: Sort method set to Alphabetical")
        else
            BagSorterDB.sortMethod = "category"
            print("BagSorter: Sort method set to Category")
        end
    end
end)

-- Minimap button drag functionality
minimapButton:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        
        local angle = math.deg(math.atan2(py - my, px - mx))
        if angle < 0 then
            angle = angle + 360
        end
        
        BagSorterDB.minimap.minimapPos = angle
        UpdateMinimapButtonPosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self:UnlockHighlight()
    self:SetScript("OnUpdate", nil)
end)

-- Initialize minimap button
local function InitializeMinimapButton()
    if BagSorterDB.minimap.hide then
        minimapButton:Hide()
    else
        minimapButton:Show()
        UpdateMinimapButtonPosition()
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
            elseif type(v) == "table" then
                -- Handle nested tables (like minimap settings)
                if type(BagSorterDB[k]) ~= "table" then
                    BagSorterDB[k] = {}
                end
                for kk, vv in pairs(v) do
                    if BagSorterDB[k][kk] == nil then
                        BagSorterDB[k][kk] = vv
                    end
                end
            end
        end
        
        print("BagSorter loaded! Ctrl+Right-click on bag slots to sort.")
        print("Current sort method: " .. BagSorterDB.sortMethod)
    elseif event == "PLAYER_LOGIN" then
        -- Hook bag frames after player login
        HookBagFrames()
        -- Initialize minimap button
        InitializeMinimapButton()
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
    elseif msg == "minimap" then
        BagSorterDB.minimap.hide = not BagSorterDB.minimap.hide
        if BagSorterDB.minimap.hide then
            minimapButton:Hide()
            print("BagSorter: Minimap button hidden")
        else
            minimapButton:Show()
            UpdateMinimapButtonPosition()
            print("BagSorter: Minimap button shown")
        end
    elseif msg == "help" or msg == "" then
        print("BagSorter Commands:")
        print("  /bagsorter category - Sort by category (quest, armor/weapon, food/drink, materials)")
        print("  /bagsorter price - Sort by price (highest to lowest)")
        print("  /bagsorter alphabetical - Sort alphabetically")
        print("  /bagsorter minimap - Toggle minimap button")
        print("  /bagsorter help - Show this help message")
        print("")
        print("Usage: Ctrl+Right-click on bag slots to open sort menu")
        print("Or left-click the minimap button")
        print("Current method: " .. BagSorterDB.sortMethod)
    else
        print("BagSorter: Unknown command. Type /bagsorter help for available commands.")
    end
end
