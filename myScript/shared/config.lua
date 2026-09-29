ShipmentConfig = {

    duration = 45 * 60 * 1000,
    testMode = true,
    cooldown = 3 * 60 * 60 * 1000,

    minimumGangMembers = 3,
    minimumLEO = 5,

    vehicles = {
        {
            model = 456, -- Yankee
            name = "Yankee",
            capacity = 12
        },

        {
            model = 482, -- Burrito
            name = "Burrito",
            capacity = 8
        }
    },

    cargoTypes = {
        "cash",
        "weapons",
        "bullets"
    },

    crateObjectModel = 1271,

    testLocations = {
        pickup = nil,
        destination = nil
    }

}   