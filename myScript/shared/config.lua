ShipmentConfig = {

    -- TEST MODE
    testMode = true,

    -- Shipment duration
    duration = 45 * 60 * 1000,

    -- Global cooldown
    cooldown = 3 * 60 * 60 * 1000,

    -- Shipment vehicles
    vehicles = {

        {
            model = 456,
            name = "Yankee",
            capacity = 12
        },

        {
            model = 482,
            name = "Burrito",
            capacity = 8
        }

    },

    -- Cargo types
    cargoTypes = {
        "cash",
        "weapons",
        "bullets"
    },

    -- Crate object
    crateObjectModel = 1271,

    -- Shipment NPC
    npc = {

        model = 29,

        x = nil,
        y = nil,
        z = nil,

        rotation = 0,

        interior = 0,
        dimension = 0

    },

    -- Temporary test locations
    testLocations = {

        pickup = nil,

        destination = nil

    }

}
