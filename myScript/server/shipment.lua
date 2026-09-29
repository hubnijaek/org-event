ActiveShipment = nil

local shipmentID = 0
local cooldownEndsAt = 0

function resetShipmentCooldown()
    cooldownEndsAt = 0
    outputDebugString(
        "[SHIPMENT] Shipment cooldown reset."
    )
    return true
end

-- GET ACTIVE SHIPMENT

function getActiveShipment()
    return ActiveShipment
end


-- CHECK IF EVENT IS ON COOLDOWN

function isShipmentOnCooldown()
    return getTickCount() < cooldownEndsAt
end


-- GET REMAINING COOLDOWN

function getShipmentCooldownRemaining()
    if not isShipmentOnCooldown() then
        return 0
    end

    return cooldownEndsAt - getTickCount()
end


-- CREATE RANDOM CARGO

local function generateCargo(amount)
    local crates = {}

    for i = 1, amount do

        local randomType = ShipmentConfig.cargoTypes[
            math.random(1, #ShipmentConfig.cargoTypes)
        ]

        crates[i] = {
            id = i,
            type = randomType
        }
    end

    return crates
end


-- CREATE SHIPMENT

function createShipment(organization)
    if ActiveShipment then
        return false, "There is already an active shipment."
    end

    if isShipmentOnCooldown() then
        return false, "The illegal shipment event is on cooldown."
    end

    shipmentID = shipmentID + 1


    -- RANDOM VEHICLE


    local vehicleConfig = ShipmentConfig.vehicles[
        math.random(1, #ShipmentConfig.vehicles)
    ]


    -- CREATE SHIPMENT DATA


    local now = getTickCount()

    ActiveShipment = {

        id = shipmentID,

        state = "created",

    
        -- ORIGINAL ORGANIZATION
    

        initiator = {
            organizationId = organization.id,
            organizationName = organization.name
        },

    
        -- CURRENT OWNER
    

        currentOwner = {
            type = "organization",
            organizationId = organization.id,
            organizationName = organization.name
        },

    
        -- VEHICLE
    

        vehicle = {
            model = vehicleConfig.model,
            name = vehicleConfig.name,
            capacity = vehicleConfig.capacity,
            element = nil
        },

    
        -- CARGO
    

        cargo = {
            total = vehicleConfig.capacity,
            crates = generateCargo(vehicleConfig.capacity)
        },

    
        -- TIME
    

        startedAt = now,

        expiresAt = now + ShipmentConfig.duration,

    
        -- DESTINATION
    

        pickup = nil,

        destination = nil
    }
end
-- CHANGE SHIPMENT STATE

function setShipmentState(newState)

    if not ActiveShipment then
        return false
    end

    local oldState = ActiveShipment.state

    ActiveShipment.state = newState

    outputDebugString(
        "[SHIPMENT] #" ..
        ActiveShipment.id ..
        " state changed: " ..
        oldState ..
        " -> " ..
        newState
    )

    triggerClientEvent(
        root,
        "shipment:stateChanged",
        resourceRoot,
        ActiveShipment.id,
        newState
    )

    return true
end


-- DESTROY SHIPMENT

function destroyShipment(reason)

    if not ActiveShipment then
        return false
    end

    local shipment = ActiveShipment



    if isElement(shipment.vehicle.element) then
        destroyElement(shipment.vehicle.element)
    end



    ActiveShipment = nil


    -- START GLOBAL COOLDOWN


    cooldownEndsAt = getTickCount() + ShipmentConfig.cooldown

    outputDebugString(
        "[SHIPMENT] Shipment #" ..
        shipment.id ..
        " ended. Reason: " ..
        tostring(reason)
    )

    return true
end

if ShipmentConfig.testMode then

    local pickup = ShipmentConfig.testLocations.pickup

    if not pickup then
        ActiveShipment = nil

        return false,
            "No pickup location has been set. Use /setshipmentpos pickup first."
    end

    -------------------------------------------------
    -- SPAWN VEHICLE
    -------------------------------------------------

    local vehicle = createVehicle(
        vehicleConfig.model,
        pickup.x,
        pickup.y,
        pickup.z
    )

    if not vehicle then
        ActiveShipment = nil

        return false,
            "Failed to create shipment vehicle."
    end

    -------------------------------------------------
    -- SET INTERIOR / DIMENSION
    -------------------------------------------------

    setElementInterior(vehicle, pickup.interior)
    setElementDimension(vehicle, pickup.dimension)

    -------------------------------------------------
    -- STORE VEHICLE
    -------------------------------------------------

    ActiveShipment.vehicle.element = vehicle

    -------------------------------------------------
    -- STORE PICKUP
    -------------------------------------------------

    ActiveShipment.pickup = {
        x = pickup.x,
        y = pickup.y,
        z = pickup.z,

        interior = pickup.interior,
        dimension = pickup.dimension
    }

    -------------------------------------------------
    -- STORE DESTINATION
    -------------------------------------------------

    local destination =
        ShipmentConfig.testLocations.destination

    if destination then

        ActiveShipment.destination = {
            x = destination.x,
            y = destination.y,
            z = destination.z,

            interior = destination.interior,
            dimension = destination.dimension
        }

    end

    -------------------------------------------------
    -- STORE SHIPMENT DATA ON VEHICLE
    -------------------------------------------------

    setElementData(
        vehicle,
        "shipment:id",
        ActiveShipment.id
    )

    setElementData(
        vehicle,
        "shipment:vehicle",
        true
    )

    -------------------------------------------------
    -- DEBUG
    -------------------------------------------------

    outputDebugString(
        "[SHIPMENT] Created shipment #" ..
        shipmentID ..
        " - " ..
        vehicleConfig.name ..
        " - " ..
        vehicleConfig.capacity ..
        " crates"
    )

    return true, ActiveShipment
end