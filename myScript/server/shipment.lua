ActiveShipment = nil

local shipmentID = 0
local cooldownEndsAt = 0
local expirationTimer = nil
local endingShipment = false


--------------------------------------------------
-- GET ACTIVE SHIPMENT
--------------------------------------------------

function getActiveShipment()

    return ActiveShipment

end


--------------------------------------------------
-- COOLDOWN
--------------------------------------------------

function isShipmentOnCooldown()

    return getTickCount() < cooldownEndsAt

end


function getShipmentCooldownRemaining()

    if not isShipmentOnCooldown() then
        return 0
    end

    return cooldownEndsAt - getTickCount()

end


function resetShipmentCooldown()

    cooldownEndsAt = 0

    outputDebugString(
        "[SHIPMENT] Cooldown reset."
    )

end


--------------------------------------------------
-- RANDOM CARGO
--------------------------------------------------

local function generateCargo(amount)

    local crates = {}

    for i = 1, amount do

        local cargoType =
            ShipmentConfig.cargoTypes[
                math.random(
                    1,
                    #ShipmentConfig.cargoTypes
                )
            ]

        crates[i] = {

            id = i,

            type = cargoType

        }

    end

    return crates

end


--------------------------------------------------
-- SHIPMENT EXPIRATION
--------------------------------------------------

local function shipmentExpired()

    if not ActiveShipment then
        return
    end

    outputDebugString(
        "[SHIPMENT] Shipment #"
        .. ActiveShipment.id
        .. " expired."
    )

    setShipmentState("expired")

    destroyShipment(
        "Shipment time expired."
    )

end


--------------------------------------------------
-- VEHICLE DESTROYED
--------------------------------------------------

local function onShipmentVehicleDestroy()

    if not ActiveShipment then
        return
    end

    if endingShipment then
        return
    end

    if ActiveShipment.vehicle.element ~= source then
        return
    end

    outputDebugString(
        "[SHIPMENT] Shipment vehicle was destroyed."
    )

    setShipmentState("destroyed")

    destroyShipment(
        "Shipment vehicle destroyed."
    )

end


--------------------------------------------------
-- CREATE SHIPMENT
--------------------------------------------------

function createShipment()

    if ActiveShipment then

        return false,
            "There is already an active shipment."

    end


    if isShipmentOnCooldown() then

        return false,
            "The illegal shipment event is on cooldown."

    end


    if not ShipmentConfig.testMode then

        return false,
            "Test mode is disabled."

    end


    local pickup =
        ShipmentConfig.testLocations.pickup


    local destination =
        ShipmentConfig.testLocations.destination


    if not pickup then

        return false,
            "Pickup location has not been set."

    end


    if not destination then

        return false,
            "Destination location has not been set."

    end


    shipmentID = shipmentID + 1


    --------------------------------------------------
    -- RANDOM VEHICLE
    --------------------------------------------------

    local vehicleConfig =
        ShipmentConfig.vehicles[
            math.random(
                1,
                #ShipmentConfig.vehicles
            )
        ]


    local now = getTickCount()


    --------------------------------------------------
    -- CREATE SHIPMENT DATA
    --------------------------------------------------

    ActiveShipment = {

        id = shipmentID,

        state = "created",

        vehicle = {

            model = vehicleConfig.model,

            name = vehicleConfig.name,

            capacity = vehicleConfig.capacity,

            element = nil

        },

        cargo = {

            total = vehicleConfig.capacity,

            crates = generateCargo(
                vehicleConfig.capacity
            )

        },

        pickup = {

            x = pickup.x,

            y = pickup.y,

            z = pickup.z,

            interior = pickup.interior,

            dimension = pickup.dimension

        },

        destination = {

            x = destination.x,

            y = destination.y,

            z = destination.z,

            interior = destination.interior,

            dimension = destination.dimension

        },

        startedAt = now,

        expiresAt =
            now + ShipmentConfig.duration

    }


    --------------------------------------------------
    -- CREATE VEHICLE
    --------------------------------------------------

    local vehicle =
        createVehicle(
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


    --------------------------------------------------
    -- SET VEHICLE LOCATION
    --------------------------------------------------

    setElementInterior(
        vehicle,
        pickup.interior
    )

    setElementDimension(
        vehicle,
        pickup.dimension
    )


    --------------------------------------------------
    -- SAVE VEHICLE
    --------------------------------------------------

    ActiveShipment.vehicle.element =
        vehicle


    --------------------------------------------------
    -- VEHICLE DATA
    --------------------------------------------------

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


    --------------------------------------------------
    -- VEHICLE DESTROY EVENT
    --------------------------------------------------

    addEventHandler(
        "onElementDestroy",
        vehicle,
        onShipmentVehicleDestroy
    )


    --------------------------------------------------
    -- EXPIRATION TIMER
    --------------------------------------------------

    expirationTimer =
        setTimer(
            shipmentExpired,
            ShipmentConfig.duration,
            1
        )


    --------------------------------------------------
    -- DEBUG
    --------------------------------------------------

    outputDebugString(
        "[SHIPMENT] ==============================="
    )

    outputDebugString(
        "[SHIPMENT] Shipment created."
    )

    outputDebugString(
        "[SHIPMENT] ID: "
        .. ActiveShipment.id
    )

    outputDebugString(
        "[SHIPMENT] Vehicle: "
        .. vehicleConfig.name
    )

    outputDebugString(
        "[SHIPMENT] Capacity: "
        .. vehicleConfig.capacity
    )

    outputDebugString(
        "[SHIPMENT] Pickup: "
        .. pickup.x
        .. ", "
        .. pickup.y
        .. ", "
        .. pickup.z
    )

    outputDebugString(
        "[SHIPMENT] Destination: "
        .. destination.x
        .. ", "
        .. destination.y
        .. ", "
        .. destination.z
    )

    outputDebugString(
        "[SHIPMENT] ==============================="
    )


    return true, ActiveShipment

end


--------------------------------------------------
-- CHANGE STATE
--------------------------------------------------

function setShipmentState(newState)

    if not ActiveShipment then
        return false
    end


    local oldState =
        ActiveShipment.state


    ActiveShipment.state =
        newState


    outputDebugString(
        "[SHIPMENT] Shipment #"
        .. ActiveShipment.id
        .. " state: "
        .. oldState
        .. " -> "
        .. newState
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


--------------------------------------------------
-- DESTROY SHIPMENT
--------------------------------------------------

function destroyShipment(reason)

    if not ActiveShipment then
        return false
    end


    if endingShipment then
        return false
    end


    endingShipment = true


    local shipment =
        ActiveShipment


    --------------------------------------------------
    -- STOP EXPIRATION TIMER
    --------------------------------------------------

    if isTimer(expirationTimer) then

        killTimer(
            expirationTimer
        )

    end

    expirationTimer = nil


    --------------------------------------------------
    -- DESTROY VEHICLE
    --------------------------------------------------

    if isElement(
        shipment.vehicle.element
    ) then

        destroyElement(
            shipment.vehicle.element
        )

    end


    --------------------------------------------------
    -- START GLOBAL COOLDOWN
    --------------------------------------------------

    cooldownEndsAt =
        getTickCount()
        + ShipmentConfig.cooldown


    outputDebugString(
        "[SHIPMENT] Shipment #"
        .. shipment.id
        .. " ended."
    )

    outputDebugString(
        "[SHIPMENT] Reason: "
        .. tostring(reason)
    )

    outputDebugString(
        "[SHIPMENT] Global cooldown started."
    )


    ActiveShipment = nil

    endingShipment = false


    return true

end
