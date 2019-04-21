RoleplayFinder = {
    name = "RoleplayFinder",
    version = "1.0",
    author = "Tactitocalon",
    color = "DDFFEE", -- Used in menu titles and so on.
    menuName = "Roleplay Finder", -- A UNIQUE identifier for menu object.

    protocolVersion = 1,

    -- Default settings.
    savedVariables = {
        FirstLoad = true
    },
}

local COLOR_OOC_HEADER = "|cFF6666"
local COLOR_IC_HEADER = "|c66FF66"
local COLOR_LOCATION_HEADER = "|cFFFFFF"

local ENCODE_CHARSET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/!"$%()^&*-_=+:;{}.?<>,@&~`[]'
local ENCODE_CHARSET_LENGTH = string.len(ENCODE_CHARSET)

local function encodeNumber(number, encodeLength)
    encodeLength = encodeLength or 1

    local t = {}
    repeat
        local d = (number % ENCODE_CHARSET_LENGTH) + 1
        number = math.floor(number / ENCODE_CHARSET_LENGTH)
        table.insert(t, 1, ENCODE_CHARSET:sub(d, d))
    until number == 0

    local encodedNumber = table.concat(t, "")

    if (string.len(encodedNumber) > encodeLength) then
        -- TODO: Log this correctly, then throw an error.
        d("Encoded length " .. string.len(encodedNumber) .. " exceeds encodeLength of " .. encodeLength .. ".")
    end
    while string.len(encodedNumber) < encodeLength do
        encodedNumber = ENCODE_CHARSET:sub(1, 1) .. encodedNumber
    end

    return encodedNumber
end

local function decodeNumber(encodedNumber)
    local number = 0
    local length = string.len(encodedNumber)
    for i = 1, length do
        local symbol = encodedNumber:sub(i, i)
        local index = string.find(ENCODE_CHARSET, symbol, 1, true) - 1

        number = number + (index * math.pow(ENCODE_CHARSET_LENGTH, length - i))
    end
    return number
end

-- TODO debug remove me later
ENCODE = encodeNumber
DECODE = decodeNumber

function RoleplayFinder.isRoleplayFinderGuild(guildName)
    -- TODO: make this a configurable list of guild names
    return guildName == "Roleplay Finder"
end

function RoleplayFinder.setGuildNote(note)
    -- Find all guilds that are registered for Roleplay Finder capabilities.
    local displayName = GetDisplayName()

    for i = 1, 5 do
        local guildName = GetGuildName(i)
        if (RoleplayFinder.isRoleplayFinderGuild(guildName)) then
            -- Check permission for note editing; if not available, show an error.
            -- TODO
            local memberIndex = GetGuildMemberIndexFromDisplayName(i, displayName)

            SetGuildMemberNote(i, memberIndex, note)
        end
    end
end

-- Converts a note into a Notedata object, or nil if the note cannot be converted.
function RoleplayFinder.convertNoteToNotedata(note)
    local function convertNoteToNotedata(note)
        local notedata = {
            inCharacter = nil,
            protocolVersion = nil,
            shortBio = "",
            locationId = 0,
            population = 0,
            checksum = nil
        }

        -- S1: checksum
        -- TODO: validate, if not valid, abort

        -- S2: IC/OOC flag (bit 1), protocol version (remainder)
        local s2 = decodeNumber(note:sub(2, 2))
        notedata.inCharacter = BIT.bit32.band(s2, 0x00000001)
        if (notedata.inCharacter == 0) then
            notedata.inCharacter = false
        else
            notedata.inCharacter = true
        end
        notedata.protocolVersion = BIT.bit32.rshift(s2, 1)

        -- S3_4: location ID (0 if public zone, 1 if unknown homestead, 2+ for registered locations)
        local s3_4 = decodeNumber(note:sub(3, 4))
        notedata.locationId = s3_4

        -- S5: population data
        local s5 = decodeNumber(note:sub(5, 5))
        notedata.population = s5

        -- S6+: short biography
        local s6p = note:sub(6, string.len(note))
        notedata.shortBio = s6p

        return notedata
    end

    local status, notedata = pcall(convertNoteToNotedata, note)
    if (status) then
        return notedata
    else
        return nil
    end
end

function RoleplayFinder.convertNotedataToNote(notedata)
    local note = ""

    -- S2: IC/OOC flag (bit 1), protocol version (remainder)
    local s2 = notedata.protocolVersion
    s2 = BIT.bit32.lshift(s2, 1)
    s2 = s2 + (notedata.inCharacter and 1 or 0)
    note = note .. encodeNumber(s2, 1)

    -- S3_4: location ID (0 if public zone, 1 if unknown homestead, 2+ for registered locations)
    note = note .. encodeNumber(notedata.locationId, 2)

    -- S5: population data
    note = note .. encodeNumber(notedata.population, 1)

    -- S6+: short biography
    note = note .. notedata.shortBio

    -- S1: checksum
    note = "D" .. note
    -- TODO: compute checksum using CRC32

    return note
end

function RoleplayFinder.updateNotedata()
    -- TODO: Eventually might want to implement a throttle here, to prevent the user from accidentally spamming.

    local notedata = {
        inCharacter = nil,
        protocolVersion = nil,
        shortBio = "",
        locationId = 0,
        population = 0,
        checksum = nil
    }

    -- TODO: read inCharacter flag from... somewhere
    notedata.inCharacter = true
    -- TODO: Read shortBio from somewhere too...
    notedata.shortBio = SHORTBIO

    notedata.protocolVersion = RoleplayFinder.protocolVersion

    local houseOwner = GetCurrentHouseOwner()
    local houseId = GetCurrentZoneHouseId()
    local housePopulation = GetCurrentHousePopulation()

    if (houseOwner == "") then
        notedata.locationId = 0
        notedata.population = 0
    else
        local locationData = LocationRegistry.getLocation(houseOwner, houseId)
        notedata.population = housePopulation
        if (locationData == nil) then
            -- Unknown house
            notedata.locationId = 1
        else
            -- Known house
            notedata.locationId = locationData.id
        end
    end

    RoleplayFinder.setGuildNote(RoleplayFinder.convertNotedataToNote(notedata))
end

SHORTBIO = "Talen-Chath is a very good lizard."
UPDATE = RoleplayFinder.updateNotedata

function RoleplayFinder.computeAllLocationData()
    local allLocationData = {}

    for guildId = 1, 5 do
        local guildName = GetGuildName(guildId)
        if (RoleplayFinder.isRoleplayFinderGuild(guildName)) then
            local memberCount, _, _, _ = GetGuildInfo(guildId)

            for memberIndex = 1, memberCount do
                local _, note, _, playerStatus, _ = GetGuildMemberInfo(guildId, memberIndex)
                if (playerStatus ~= PLAYER_STATUS_OFFLINE) then
                    local notedata = RoleplayFinder.convertNoteToNotedata(note)
                    if (notedata ~= nil) then
                        if (allLocationData[notedata.locationId] == nil) then
                            allLocationData[notedata.locationId] = {
                                population = notedata.population
                            }
                        end

                        local locationData = allLocationData[notedata.locationId]
                        if (locationData.population < notedata.population) then
                            locationData.population = notedata.population
                        end
                    end
                end
            end
        end
    end

    return allLocationData
end

function RoleplayFinder.printAllLocationData()
    local allLocationData = RoleplayFinder.computeAllLocationData()
    for locationId, locationData in pairs(allLocationData) do
        local location = LocationRegistry.getLocationById(locationId)
        if (location ~= nil) then
            d(COLOR_LOCATION_HEADER .. location.houseName .. " (" .. locationData.population .. "/" .. location.populationCap .. ")|r")
        end
    end
end

function TACTITEST()
    RoleplayFinder.printAllLocationData()
end

function RoleplayFinder.computeDisplayText(notedata)
    local notetext = ""
    if (notedata.inCharacter == true) then
        notetext = notetext .. COLOR_IC_HEADER .. "In Character" .. "|r"
    else
        notetext = notetext .. COLOR_OOC_HEADER .. "Out Of Character" .. "|r"
    end

    local location = LocationRegistry.getLocationById(notedata.locationId)
    if (location ~= nil) then
        notetext = notetext .. "\n" .. COLOR_LOCATION_HEADER .. location.houseName .. " (" .. notedata.population .. "/" .. location.populationCap .. ")|r"
    end

    if (notedata.shortBio ~= "") then
        notetext = notetext .. "\n\n" .. notedata.shortBio
    end

    return notetext
end

--[[
-- Only show the loading message on first load ever.
function RoleplayFinder.Activated(e)
    EVENT_MANAGER:UnregisterForEvent(RoleplayFinder.name, EVENT_PLAYER_ACTIVATED)

    if RoleplayFinder.savedVariables.FirstLoad then
        RoleplayFinder.savedVariables.FirstLoad = fal   wdse
    end
end
-- When player is ready, after everything has been loaded.
EVENT_MANAGER:RegisterForEvent(RoleplayFinder.name, EVENT_PLAYER_ACTIVATED, RoleplayFinder.Activated)
]] --

local function ShowContextMenu()
    ClearMenu()
    AddMenuItem("Set to In Character", function()
        d("a")
    end)
    AddMenuItem("Set to Out of Character", function()
        d("a")
    end)
    AddMenuItem("View Homestead Directory", function()
        -- TODO: Eventually show a nice GUI with a list of homesteads.
        RoleplayFinder.printAllLocationData()
    end)
    ShowMenu()
end

local myList = ZO_SortFilterList:Subclass()

function myList:New(control)
    ZO_SortFilterList.InitializeSortFilterList(self, control)

    -- tiebreaker  is used when values are equal. You can also add isNumeric = true if needed.
    local sorterKeys =
    {
        ["name"] = {tiebreaker = "population"},
        ["location"] = {tiebreaker = "population"},
        ["faction"] = {tiebreaker = "population"},
        ["population"] = {isNumeric = true},
    }

    self.masterList = {}
    ZO_ScrollList_AddDataType(self.list, 1, "HomesteadDirectoryRowTemplate", 32, function(control, data) self:SetupEntry(control, data) end) -- Add my row
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight") -- Enable the highlight (the turquoise color)
    self.currentSortKey = "population" -- defaut sort

    self.sortFunction = function(listEntry1, listEntry2) return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, sorterKeys, self.currentSortOrder) end -- my sort function
    self:SetAlternateRowBackgrounds(true) -- Alternate background, one dark, one grey

    return self

end

function myList:SetupEntry(control, data)
    -- Setup a row
    control.data = data
    control.name = GetControl(control, "Name")
    control.location = GetControl(control, "Location")
    control.faction = GetControl(control, "Faction")
    control.population = GetControl(control, "Population")

    control.name:SetText(data.name)
    control.location:SetText("Bleaker's Outpost")
    control.faction:SetText("Everyone buy AD")
    control.population:SetText("42")

    d("setting up entry")

    ZO_SortFilterList.SetupRow(self, control, data)
end

function myList:BuildMasterList()
    self.masterList = {}
    -- TODO: Read a list from somewhere and copy it into masterList
    table.insert(self.masterList, { name = "lol", location = "Bleaker's Outpost" })
    table.insert(self.masterList, { name = "xds" })
    table.insert(self.masterList, { name = "lolxas" })
    table.insert(self.masterList, { name = "v" })
end

function myList:SortScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    table.sort(scrollData, self.sortFunction)
end

function myList:FilterScrollList()
    -- If you want to add a filter
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for i = 1, #self.masterList do
        local data = self.masterList[i]
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
    end
end

function RoleplayFinder.OnAddOnLoaded(event, addonName)
    if addonName ~= RoleplayFinder.name then return end
    EVENT_MANAGER:UnregisterForEvent(RoleplayFinder.name, EVENT_ADD_ON_LOADED)

    RoleplayFinder.savedVariables = ZO_SavedVars:New("RoleplayFinderSavedVariables", 1, nil, RoleplayFinder.savedVariables)

    -- Settings menu in Settings.lua.
    RoleplayFinder.LoadSettings()

    -- Create the IC/OOC toggle button.

    local buttonControl = WINDOW_MANAGER:CreateControl("buttonControl", ZO_ChatWindow, CT_BUTTON)
    buttonControl:SetAnchor(TOPLEFT, ZO_ChatWindowOptions, TOPLEFT, -32, 0)
    buttonControl:SetDimensions(32, 32)
    buttonControl:SetNormalTexture('/EsoUI/Art/ChatWindow/chat_options_up.dds')
    buttonControl:SetMouseOverTexture('/esoui/art/buttons/closebutton_mouseover.dds')
    buttonControl:SetHandler("OnClicked", ShowContextMenu)
    buttonControl:SetState(BSTATE_NORMAL)

    -- TODO: hook to update my notedata on location change
    -- TODO: hook to update my notedata on population change
    EVENT_MANAGER:RegisterForEvent(RoleplayFinder.name, EVENT_PLAYER_ACTIVATED, RoleplayFinder.updateNotedata)
    EVENT_MANAGER:RegisterForEvent(RoleplayFinder.name, EVENT_HOUSING_POPULATION_CHANGED, RoleplayFinder.updateNotedata)

    -- TODO: test code
    SLASH_COMMANDS["/tt"] = function()
        HomesteadDirectoryWindow:SetHidden(not HomesteadDirectoryWindow:IsHidden())
    end
    myList:New(HomesteadDirectoryWindow)
    myList:RefreshData()
end

-- When any addon is loaded, but before UI (Chat) is loaded.
EVENT_MANAGER:RegisterForEvent(RoleplayFinder.name, EVENT_ADD_ON_LOADED, RoleplayFinder.OnAddOnLoaded)