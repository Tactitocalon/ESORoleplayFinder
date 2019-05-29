LocationRegistry = {
    data = {
        [2] = {
            username = "@teacupdragon",
            houseId = 23,
            houseName = "Pots' Potion Emporium",
            populationCap = 12,
            loreLocation = "Reaper's March",
            shortDesc = "A quaint little potion shop.",
            longDesc = "LONG DESCRIPTION",
            monsterPolicy = "No monsters allowed!",
            faction = "Aldmeri Dominion",
            miscDesc = "ADDITIONAL INFO",
        },
        [3] = {
            username = "@Tactitocalon",
            houseId = 20,
            houseName = "Valyndia's Home",
            populationCap = 12,
            loreLocation = "Deshaan",
            shortDesc = "A displaced maormer's home.",
            longDesc = "LONG DESCRIPTION",
            monsterPolicy = "No monsters allowed!",
            faction = "Ebonheart Pact",
            miscDesc = "ADDITIONAL INFO",
        },
        [4] = {
            username = "@Airamathea",
            houseId = 36,
            houseName = "The Crystal Fox Inn",
            populationCap = 12,
            loreLocation = "Shores of Alik'r Desert, Hammerfell",
            shortDesc = "Nestled on the shores of the Alik'r Desert.",
            longDesc = "Nestled on the shores of the Alik’r Desert. Feel free to use for RP as you wish and to bring others with you! Settings are open for ALL visitors! There is a bar and food. Cozy indoor seating around a fireplace. A stage for anyone that wishes to entertain. Scenic seating outside. Seating on the beach and fishing. Rooms for rent inside, and a lovely private room in the tower.",
            monsterPolicy = "Hidden Monsters Allowed",
            faction = "Neutral",
            miscDesc = "N/A",
        },
        [5] = {
            username = "@AONomad",
            houseId = 43,
            houseName = "Lakeside Retreat",
            populationCap = 12,
            loreLocation = "Vvardenfell, Morrowind",
            shortDesc = "",
            longDesc = "Property contains a 3-room treehouse with an additional 4th room accessible via magic portal. Top of treehouse also has access to the largest waterslide in ESO.",
            monsterPolicy = " Open Monsters Allowed",
            faction = "Ebonheart Pact",
            miscDesc = "Won 2nd place in DDA Dark Elf design challenge.",
        }
    }
}

for i = 6, 100 do
    table.insert(LocationRegistry.data, {
        username = "@Tactitocalon",
        houseId = 20,
        houseName = "Test House " .. i,
        populationCap = 12,
        loreLocation = "Somewhere",
        shortDesc = "Short description.",
        longDesc = "Long descripption.",
        monsterPolicy = "Kill them with fire.",
        faction = "Neutral",
        miscDesc = "N/A",
    })
end


for k, v in pairs(LocationRegistry.data) do
    v.id = k
end


local lookupCache = {}

function LocationRegistry.getLocationById(locationId)
    return LocationRegistry.data[locationId] or nil
end

function LocationRegistry.getLocation(houseOwner, houseId)
    local lookupString = houseOwner .. "#" .. houseId
    local lookupId = lookupCache[lookupString]

    if (lookupId == nil) then
        -- Linear search through registry, cache the ID when we find it.
        for locationId, locationData in pairs(LocationRegistry.data) do
            if (locationData.username == houseOwner and locationData.houseId == houseId) then
                lookupCache[lookupString] = locationId
                lookupId = locationId
                break
            end
        end
    end

    if (lookupId == nil) then
        return nil
    end

    return LocationRegistry.getLocationById(lookupId)
end

function LocationRegistry.getAllLocations()
    -- Pass by reference; don't mutate this!
    return LocationRegistry.data
end