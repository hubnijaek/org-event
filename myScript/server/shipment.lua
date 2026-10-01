ActiveShipment = nil
ShipmentNPC = nil


local shipmentID = 0
local cooldownEndsAt = 0
local expirationTimer = nil
local endingShipment = false
local ShipmentDeliveryCheckpoint = nil
local ShipmentDropoffMarker = nil

-- defined further down (manual unloading stage)
local handleUnloadInteraction
local checkUnloadComplete

-- Physical crate objects
local shipmentCrates = {}

-- Which crate each player is currently carrying
local carryingCrate = {}



-- GET ACTIVE SHIPMENT


function getActiveShipment()
    return ActiveShipment
end



-- COOLDOWN


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



-- CRATE CONTENTS
-- Each crate holds either cash or weapons, chosen at random.

local CRATE_CASH_MIN        = 3000
local CRATE_CASH_MAX        = 5000

local CRATE_WEAPON_MIN      = 2     -- number of weapons in a weapon crate
local CRATE_WEAPON_MAX      = 4

local CRATE_CASH_CHANCE     = 0.5   -- 0.5 = half the crates hold cash, half weapons

-- ammo handed over per weapon in the crate (on delivery, scaled by crate condition)
local CRATE_WEAPONS = {
    { id = 31, name = "M4",           ammoPerWeapon = 60 },
    { id = 30, name = "AK-47",        ammoPerWeapon = 60 },
    { id = 24, name = "Desert Eagle", ammoPerWeapon = 28 },
    { id = 29, name = "MP5",          ammoPerWeapon = 60 },
    { id = 25, name = "Shotgun",      ammoPerWeapon = 24 },
}

local function generateCrateContents()

    if math.random() < CRATE_CASH_CHANCE then

        return {
            kind = "cash",
            cash = math.random(
                CRATE_CASH_MIN,
                CRATE_CASH_MAX
            )
        }

    end

    local weapon =
        CRATE_WEAPONS[
            math.random(
                1,
                #CRATE_WEAPONS
            )
        ]

    return {
        kind = "weapon",
        weaponID = weapon.id,
        weaponName = weapon.name,
        ammoPerWeapon = weapon.ammoPerWeapon,
        amount = math.random(
            CRATE_WEAPON_MIN,
            CRATE_WEAPON_MAX
        )
    }

end

local function describeContents(contents)

    if not contents then
        return "unknown"
    end

    if contents.kind == "cash" then
        return "$" .. contents.cash .. " in cash"
    end

    return contents.amount .. "x " .. contents.weaponName

end


-- RANDOM CARGO


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

            type = cargoType,

            element = nil,

            contents = generateCrateContents(),

            loaded = false

        }

    end

    return crates

end



-- SPAWN PHYSICAL CRATES


local function spawnShipmentCrates()

    outputDebugString(
        "[SHIPMENT] spawnShipmentCrates() CALLED."
    )

    if not ActiveShipment then

        outputDebugString(
            "[SHIPMENT] ERROR: ActiveShipment is nil.",
            1
        )

        return false

    end

    if not ActiveShipment.pickup then

        outputDebugString(
            "[SHIPMENT] ERROR: Pickup location is nil.",
            1
        )

        return false

    end

    if not ActiveShipment.cargo then

        outputDebugString(
            "[SHIPMENT] ERROR: Cargo data is nil.",
            1
        )

        return false

    end

    local pickup = 
        ActiveShipment.cratesPosition 
    local crates = ActiveShipment.cargo.crates

    if not crates then

        outputDebugString(
            "[SHIPMENT] ERROR: Cargo crates table is nil.",
            1
        )

        return false

    end

    outputDebugString(
        "[SHIPMENT] Number of crates to spawn: "
        .. #crates
    )

    for index, crateData in ipairs(crates) do

        local row =
            math.floor((index - 1) / 4)

        local column =
            (index - 1) % 4

        local x =
            pickup.x + (column * 1.5)

        local y =
            pickup.y + (row * 1.5)

        local z =
            pickup.z - 1

        outputDebugString(
            "[SHIPMENT] Creating crate #"
            .. index
            .. " at "
            .. x
            .. ", "
            .. y
            .. ", "
            .. z
        )

        local crate =
            createObject(
                ShipmentConfig.crateObjectModel,
                x,
                y,
                z
            )

        if crate and isElement(crate) then

            setElementInterior(
                crate,
                pickup.interior
            )

            setElementDimension(
                crate,
                pickup.dimension
            )

            setElementData(
                crate,
                "shipment:crate",
                true
            )

            setElementData(
                crate,
                "shipment:crateHealth",
                100
            )
            setElementData(
                crate,
                "shipment:id",
                ActiveShipment.id
            )

            setElementData(
                crate,
                "shipment:crateID",
                crateData.id
            )

            crateData.element = crate

            table.insert(
                shipmentCrates,
                crate
            )

            outputDebugString(
                "[SHIPMENT] SUCCESS: Crate #"
                .. index
                .. " created."
            )

        else

            outputDebugString(
                "[SHIPMENT] ERROR: Failed to create crate #"
                .. index
                .. ". Model: "
                .. tostring(ShipmentConfig.crateObjectModel),
                1
            )

        end

    end

    outputDebugString(
        "[SHIPMENT] Finished spawning crates. Total: "
        .. #shipmentCrates
    )

    return true

end


-- DESTROY PHYSICAL CRATES


local function destroyShipmentCrates()

    outputDebugString(
        "[SHIPMENT] destroyShipmentCrates() CALLED."
    )

    outputDebugString(
        "[SHIPMENT] Crates currently tracked: "
        .. #shipmentCrates
    )

    for index, crate in ipairs(shipmentCrates) do

        if isElement(crate) then

            outputDebugString(
                "[SHIPMENT] Destroying crate #"
                .. index
            )

            destroyElement(crate)

        else

            outputDebugString(
                "[SHIPMENT] Crate #"
                .. index
                .. " is already invalid."
            )

        end

    end

    shipmentCrates = {}

end



-- FIND CARRIED CRATE


local function getCarriedCrate(player)

    local crate =
        carryingCrate[player]

    if crate and isElement(crate) then
        return crate
    end

    carryingCrate[player] = nil

    return nil

end



-- FIND NEAREST CRATE


local function getNearestAvailableCrate(player)

    local px, py, pz =
        getElementPosition(player)


    local nearestCrate = nil
    local nearestDistance = 999


    for _, crate in ipairs(shipmentCrates) do

        if isElement(crate) then

            local owner =
                getElementData(
                    crate,
                    "shipment:carriedBy"
                )


            if not owner then

                local x, y, z =
                    getElementPosition(crate)


                local distance =
                    getDistanceBetweenPoints3D(
                        px, py, pz,
                        x, y, z
                    )


                if distance < nearestDistance then

                    nearestDistance = distance

                    nearestCrate = crate

                end

            end

        end

    end


    if nearestDistance <= 2.5 then
        return nearestCrate
    end


    return nil

end



-- FIND SHIPMENT VEHICLE


local function isNearShipmentVehicle(player)

    if not ActiveShipment then
        return false
    end


    local vehicle =
        ActiveShipment.vehicle.element


    if not isElement(vehicle) then
        return false
    end


    local px, py, pz =
        getElementPosition(player)


    local vx, vy, vz =
        getElementPosition(vehicle)


    local distance =
        getDistanceBetweenPoints3D(
            px, py, pz,
            vx, vy, vz
        )


    return distance <= 4.5

end



-- PICK UP CRATE


local function pickupCrate(player, crate)

    if not ActiveShipment then
        return
    end


    if not isElement(crate) then
        return
    end


    if getCarriedCrate(player) then

        outputChatBox(
            "[SHIPMENT] You are already carrying a crate.",
            player,
            255, 100, 100
        )

        return

    end


    local crateShipmentID =
        getElementData(
            crate,
            "shipment:id"
        )


    if crateShipmentID
    ~= ActiveShipment.id then

        return

    end


    local crateID =
        getElementData(
            crate,
            "shipment:crateID"
        )


    local crateData =
        ActiveShipment.cargo.crates[
            crateID
        ]


    if not crateData then
        return
    end


    if crateData.loaded then
        return
    end


    
    -- MARK AS CARRIED
    

    carryingCrate[player] =
        crate


    setElementData(
        crate,
        "shipment:carriedBy",
        player
    )


    
    -- ATTACH TO PLAYER
    

    setElementCollisionsEnabled(
        crate,
        false
    )


    attachElements(
        crate,
        player,
        0,
        0.8,
        0.5
    )


    
    -- CARRY ANIMATION
    

    setPedAnimation(
        player,
        "CARRY",
        "crry_prtial",
        1,
        true,
        false,
        false,
        true
    )


    outputChatBox(
        "[SHIPMENT] Crate picked up (" .. describeContents(crateData.contents) .. "). Take it to the truck.",
        player,
        0, 255, 0
    )

end


local function createDeliveryCheckpoint()

    if not ActiveShipment then
        return
    end

    local destination =
        ActiveShipment.destination

    if not destination then
        return
    end

    -- Remove old checkpoint if one exists
    if ShipmentDeliveryCheckpoint
    and isElement(ShipmentDeliveryCheckpoint) then

        destroyElement(
            ShipmentDeliveryCheckpoint
        )

    end

    ShipmentDeliveryCheckpoint =
        createMarker(
            destination.x,
            destination.y,
            destination.z - 1,
            "checkpoint",
            4.0,
            255,
            180,
            0,
            180
        )

    if not ShipmentDeliveryCheckpoint then

        outputDebugString(
            "[SHIPMENT] Failed to create delivery checkpoint.",
            1
        )

        return
    end

    setElementInterior(
        ShipmentDeliveryCheckpoint,
        destination.interior
    )

    setElementDimension(
        ShipmentDeliveryCheckpoint,
        destination.dimension
    )

    setElementData(
        ShipmentDeliveryCheckpoint,
        "shipment:delivery",
        true
    )

    setElementData(
        ShipmentDeliveryCheckpoint,
        "shipment:id",
        ActiveShipment.id
    )

    outputDebugString(
        "[SHIPMENT] Delivery checkpoint created."
    )

end


-- LOAD CRATE INTO VEHICLE


local function loadCarriedCrate(player)

    if not ActiveShipment then
        return
    end


    local crate =
        getCarriedCrate(player)


    if not crate then

        outputChatBox(
            "[SHIPMENT] You are not carrying a crate.",
            player,
            255, 100, 100
        )

        return

    end


    if not isNearShipmentVehicle(player) then

        outputChatBox(
            "[SHIPMENT] Move closer to the shipment vehicle.",
            player,
            255, 100, 100
        )

        return

    end


    local crateID =
        getElementData(
            crate,
            "shipment:crateID"
        )


    local crateData =
        ActiveShipment.cargo.crates[
            crateID
        ]


    if not crateData then
        return
    end


    
    -- REMOVE FROM PLAYER
    

    detachElements(crate)

    setPedAnimation(
        player
    )


    setElementData(
        crate,
        "shipment:carriedBy",
        false
    )


    
    -- MARK LOADED
    

    crateData.loaded = true

    -- remember the crate's condition so it keeps it when taken out again
    crateData.health =
        tonumber(
            getElementData(
                crate,
                "shipment:crateHealth"
            )
        ) or 100


    carryingCrate[player] = nil


    
    -- DESTROY PHYSICAL CRATE
    

    if isElement(crate) then
        destroyElement(crate)
    end


    
    -- COUNT LOADED CRATES
    

    local loadedCount = 0
    local lostCount = 0


    for _, data in ipairs(
        ActiveShipment.cargo.crates
    ) do

        if data.loaded then
            loadedCount = loadedCount + 1
        end

        if data.destroyed then
            lostCount = lostCount + 1
        end

    end


    ActiveShipment.cargo.loaded =
        loadedCount


    outputChatBox(
        "[SHIPMENT] Crate loaded! "
        .. loadedCount
        .. "/"
        .. ActiveShipment.cargo.total,
        player,
        0, 255, 0
    )


    
    -- ALL CRATES LOADED
    

    if loadedCount
    >= (ActiveShipment.cargo.total - lostCount) then

        setShipmentState(
            "in_transit"
        )


        outputChatBox(
            "[SHIPMENT] All crates loaded!",
            player,
            0, 255, 0
        )

        createDeliveryCheckpoint()

        outputChatBox(
            "[SHIPMENT] Proceed to the delivery destination.",
            player,
            255, 200, 0
        )

    end

end



-- CARGO INTERACTION EVENT


addEvent(
    "shipment:cargoInteraction",
    true
)


addEventHandler(
    "shipment:cargoInteraction",
    root,
    function()

        local player = client


        if not isElement(player) then
            return
        end


        if not ActiveShipment then

            outputChatBox(
                "[SHIPMENT] There is no active shipment.",
                player,
                255, 100, 100
            )

            return

        end


        if isPedDead(player) then
            return
        end

        -- MANUAL UNLOADING STAGE
        if ActiveShipment.state == "unloading" then
            handleUnloadInteraction(player)
            return
        end


        
        -- PLAYER IS CARRYING
        

        if getCarriedCrate(player) then

            loadCarriedCrate(player)

            return

        end


        
        -- PLAYER IS NOT CARRYING
        

        local crate =
            getNearestAvailableCrate(player)


        if crate then

            pickupCrate(
                player,
                crate
            )

            return

        end


        outputChatBox(
            "[SHIPMENT] No crate nearby.",
            player,
            255, 100, 100
        )

    end
)



-- PLAYER QUIT


addEventHandler(
    "onPlayerQuit",
    root,
    function()

        local crate =
            carryingCrate[source]


        if crate and isElement(crate) then

            destroyElement(crate)

        end


        carryingCrate[source] = nil

    end
)



-- SHIPMENT EXPIRATION


local function shipmentExpired()

    if not ActiveShipment then
        return
    end


    outputDebugString(
        "[SHIPMENT] Shipment #"
        .. ActiveShipment.id
        .. " expired."
    )


    setShipmentState(
        "expired"
    )


    destroyShipment(
        "Shipment time expired."
    )

end



-- VEHICLE DESTROYED


local function onShipmentVehicleDestroy()

    if not ActiveShipment then
        return
    end


    if endingShipment then
        return
    end


    if ActiveShipment.vehicle.element
    ~= source then

        return

    end


    outputDebugString(
        "[SHIPMENT] Shipment vehicle was destroyed."
    )


    setShipmentState(
        "destroyed"
    )

    outputChatBox(
        "[SHIPMENT] The shipment vehicle was destroyed. Shipment failed.",
        root,
        255, 100, 100
    )

    destroyShipment(
        "Shipment vehicle destroyed."
    )

end



-- CREATE SHIPMENT


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


    local cratePosition =
        ShipmentConfig.testLocations.crates

    if not cratePosition then
        return false,
            "Crate position has not been set."
    end

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


    shipmentID =
        shipmentID + 1


    
    -- RANDOM VEHICLE
    

    local vehicleConfig =
        ShipmentConfig.vehicles[
            math.random(
                1,
                #ShipmentConfig.vehicles
            )
        ]


    local now =
        getTickCount()


    
    -- CREATE SHIPMENT DATA
    

    ActiveShipment = {

        id = shipmentID,

        state = "loading",

        owner ="test_owner",
        takeover = {
            active = false,
            startedAt = nil,
            endsAt = nil,
            newOwner = nil,
            timer = nil,
            player = nil,

        },

        vehicle = {

            model = vehicleConfig.model,

            name = vehicleConfig.name,

            capacity = vehicleConfig.capacity,

            element = nil

        },

        cargo = {

            total =
                vehicleConfig.capacity,

            loaded = 0,

            crates =
                generateCargo(
                    vehicleConfig.capacity
                )

        },

        pickup = {

            x = pickup.x,

            y = pickup.y,

            z = pickup.z,

            interior =
                pickup.interior,

            dimension =
                pickup.dimension

        },

        destination = {

            x = destination.x,

            y = destination.y,

            z = destination.z,

            interior =
                destination.interior,

            dimension =
                destination.dimension

        },

        startedAt = now,

        expiresAt =
            now + ShipmentConfig.duration,

        cratesPosition = {
            x = cratePosition.x,
            y = cratePosition.y,
            z = cratePosition.z,

            interior = cratePosition.interior,
            dimension = cratePosition.dimension

        }

    }
    




    
    -- CREATE VEHICLE
    

  local vehicle =
    createVehicle(
        vehicleConfig.model,
        pickup.x,
        pickup.y,
        pickup.z
    )

    if not vehicle then

    outputDebugString(
        "[SHIPMENT] Failed to create shipment vehicle.",
        1
    )

    ActiveShipment = nil

    return false

    end

    ActiveShipment.vehicle.element =
        vehicle
    
    -- VEHICLE LOCATION
    

    setElementInterior(
        vehicle,
        pickup.interior
    )

    setElementDimension(
        vehicle,
        pickup.dimension
    )
    
    -- SAVE VEHICLE


    ActiveShipment.vehicle.element =
        vehicle

    
    -- VEHICLE DATA
    
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


    -- VEHICLE DESTROY EVENT
    

    addEventHandler(
        "onElementDestroy",
        vehicle,
        onShipmentVehicleDestroy
    )

    addEventHandler(
        "onVehicleExplode",
        vehicle,
        onShipmentVehicleDestroy
    )


    
    -- SPAWN CRATES
    

    spawnShipmentCrates()


    
    -- EXPIRATION TIMER
    

    expirationTimer =
        setTimer(
            shipmentExpired,
            ShipmentConfig.duration,
            1
        )


    
    -- DEBUG
    

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
        "[SHIPMENT] Crates spawned: "
        .. vehicleConfig.capacity
    )


    outputDebugString(
        "[SHIPMENT] ==============================="
    )


    return true,
        ActiveShipment

end



-- CHANGE STATE


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



-- DESTROY SHIPMENT


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


    -- STOP TIMER

    if isTimer(expirationTimer) then

        killTimer(
            expirationTimer
        )

    end

    expirationTimer = nil


    -- DESTROY CRATES

    destroyShipmentCrates()

    -- REMOVE DELIVERY / DROP-OFF MARKERS

    if isElement(ShipmentDeliveryCheckpoint) then

        destroyElement(
            ShipmentDeliveryCheckpoint
        )

    end

    ShipmentDeliveryCheckpoint = nil

    if isElement(ShipmentDropoffMarker) then

        destroyElement(
            ShipmentDropoffMarker
        )

    end

    ShipmentDropoffMarker = nil


    -- CLEAR CARRIED CRATES

    for player, crate in pairs(
        carryingCrate
    ) do

        if isElement(player) then

            setPedAnimation(
                player
            )

        end

        if isElement(crate) then

            destroyElement(
                crate
            )

        end

        carryingCrate[player] = nil

    end


    -- DESTROY VEHICLE

    if shipment.vehicle
    and isElement(shipment.vehicle.element) then

        destroyElement(
            shipment.vehicle.element
        )

    end


    -- START COOLDOWN

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



-- CREATE SHIPMENT NPC


function createShipmentNPC()

    if isElement(ShipmentNPC) then

        destroyElement(
            ShipmentNPC
        )

    end


    local npc =
        ShipmentConfig.npc


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



-- NPC START EVENT


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
                "[SHIPMENT] Shipment NPC is not available.",
                player,
                255, 0, 0
            )

            return

        end


        local px, py, pz =
            getElementPosition(player)


        local nx, ny, nz =
            getElementPosition(
                ShipmentNPC
            )


        local distance =
            getDistanceBetweenPoints3D(
                px, py, pz,
                nx, ny, nz
            )


        if distance > 3 then

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


        outputChatBox(
            "[SHIPMENT] Pick up the crates and load the vehicle.",
            player,
            255, 200, 0
        )

    end
)



-- RESOURCE START


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

local function getShipmentReward()

    if not ActiveShipment then
        return 0
    end

    if ActiveShipment.vehicle.model == 456 then
        -- Yankee
        return 12000

    elseif ActiveShipment.vehicle.model == 482 then
        -- Burrito
        return 8000
    end

    return 0

end


-- MANUAL UNLOADING
-- After the driver confirms delivery at the checkpoint, the crates are
-- taken out of the vehicle one by one (press E near the vehicle) and carried
-- to a drop-off marker (press E inside the marker to put the crate down).

local DROPOFF_DISTANCE = 8.0   -- units behind the vehicle where the drop-off marker appears
local DROPOFF_RADIUS   = 3.0   -- how close to the marker centre a crate must be put down

-- delivered / lost-to-damage / still-in-vehicle counts
local function getUnloadStats()

    local delivered, lost, inVehicle = 0, 0, 0

    for _, data in ipairs(
        ActiveShipment.cargo.crates
    ) do

        if data.destroyed then
            lost = lost + 1
        elseif data.delivered then
            delivered = delivered + 1
        elseif data.loaded and not data.takenOut then
            inVehicle = inVehicle + 1
        end

    end

    return delivered, lost, inVehicle

end

local function startCarrying(player, crate)

    carryingCrate[player] =
        crate

    setElementData(
        crate,
        "shipment:carriedBy",
        player
    )

    setElementCollisionsEnabled(
        crate,
        false
    )

    attachElements(
        crate,
        player,
        0,
        0.8,
        0.5
    )

    setPedAnimation(
        player,
        "CARRY",
        "crry_prtial",
        1,
        true,
        false,
        false,
        true
    )

end

local function finishDelivery()

    if not ActiveShipment then
        return
    end

    local unload = ActiveShipment.unload
    local driver = unload and unload.driver

    local delivered = getUnloadStats()
    local total = ActiveShipment.cargo.total

    -- Pay out what each delivered crate holds, scaled by its remaining health:
    --   cash crates   -> cash * condition
    --   weapon crates -> the weapon with ammo (amount * ammoPerWeapon) * condition
    local cashTotal = 0
    local conditionSum = 0
    local weaponAmmo = {}      -- [weaponID] = { name, ammo, count }
    local weaponOrder = {}

    for _, data in ipairs(
        ActiveShipment.cargo.crates
    ) do

        if data.delivered then

            local condition =
                math.max(
                    0,
                    math.min(
                        100,
                        tonumber(data.health) or 100
                    )
                ) / 100

            conditionSum = conditionSum + condition

            local contents = data.contents

            if contents and contents.kind == "cash" then

                cashTotal =
                    cashTotal
                    + math.floor(contents.cash * condition)

            elseif contents and contents.kind == "weapon" then

                local entry = weaponAmmo[contents.weaponID]

                if not entry then

                    entry = {
                        name = contents.weaponName,
                        ammo = 0,
                        count = 0
                    }

                    weaponAmmo[contents.weaponID] = entry
                    weaponOrder[#weaponOrder + 1] = contents.weaponID

                end

                entry.count = entry.count + contents.amount

                entry.ammo =
                    entry.ammo
                    + math.floor(
                        contents.amount
                        * contents.ammoPerWeapon
                        * condition
                    )

            end

        end

    end

    local averageCondition =
        (delivered > 0)
        and math.floor((conditionSum / delivered) * 100)
        or 0

    if isElement(driver) then

        outputChatBox(
            "[SHIPMENT] Shipment successfully delivered! ("
            .. delivered .. "/" .. total .. " crates)",
            driver,
            0, 255, 0
        )

        outputChatBox(
            "[SHIPMENT] Average cargo condition: "
            .. averageCondition .. "%",
            driver,
            255, 200, 0
        )

        if cashTotal > 0 then

            givePlayerMoney(
                driver,
                cashTotal
            )

            outputChatBox(
                "[SHIPMENT] Cash received: $"
                .. cashTotal,
                driver,
                0, 255, 0
            )

        end

        for _, weaponID in ipairs(weaponOrder) do

            local entry = weaponAmmo[weaponID]

            if entry.ammo > 0 then

                giveWeapon(
                    driver,
                    weaponID,
                    entry.ammo
                )

                outputChatBox(
                    "[SHIPMENT] Weapons received: "
                    .. entry.count .. "x " .. entry.name
                    .. " (" .. entry.ammo .. " ammo)",
                    driver,
                    0, 255, 0
                )

            end

        end

    end

    setShipmentState(
        "completed"
    )

    destroyShipment(
        "Successfully delivered."
    )

end

-- ends the shipment once every crate is either delivered or destroyed
function checkUnloadComplete()

    if not ActiveShipment
    or ActiveShipment.state ~= "unloading" then
        return
    end

    local delivered, lost =
        getUnloadStats()

    if delivered > 0
    and delivered + lost >= ActiveShipment.cargo.total then
        finishDelivery()
    end

end

local function takeCrateFromVehicle(player)

    if getPedOccupiedVehicle(player) then

        outputChatBox(
            "[SHIPMENT] Exit the vehicle first.",
            player,
            255, 100, 100
        )

        return

    end

    if not isNearShipmentVehicle(player) then

        outputChatBox(
            "[SHIPMENT] Move closer to the shipment vehicle.",
            player,
            255, 100, 100
        )

        return

    end

    -- next crate still inside the vehicle
    local crateData = nil

    for _, data in ipairs(
        ActiveShipment.cargo.crates
    ) do

        if data.loaded
        and not data.takenOut
        and not data.destroyed then

            crateData = data
            break

        end

    end

    if not crateData then

        outputChatBox(
            "[SHIPMENT] There are no crates left in the vehicle.",
            player,
            255, 200, 0
        )

        return

    end

    local px, py, pz =
        getElementPosition(player)

    local crate =
        createObject(
            ShipmentConfig.crateObjectModel,
            px,
            py,
            pz
        )

    if not crate then

        outputDebugString(
            "[SHIPMENT] ERROR: Failed to create crate while unloading.",
            1
        )

        return

    end

    setElementInterior(
        crate,
        getElementInterior(player)
    )

    setElementDimension(
        crate,
        getElementDimension(player)
    )

    setElementData(
        crate,
        "shipment:crate",
        true
    )

    setElementData(
        crate,
        "shipment:crateHealth",
        crateData.health or 100
    )

    setElementData(
        crate,
        "shipment:id",
        ActiveShipment.id
    )

    setElementData(
        crate,
        "shipment:crateID",
        crateData.id
    )

    crateData.element = crate
    crateData.takenOut = true

    -- tracked so it is cleaned up when the shipment ends
    table.insert(
        shipmentCrates,
        crate
    )

    startCarrying(
        player,
        crate
    )

    local _, _, inVehicle = getUnloadStats()

    outputChatBox(
        "[SHIPMENT] Crate taken out (" .. describeContents(crateData.contents) .. "). Carry it to the green drop-off marker. ("
        .. inVehicle .. " left in the vehicle)",
        player,
        0, 255, 0
    )

end

local function placeCarriedCrate(player)

    local crate =
        getCarriedCrate(player)

    if not crate then
        return
    end

    local unload = ActiveShipment.unload

    local px, py =
        getElementPosition(player)

    if getDistanceBetweenPoints2D(
        px, py,
        unload.x, unload.y
    ) > (DROPOFF_RADIUS + 0.5) then

        outputChatBox(
            "[SHIPMENT] Bring the crate to the green drop-off marker.",
            player,
            255, 100, 100
        )

        return

    end

    local crateID =
        getElementData(
            crate,
            "shipment:crateID"
        )

    local crateData =
        ActiveShipment.cargo.crates[crateID]

    if not crateData then
        return
    end

    -- put it down on the next free spot in a small grid around the marker
    local index = unload.slots
    unload.slots = unload.slots + 1

    local col = index % 3
    local row = math.floor(index / 3)

    local x = unload.x + (col - 1) * 1.4
    local y = unload.y + (row - 0.5) * 1.4

    detachElements(
        crate
    )

    setPedAnimation(
        player
    )

    setElementPosition(
        crate,
        x,
        y,
        unload.z
    )

    setElementRotation(
        crate,
        0,
        0,
        0
    )

    setElementCollisionsEnabled(
        crate,
        true
    )

    setElementFrozen(
        crate,
        true
    )

    setElementData(
        crate,
        "shipment:carriedBy",
        false
    )

    -- delivered crates can no longer be damaged
    setElementData(
        crate,
        "shipment:crate",
        false
    )

    carryingCrate[player] = nil

    crateData.health =
        tonumber(
            getElementData(
                crate,
                "shipment:crateHealth"
            )
        ) or crateData.health or 100

    crateData.delivered = true

    local delivered, lost =
        getUnloadStats()

    outputChatBox(
        "[SHIPMENT] Crate delivered! "
        .. delivered .. "/" .. (ActiveShipment.cargo.total - lost)
        .. " (condition: " .. math.floor(crateData.health) .. "%)",
        player,
        0, 255, 0
    )

    checkUnloadComplete()

end

-- E pressed while the shipment is in the unloading stage
function handleUnloadInteraction(player)

    if not ActiveShipment
    or ActiveShipment.state ~= "unloading" then
        return
    end

    if getCarriedCrate(player) then

        placeCarriedCrate(player)

    else

        takeCrateFromVehicle(player)

    end

end

-- starts the unloading stage (called when the driver confirms delivery)
local function beginManualUnload(player)

    local vehicle =
        ActiveShipment.vehicle.element

    local destination =
        ActiveShipment.destination

    -- drop-off marker goes behind the vehicle
    local vx, vy =
        getElementPosition(vehicle)

    local _, _, rz =
        getElementRotation(vehicle)

    local rad = math.rad(rz)

    local dx = vx + math.sin(rad) * DROPOFF_DISTANCE
    local dy = vy - math.cos(rad) * DROPOFF_DISTANCE
    local dz = destination.z - 1

    -- the vehicle checkpoint is no longer needed
    if isElement(ShipmentDeliveryCheckpoint) then

        destroyElement(
            ShipmentDeliveryCheckpoint
        )

    end

    ShipmentDeliveryCheckpoint = nil

    if isElement(ShipmentDropoffMarker) then

        destroyElement(
            ShipmentDropoffMarker
        )

    end

    ShipmentDropoffMarker =
        createMarker(
            dx,
            dy,
            dz,
            "cylinder",
            DROPOFF_RADIUS * 2,
            0,
            255,
            100,
            150
        )

    if ShipmentDropoffMarker then

        setElementInterior(
            ShipmentDropoffMarker,
            destination.interior
        )

        setElementDimension(
            ShipmentDropoffMarker,
            destination.dimension
        )

        setElementData(
            ShipmentDropoffMarker,
            "shipment:dropoff",
            true
        )

        setElementData(
            ShipmentDropoffMarker,
            "shipment:id",
            ActiveShipment.id
        )

        createBlipAttachedTo(
            ShipmentDropoffMarker,
            0,
            2,
            0, 255, 100, 255
        )

    end

    ActiveShipment.unload = {
        driver = player,
        x = dx,
        y = dy,
        z = dz,
        slots = 0
    }

    setShipmentState(
        "unloading"
    )

    local _, _, inVehicle = getUnloadStats()

    outputChatBox(
        "[SHIPMENT] Unload the cargo! Get out, press E next to the vehicle to take out a crate ("
        .. inVehicle .. " total), then carry it to the green drop-off marker and press E.",
        player,
        255, 200, 0
    )

end

local function unloadShipment(player)

    if not ActiveShipment then
        return
    end

    
    -- CHECK STATE
    

    if ActiveShipment.state == "unloading" then

        handleUnloadInteraction(player)

        return

    end

    if ActiveShipment.state ~= "in_transit" then

        outputChatBox(
            "[SHIPMENT] The shipment is not ready for delivery.",
            player,
            255, 100, 100
        )

        return

    end


    
    -- CHECK SHIPMENT VEHICLE
    

    local vehicle =
        ActiveShipment.vehicle.element

    if not vehicle or not isElement(vehicle) then

        outputChatBox(
            "[SHIPMENT] Shipment vehicle no longer exists.",
            player,
            255, 100, 100
        )

        return

    end


    
    -- CHECK PLAYER VEHICLE
    

    local playerVehicle =
        getPedOccupiedVehicle(player)

    if not playerVehicle then

        outputChatBox(
            "[SHIPMENT] You must be inside the shipment vehicle.",
            player,
            255, 100, 100
        )

        return

    end


    
    -- CHECK CORRECT VEHICLE
    

    if playerVehicle ~= vehicle then

        outputChatBox(
            "[SHIPMENT] This is not the shipment vehicle.",
            player,
            255, 100, 100
        )

        return

    end


    
    -- CHECK DRIVER
    

    if getVehicleOccupant(
        vehicle,
        0
    ) ~= player then

        outputChatBox(
            "[SHIPMENT] Only the driver can unload the shipment.",
            player,
            255, 100, 100
        )

        return

    end


    
    -- CHECK CHECKPOINT
    

    if not ShipmentDeliveryCheckpoint
    or not isElement(ShipmentDeliveryCheckpoint) then

        outputChatBox(
            "[SHIPMENT] Delivery checkpoint is not active.",
            player,
            255, 100, 100
        )

        return

    end


    local vx, vy, vz =
        getElementPosition(vehicle)

    local cx, cy, cz =
        getElementPosition(
            ShipmentDeliveryCheckpoint
        )

    local distance =
        getDistanceBetweenPoints3D(
            vx, vy, vz,
            cx, cy, cz
        )


    if distance > 7 then

        outputChatBox(
            "[SHIPMENT] Drive into the delivery checkpoint.",
            player,
            255, 100, 100
        )

        return

    end


    
    -- UNLOAD (manual: the crates are carried out by hand)

    beginManualUnload(player)

end


-- DELIVERY E INTERACTION


addEvent(
    "shipment:deliveryInteraction",
    true
)

addEventHandler(
    "shipment:deliveryInteraction",
    root,
    function()

        unloadShipment(
            client
        )

    end
)

-- CRATE DAMAGE
-- Bullets, ramming and melee are detected on the client
-- (client/crate_damage.lua) and reported here. Explosions are server-side.

local CRATE_BULLET_DAMAGE      = 10    -- per bullet hit

local CRATE_EXPLOSION_RADIUS   = 10.0  -- units
local CRATE_EXPLOSION_DAMAGE   = 100   -- at the centre, falls off with distance

local CRATE_RAM_MIN_SPEED      = 8     -- km/h, ignore gentle bumps
local CRATE_RAM_DAMAGE_PER_KMH = 0.6   -- damage = speed * this
local CRATE_RAM_MAX_DAMAGE     = 50
local CRATE_RAM_COOLDOWN       = 700   -- ms, per player

local CRATE_MELEE_COOLDOWN     = 500   -- ms, per player
local CRATE_MELEE_DAMAGE       = {     -- by weapon id
    [0]  = 3,   -- fists
    [1]  = 5,   -- brass knuckles
    [2]  = 6,   -- golf club
    [3]  = 6,   -- nightstick
    [4]  = 8,   -- knife
    [5]  = 10,  -- baseball bat
    [6]  = 8,   -- shovel
    [7]  = 6,   -- pool cue
    [8]  = 12,  -- katana
    [9]  = 15,  -- chainsaw
}
local CRATE_MELEE_DEFAULT      = 5
local CRATE_MAX_ACTION_DIST    = 150   -- general sanity limit
local CRATE_MELEE_MAX_DIST     = 8     -- melee must be this close

local CRATE_DEBUG = true   -- prints why a ram/melee report was rejected

local function crateReject(kind, why)
    if CRATE_DEBUG then
        outputDebugString("[SHIPMENT] " .. kind .. " rejected: " .. why)
    end
end

local lastRamHit   = {}
local lastMeleeHit = {}

-- Called after a crate is destroyed by damage.
-- Ends the shipment if every crate is gone; otherwise lets the
-- remaining crates complete the loading phase.
local function onShipmentCrateLost(crateShipmentID, crateID)

    if not ActiveShipment
    or endingShipment then
        return
    end

    -- crate belonged to an older shipment
    if crateShipmentID ~= ActiveShipment.id then
        return
    end

    local crateData =
        ActiveShipment.cargo.crates[crateID]

    if not crateData
    or crateData.destroyed then
        return
    end

    crateData.destroyed = true
    crateData.element = nil

    local total = ActiveShipment.cargo.total
    local lostCount = 0
    local loadedCount = 0

    for _, data in ipairs(
        ActiveShipment.cargo.crates
    ) do

        if data.destroyed then
            lostCount = lostCount + 1
        elseif data.loaded then
            loadedCount = loadedCount + 1
        end

    end

    outputDebugString(
        "[SHIPMENT] Crates lost: "
        .. lostCount .. "/" .. total
    )

    -- ALL CRATES DESTROYED -> stop the shipment
    if lostCount >= total then

        setShipmentState(
            "failed"
        )

        outputChatBox(
            "[SHIPMENT] All crates were destroyed. Shipment failed.",
            root,
            255, 100, 100
        )

        destroyShipment(
            "All crates destroyed."
        )

        return

    end

    outputChatBox(
        "[SHIPMENT] A crate was destroyed! "
        .. (total - lostCount) .. " crate(s) remaining.",
        root,
        255, 150, 0
    )

    -- the remaining crates may already all be loaded
    if ActiveShipment.state == "loading"
    and loadedCount >= (total - lostCount) then

        setShipmentState(
            "in_transit"
        )

        createDeliveryCheckpoint()

        outputChatBox(
            "[SHIPMENT] All remaining crates loaded. Proceed to the delivery destination.",
            root,
            255, 200, 0
        )

    end

    -- crate lost while unloading: the rest may already be delivered
    if ActiveShipment.state == "unloading" then

        checkUnloadComplete()

    end

end

local function isShipmentCrate(element)

    return isElement(element)
        and getElementType(element) == "object"
        and getElementData(
            element,
            "shipment:crate"
        ) == true

end

-- Applies damage to a crate, updates HP, destroys it at 0.
local function damageCrate(crate, damage, sourceText)

    if not isShipmentCrate(crate) then
        return
    end

    local health =
        tonumber(
            getElementData(
                crate,
                "shipment:crateHealth"
            )
        ) or 100

    local newHealth =
        math.max(
            0,
            health - damage
        )

    setElementData(
        crate,
        "shipment:crateHealth",
        newHealth,
        true
    )

    outputDebugString(
        "[SHIPMENT] Crate "
        .. tostring(
            getElementData(
                crate,
                "shipment:crateID"
            )
        )
        .. " "
        .. tostring(sourceText)
        .. " | -" .. tostring(damage)
        .. " | HP: "
        .. tostring(newHealth)
        .. "%"
    )

    if newHealth <= 0 then

        outputDebugString(
            "[SHIPMENT] Crate destroyed."
        )

        local crateID =
            getElementData(
                crate,
                "shipment:crateID"
            )

        local crateShipmentID =
            getElementData(
                crate,
                "shipment:id"
            )

        -- if someone was carrying it, release them
        local carrier =
            getElementData(
                crate,
                "shipment:carriedBy"
            )

        if isElement(carrier) then

            carryingCrate[carrier] = nil

            setPedAnimation(
                carrier
            )

            outputChatBox(
                "[SHIPMENT] The crate you were carrying was destroyed!",
                carrier,
                255, 100, 100
            )

        end

        destroyElement(
            crate
        )

        onShipmentCrateLost(
            crateShipmentID,
            crateID
        )

    end

end

local function playerNearCrate(player, crate, maxDist)

    local px, py, pz = getElementPosition(player)
    local cx, cy, cz = getElementPosition(crate)

    return getDistanceBetweenPoints3D(
        px, py, pz,
        cx, cy, cz
    ) <= maxDist

end


-- BULLETS

addEvent(
    "shipment:crateHit",
    true
)

addEventHandler(
    "shipment:crateHit",
    root,
    function(crate)

        local player = client

        if not isElement(player)
        or not isShipmentCrate(crate)
        or not playerNearCrate(player, crate, CRATE_MAX_ACTION_DIST) then
            return
        end

        damageCrate(
            crate,
            CRATE_BULLET_DAMAGE,
            "shot by " .. getPlayerName(player)
        )

    end
)


-- EXPLOSIONS

addEventHandler(
    "onExplosion",
    root,
    function(x, y, z, explosionType)

        for _, crate in ipairs(shipmentCrates) do

            if isShipmentCrate(crate) then

                local cx, cy, cz = getElementPosition(crate)

                local dist =
                    getDistanceBetweenPoints3D(
                        x, y, z,
                        cx, cy, cz
                    )

                if dist <= CRATE_EXPLOSION_RADIUS then

                    local falloff =
                        1 - (dist / CRATE_EXPLOSION_RADIUS)

                    local damage =
                        math.max(
                            5,
                            math.floor(
                                CRATE_EXPLOSION_DAMAGE * falloff
                            )
                        )

                    damageCrate(
                        crate,
                        damage,
                        "hit by explosion (" .. string.format("%.1f", dist) .. " units away)"
                    )

                end

            end

        end

    end
)


-- VEHICLE RAMMING
-- The client reports the crate and the vehicle speed (km/h) at impact.

addEvent(
    "shipment:crateRam",
    true
)

addEventHandler(
    "shipment:crateRam",
    root,
    function(crate, speed)

        local player = client

        if not isElement(player) then
            return
        end

        if not isShipmentCrate(crate) then
            return crateReject("ram", "not a shipment crate")
        end

        local vehicle = getPedOccupiedVehicle(player)

        if not vehicle
        or getVehicleController(vehicle) ~= player then
            return crateReject("ram", "player is not driving")
        end

        if not playerNearCrate(player, crate, CRATE_MAX_ACTION_DIST) then
            return crateReject("ram", "too far from crate")
        end

        speed = math.min(tonumber(speed) or 0, 400)

        if speed < CRATE_RAM_MIN_SPEED then
            return crateReject("ram", "too slow (" .. math.floor(speed) .. " km/h)")
        end

        local now = getTickCount()

        if lastRamHit[player]
        and now - lastRamHit[player] < CRATE_RAM_COOLDOWN then
            return
        end

        lastRamHit[player] = now

        local damage =
            math.min(
                CRATE_RAM_MAX_DAMAGE,
                math.max(
                    5,
                    math.floor(speed * CRATE_RAM_DAMAGE_PER_KMH)
                )
            )

        damageCrate(
            crate,
            damage,
            "rammed by " .. getPlayerName(player) .. " at " .. math.floor(speed) .. " km/h"
        )

    end
)


-- MELEE

addEvent(
    "shipment:crateMelee",
    true
)

addEventHandler(
    "shipment:crateMelee",
    root,
    function(crate)

        local player = client

        if not isElement(player) then
            return
        end

        if not isShipmentCrate(crate) then
            return crateReject("melee", "not a shipment crate")
        end

        if getPedOccupiedVehicle(player) then
            return crateReject("melee", "player is in a vehicle")
        end

        if carryingCrate[player] then
            return crateReject("melee", "player is carrying a crate")
        end

        -- can't hit a crate somebody is carrying
        if getElementData(
            crate,
            "shipment:carriedBy"
        ) then
            return crateReject("melee", "crate is being carried")
        end

        if not playerNearCrate(player, crate, CRATE_MELEE_MAX_DIST) then
            return crateReject("melee", "too far from crate")
        end

        local now = getTickCount()

        if lastMeleeHit[player]
        and now - lastMeleeHit[player] < CRATE_MELEE_COOLDOWN then
            return
        end

        local weapon = getPedWeapon(player)

        local damage =
            CRATE_MELEE_DAMAGE[weapon]

        if not damage then

            local slot = getSlotFromWeapon(weapon)

            if slot ~= 0 and slot ~= 1 then
                return crateReject("melee", "weapon " .. tostring(weapon) .. " is not melee")
            end

            damage = CRATE_MELEE_DEFAULT

        end

        lastMeleeHit[player] = now

        damageCrate(
            crate,
            damage,
            "hit by melee from " .. getPlayerName(player)
        )

    end
)


addEventHandler(
    "onPlayerQuit",
    root,
    function()

        lastRamHit[source]   = nil
        lastMeleeHit[source] = nil

    end
)


local TAKEOVER_DURATION = 30 * 1000


--------------------------------------------------
-- START TAKEOVER
--------------------------------------------------

function startShipmentTakeover(
    player,
    newOwner
)

    if not ActiveShipment then

        outputChatBox(
            "[SHIPMENT] No active shipment.",
            player,
            255, 100, 100
        )

        return false

    end


    --------------------------------------------------
    -- CHECK CURRENT STATE
    --------------------------------------------------

    if ActiveShipment.state == "completed"
    or ActiveShipment.state == "destroyed"
    or ActiveShipment.state == "expired" then

        outputChatBox(
            "[SHIPMENT] This shipment can no longer be taken over.",
            player,
            255, 100, 100
        )

        return false

    end


    --------------------------------------------------
    -- CHECK EXISTING TAKEOVER
    --------------------------------------------------

    if ActiveShipment.takeover
    and ActiveShipment.takeover.active then

        outputChatBox(
            "[SHIPMENT] A takeover is already in progress.",
            player,
            255, 200, 0
        )

        return false

    end


    --------------------------------------------------
    -- PREVENT SAME OWNER
    --------------------------------------------------

    if ActiveShipment.owner == newOwner then

        outputChatBox(
            "[SHIPMENT] You already control this shipment.",
            player,
            255, 200, 0
        )

        return false

    end


    --------------------------------------------------
    -- CREATE TAKEOVER DATA
    --------------------------------------------------

    local now =
        getTickCount()

    ActiveShipment.takeover = {

        active = true,

        startedAt = now,

        endsAt =
            now
            + TAKEOVER_DURATION,

        newOwner = newOwner,

        player = player

    }


    --------------------------------------------------
    -- CHANGE STATE
    --------------------------------------------------

    ActiveShipment.previousState =
        ActiveShipment.state

    ActiveShipment.state =
        "captured"


    --------------------------------------------------
    -- NOTIFY PLAYER
    --------------------------------------------------

    outputChatBox(
        "[SHIPMENT] Takeover started!",
        player,
        255, 200, 0
    )

    outputChatBox(
        "[SHIPMENT] Hold the shipment for 30 seconds.",
        player,
        255, 200, 0
    )


    --------------------------------------------------
    -- TAKEOVER TIMER
    --------------------------------------------------

    ActiveShipment.takeover.timer =
        setTimer(
            completeShipmentTakeover,
            TAKEOVER_DURATION,
            1
        )


    outputDebugString(
        "[SHIPMENT] Takeover started."
    )

    outputDebugString(
        "[SHIPMENT] Current owner: "
        .. tostring(
            ActiveShipment.owner
        )
    )

    outputDebugString(
        "[SHIPMENT] New owner: "
        .. tostring(newOwner)
    )

    return true

end


--------------------------------------------------
-- CANCEL TAKEOVER
--------------------------------------------------

function cancelShipmentTakeover(
    player
)

    if not ActiveShipment then

        outputChatBox(
            "[SHIPMENT] No active shipment.",
            player,
            255, 100, 100
        )

        return false

    end


    if not ActiveShipment.takeover
    or not ActiveShipment.takeover.active then

        outputChatBox(
            "[SHIPMENT] No takeover is currently active.",
            player,
            255, 200, 0
        )

        return false

    end


    --------------------------------------------------
    -- STOP TIMER
    --------------------------------------------------

    if isTimer(
        ActiveShipment.takeover.timer
    ) then

        killTimer(
            ActiveShipment.takeover.timer
        )

    end


    --------------------------------------------------
    -- RESTORE STATE
    --------------------------------------------------

    ActiveShipment.state =
        ActiveShipment.previousState
        or "in_transit"


    --------------------------------------------------
    -- CLEAR TAKEOVER
    --------------------------------------------------

    ActiveShipment.takeover = {

        active = false,

        startedAt = nil,

        endsAt = nil,

        newOwner = nil,

        player = nil,

        timer = nil

    }


    --------------------------------------------------
    -- MESSAGE
    --------------------------------------------------

    outputChatBox(
        "[SHIPMENT] Takeover cancelled.",
        player,
        0, 255, 0
    )


    outputDebugString(
        "[SHIPMENT] Takeover cancelled."
    )


    return true

end


--------------------------------------------------
-- COMPLETE TAKEOVER
--------------------------------------------------

function completeShipmentTakeover()

    if not ActiveShipment then
        return false
    end


    --------------------------------------------------
    -- CHECK TAKEOVER
    --------------------------------------------------

    if not ActiveShipment.takeover
    or not ActiveShipment.takeover.active then

        return false

    end


    local takeover =
        ActiveShipment.takeover


    --------------------------------------------------
    -- TRANSFER OWNERSHIP
    --------------------------------------------------

    local oldOwner =
        ActiveShipment.owner

    local newOwner =
        takeover.newOwner


    ActiveShipment.owner =
        newOwner


    --------------------------------------------------
    -- RESTORE SHIPMENT STATE
    --------------------------------------------------

    ActiveShipment.state =
        takeover.previousState
        or "in_transit"


    --------------------------------------------------
    -- CLEAR TAKEOVER
    --------------------------------------------------

    ActiveShipment.takeover = {

        active = false,

        startedAt = nil,

        endsAt = nil,

        newOwner = nil,

        player = nil,

        timer = nil

    }


    --------------------------------------------------
    -- NOTIFY PLAYER
    --------------------------------------------------

    if isElement(
        takeover.player
    ) then

        outputChatBox(
            "[SHIPMENT] Takeover successful!",
            takeover.player,
            0, 255, 0
        )

        outputChatBox(
            "[SHIPMENT] You now control the shipment.",
            takeover.player,
            0, 255, 0
        )

    end


    --------------------------------------------------
    -- DEBUG
    --------------------------------------------------

    outputDebugString(
        "[SHIPMENT] Takeover completed."
    )

    outputDebugString(
        "[SHIPMENT] Previous owner: "
        .. tostring(oldOwner)
    )

    outputDebugString(
        "[SHIPMENT] New owner: "
        .. tostring(newOwner)
    )


    return true

end
