-- CLIENT: detects the local player damaging shipment crates
-- (bullets, vehicle ramming, melee) and reports them to the server.
-- Explosions are handled entirely on the server.

local DEBUG = false   -- set to false once everything works

local MELEE_RANGE      = 1.8   -- reach from the crate's surface
local MELEE_ARC        = 90    -- degrees either side of facing direction
local MELEE_COOLDOWN   = 400   -- ms between swings

local RAM_MIN_SPEED    = 8     -- km/h
local RAM_COOLDOWN     = 700   -- ms
local RAM_MARGIN       = 0.3   -- extra reach around vehicle + crate

local function debugMsg(text)
    if DEBUG then
        outputChatBox("[SHIPMENT-CLIENT] " .. text, 0, 255, 0)
    end
end

local function isCrate(element)
    return isElement(element)
        and getElementType(element) == "object"
        and getElementData(element, "shipment:crate") == true
end

-- half size (in the horizontal plane) of an element's bounding box
local function halfExtents(element)
    local minX, minY, _, maxX, maxY = getElementBoundingBox(element)
    if not minX then
        return 1, 1
    end
    return (maxX - minX) / 2, (maxY - minY) / 2
end

debugMsg("crate_damage.lua loaded")


--------------------------------------------------
-- BULLETS
--------------------------------------------------

addEventHandler(
    "onClientPlayerWeaponFire",
    localPlayer,
    function(weapon, ammo, ammoInClip, hitX, hitY, hitZ, hitElement, startX, startY, startZ)

        local target = hitElement

        -- fallback: if the engine gave no hit element, trace the bullet ourselves
        if not target then

            local dx, dy, dz = hitX - startX, hitY - startY, hitZ - startZ
            local len = math.sqrt(dx * dx + dy * dy + dz * dz)

            if len > 0 then
                local ex = hitX + (dx / len) * 0.5
                local ey = hitY + (dy / len) * 0.5
                local ez = hitZ + (dz / len) * 0.5

                local hit, _, _, _, el = processLineOfSight(
                    startX, startY, startZ,
                    ex, ey, ez,
                    true, true, true, true,
                    false, false, false, false,
                    localPlayer
                )

                if hit then
                    target = el
                end
            end
        end

        if isCrate(target) then
            debugMsg("bullet hit crate")
            triggerServerEvent("shipment:crateHit", resourceRoot, target)
        end

    end
)


--------------------------------------------------
-- VEHICLE RAMMING
-- Two detectors feed the same report: the collision event, and a
-- per-frame box-overlap check (in case the event doesn't fire for objects).
--------------------------------------------------

local speedSamples = {}      -- recent {time, speed}
local lastFastVel  = nil     -- {vx, vy, time} while moving fast
local lastRamReport = 0

local function vehicleSpeedKmh(vehicle)
    local vx, vy, vz = getElementVelocity(vehicle)
    return math.sqrt(vx * vx + vy * vy + vz * vz) * 180, vx, vy
end

-- fastest speed over the last ~300 ms (impact speed, before the crash slows us)
local function recentPeakSpeed()
    local now = getTickCount()
    local peak = 0
    for i = #speedSamples, 1, -1 do
        local sample = speedSamples[i]
        if now - sample[1] > 300 then
            table.remove(speedSamples, i)
        elseif sample[2] > peak then
            peak = sample[2]
        end
    end
    return peak
end

local function reportRam(crate, why)
    local now = getTickCount()
    if now - lastRamReport < RAM_COOLDOWN then
        return
    end

    local peak = recentPeakSpeed()
    if peak < RAM_MIN_SPEED then
        return
    end

    lastRamReport = now
    debugMsg("rammed crate (" .. why .. ") at " .. math.floor(peak) .. " km/h")
    triggerServerEvent("shipment:crateRam", resourceRoot, crate, peak)
end

addEventHandler(
    "onClientVehicleCollision",
    root,
    function(hitElement, force)

        if getVehicleController(source) ~= localPlayer then
            return
        end

        if isCrate(hitElement) then
            reportRam(hitElement, "collision event")
        end

    end
)


--------------------------------------------------
-- MELEE + per-frame ram check
--------------------------------------------------

local lastSwing = 0
local wasFiring = false

local function checkMelee()

    local firing = getControlState("fire")

    -- act only on the moment the fire button goes down
    if not firing or wasFiring then
        wasFiring = firing
        return
    end

    wasFiring = true

    if isPedInVehicle(localPlayer) then
        return
    end

    -- melee = fists (slot 0) or slot 1 weapons
    local slot = getPedWeaponSlot(localPlayer)

    if slot ~= 0 and slot ~= 1 then
        return
    end

    local now = getTickCount()

    if now - lastSwing < MELEE_COOLDOWN then
        return
    end

    lastSwing = now

    local px, py, pz = getElementPosition(localPlayer)
    local _, _, rot  = getElementRotation(localPlayer)

    local best, bestReach

    for _, obj in ipairs(getElementsByType("object", root, true)) do

        if isCrate(obj)
        and not getElementData(obj, "shipment:carriedBy") then

            local cx, cy, cz = getElementPosition(obj)
            local hx, hy = halfExtents(obj)
            local radius = math.max(hx, hy)

            local dist = getDistanceBetweenPoints2D(px, py, cx, cy)
            local reach = dist - radius

            if reach <= MELEE_RANGE and math.abs(cz - pz) < 4 then

                -- heading from the player to the crate (MTA: 0 = north, 270 = east)
                local angleToCrate =
                    (math.deg(math.atan2(cy - py, cx - px)) - 90) % 360

                local diff =
                    math.abs(((angleToCrate - rot) + 180) % 360 - 180)

                -- if we're basically touching the crate, facing doesn't matter
                if (diff <= MELEE_ARC or reach <= 0.5)
                and (not bestReach or reach < bestReach) then
                    best, bestReach = obj, reach
                end

            end

        end

    end

    if best then
        debugMsg("melee hit crate")
        triggerServerEvent("shipment:crateMelee", resourceRoot, best)
    else
        debugMsg("melee swing: no crate in reach")
    end

end

local function checkRamOverlap(vehicle)

    local speed, vx, vy = vehicleSpeedKmh(vehicle)
    local now = getTickCount()

    speedSamples[#speedSamples + 1] = { now, speed }

    if speed >= RAM_MIN_SPEED then
        lastFastVel = { vx, vy, now }
    end

    -- need to have been moving fast within the last 300 ms
    if not lastFastVel or now - lastFastVel[3] > 300 then
        return
    end

    local m = getElementMatrix(vehicle)
    if not m then
        return
    end

    local right   = m[1]
    local forward = m[2]
    local pos     = m[4]

    local vhW, vhL = halfExtents(vehicle)

    for _, obj in ipairs(getElementsByType("object", root, true)) do

        if isCrate(obj) then

            local cx, cy, cz = getElementPosition(obj)

            local dx, dy, dz = cx - pos[1], cy - pos[2], cz - pos[3]

            if math.abs(dz) < 3
            and (dx * dx + dy * dy) < 100 then

                local hx, hy = halfExtents(obj)
                local crateR = math.max(hx, hy)

                local lat = dx * right[1]   + dy * right[2]    + dz * right[3]
                local lon = dx * forward[1] + dy * forward[2]  + dz * forward[3]

                -- crate must be in the direction we were travelling
                local towards = (lastFastVel[1] * dx + lastFastVel[2] * dy) > 0

                if towards
                and math.abs(lat) <= vhW + crateR + RAM_MARGIN
                and math.abs(lon) <= vhL + crateR + RAM_MARGIN then

                    reportRam(obj, "overlap")
                    return

                end

            end

        end

    end

end

addEventHandler(
    "onClientRender",
    root,
    function()

        checkMelee()

        local vehicle = getPedOccupiedVehicle(localPlayer)

        if vehicle and getVehicleController(vehicle) == localPlayer then
            checkRamOverlap(vehicle)
        end

    end
)
