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
        }
    }
}

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