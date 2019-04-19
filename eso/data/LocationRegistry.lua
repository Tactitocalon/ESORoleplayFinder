LocationRegistry = {
    data = {
        [2] = {
            id = 2,
            username = "@teacupdragon",
            houseId = 23,
            houseName = "Pots' Potion Emporium",
            populationCap = 12
        },
        [3] = {
            id = 3,
            username = "@Tactitocalon",
            houseId = 20,
            houseName = "Valyndia's Party House",
            populationCap = 12
        }
    }
}

local lookupCache = {}

function LocationRegistry.getLocationById(locationId)
    return LocationRegistry.data[locationId] or nil
end

function LocationRegistry.getLocation(houseOwner, houseId)
    local lookupString = houseOwner .. "#" .. houseId
    d("lookupString=" .. lookupString)
    local lookupId = lookupCache[lookupString]
    d("x1")

    if (lookupId == nil) then
        d("x2")
        -- Linear search through registry, cache the ID when we find it.
        for locationId, locationData in pairs(LocationRegistry.data) do
            d("Checking locationData.username=" .. locationData.username .. " & locationData.houseId=" .. locationData.houseId)
            if (locationData.username == houseOwner and locationData.houseId == houseId) then
                lookupCache[lookupString] = locationId
                lookupId = locationId
                d("Found it!")
                break
            end
        end
    end

    if (lookupId == nil) then
        return nil
    end

    return LocationRegistry.getLocationById(lookupId)
end