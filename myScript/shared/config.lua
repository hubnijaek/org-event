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
    crateObjectModel = 964,

    -- Shipment NPC
    npc = {

        model = 29,

        x = 2491.1484,
        y = -1684.1221,
        z = 13.5082,

        rotation = 0,

        interior = 0,
        dimension = 0

    },

    -- Temporary test locations
    testLocations = {

        pickup = {
            x = 2492.7246,
            y = -1670.6904,
            z = 13.3359,

            interior = 0,
            dimension = 0
        },

        crates = {
            x = 2502.6279,
            y = -1673.9141,
            z = 13.3687,

            interior = 0,
            dimension = 0
        },

        destination = {
            x = 2472.1953,
            y = -1663.8369,
            z = 13.3209,

            interior = 0,
            dimension = 0
        }

    }

}
