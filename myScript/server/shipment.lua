ActiveShipment = nil
ShipmentNPC = nil

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

function createShipmentNPC()

    if isElement(ShipmentNPC) then
        destroyElement(ShipmentNPC)
    end


    local npc = ShipmentConfig.npc


    if not npc.x
    or not npc.y
    or not npc.z then

        outputDebugString(
            "[SHIPMENT] NPC location has not been set."
        )

        return false

    end


    ShipmentNPC =
        createPed(
            npc.model,
            npc.x,
            npc.y,
            npc.z,
            npc.rotation
        )


    if not ShipmentNPC then

        outputDebugString(
            "[SHIPMENT] Failed to create shipment NPC."
        )

        return false

    end


    setElementInterior(
        ShipmentNPC,
        npc.interior
    )


    setElementDimension(
        ShipmentNPC,
        npc.dimension
    )


    setElementFrozen(
        ShipmentNPC,
        true
    )


    setElementData(
        ShipmentNPC,
        "shipment:npc",
        true
    )


    outputDebugString(
        "[SHIPMENT] Shipment NPC created."
    )


    return true

end

addEvent(
    "shipment:requestStart",
    true
)

addEventHandler(
    "shipment:requestStart",
    root,
    function()

        local player = client


        if not isElement(player) then
            return
        end


        if not isElement(ShipmentNPC) then

            outputChatBox(
                "[SHIPMENT] The shipment NPC is not available.",
                player,
                255, 0, 0
            )

            return

        end


        local px, py, pz =
            getElementPosition(player)


        local nx, ny, nz =
            getElementPosition(ShipmentNPC)


        local distance =
            getDistanceBetweenPoints3D(
                px, py, pz,
                nx, ny, nz
            )


        -- Server-side distance check
        if distance > 3 then

            outputChatBox(
                "[SHIPMENT] You are too far from the NPC.",
                player,
                255, 100, 100
            )

            return

        end


        local success, result =
            createShipment()


        if not success then

            outputChatBox(
                "[SHIPMENT] Failed to start shipment.",
                player,
                255, 0, 0
            )


            outputChatBox(
                "[SHIPMENT] "
                .. tostring(result),
                player,
                255, 100, 100
            )


            return

        end


        outputChatBox(
            "[SHIPMENT] Shipment started!",
            player,
            0, 255, 0
        )


        outputChatBox(
            "[SHIPMENT] Vehicle: "
            .. result.vehicle.name,
            player,
            255, 255, 255
        )


        outputChatBox(
            "[SHIPMENT] Crates: "
            .. result.cargo.total,
            player,
            255, 255, 255
        )

    end
)

addEventHandler(
    "onResourceStart",
    resourceRoot,
    function()

        if not ShipmentConfig.testMode then
            return
        end


        if ShipmentConfig.npc.x
        and ShipmentConfig.npc.y
        and ShipmentConfig.npc.z then

            createShipmentNPC()

        else

            outputDebugString(
                "[SHIPMENT] NPC location is not set."
            )

        end

    end
)
