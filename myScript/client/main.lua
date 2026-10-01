--------------------------------------------------
-- SHIPMENT CLIENT
--------------------------------------------------

--------------------------------------------------
-- DRAW CRATE HEALTH
--------------------------------------------------

addEventHandler(
    "onClientRender",
    root,
    function()

        local objects =
            getElementsByType("object", root, true)

        for _, crate in ipairs(objects) do

            if isElement(crate)
            and getElementData(
                crate,
                "shipment:crate"
            ) == true then

                local health =
                    tonumber(
                        getElementData(
                            crate,
                            "shipment:crateHealth"
                        )
                    ) or 0

                local x, y, z =
                    getElementPosition(crate)

                -- Draw slightly above the crate
                z = z + 1.2

                local sx, sy =
                    getScreenFromWorldPosition(
                        x,
                        y,
                        z
                    )

                if sx and sy then

                    --------------------------------------------------
                    -- HEALTH TEXT
                    --------------------------------------------------

                    local healthText =
                        string.format(
                            "%d%%",
                            math.floor(health)
                        )

                    dxDrawText(
                        "CRATE",
                        sx,
                        sy - 24,
                        sx,
                        sy - 24,
                        tocolor(
                            255,
                            255,
                            255,
                            255
                        ),
                        1.0,
                        "default-bold",
                        "center",
                        "center"
                    )

                    dxDrawText(
                        healthText,
                        sx,
                        sy,
                        sx,
                        sy,
                        tocolor(
                            255,
                            255,
                            255,
                            255
                        ),
                        1.0,
                        "default-bold",
                        "center",
                        "center"
                    )

                    --------------------------------------------------
                    -- HEALTH BAR
                    --------------------------------------------------

                    local barWidth = 70
                    local barHeight = 7

                    local barX =
                        sx - (barWidth / 2)

                    local barY =
                        sy + 15

                    -- Background
                    dxDrawRectangle(
                        barX,
                        barY,
                        barWidth,
                        barHeight,
                        tocolor(
                            0,
                            0,
                            0,
                            180
                        )
                    )

                    -- Health
                    local healthWidth =
                        barWidth
                        * math.max(
                            0,
                            math.min(
                                health / 100,
                                1
                            )
                        )

                    dxDrawRectangle(
                        barX,
                        barY,
                        healthWidth,
                        barHeight,
                        tocolor(
                            0,
                            200,
                            0,
                            220
                        )
                    )

                end

            end

        end

    end
)

--------------------------------------------------
-- INTERACTION
--------------------------------------------------

local INTERACTION_DISTANCE = 3.0


local function isNearElement(element, distance)

    if not element
    or not isElement(element) then
        return false
    end

    local px, py, pz =
        getElementPosition(localPlayer)

    local ex, ey, ez =
        getElementPosition(element)

    local currentDistance =
        getDistanceBetweenPoints3D(
            px, py, pz,
            ex, ey, ez
        )

    return currentDistance <= distance

end


bindKey(
    "e",
    "down",
    function()

        --------------------------------------------------
        -- 1. SHIPMENT NPC
        --------------------------------------------------

        local nearbyNPC = nil

        for _, ped in ipairs(
            getElementsByType("ped")
        ) do

            if isElement(ped)
            and getElementData(
                ped,
                "shipment:npc"
            ) == true then

                if isNearElement(
                    ped,
                    INTERACTION_DISTANCE
                ) then

                    nearbyNPC = ped
                    break

                end

            end

        end


        if nearbyNPC then

            triggerServerEvent(
                "shipment:requestStart",
                localPlayer
            )

            return

        end


        --------------------------------------------------
        -- 2. SHIPMENT CRATE
        --------------------------------------------------

        local nearbyCrate = nil

        for _, object in ipairs(
            getElementsByType("object")
        ) do

            if isElement(object)
            and getElementData(
                object,
                "shipment:crate"
            ) == true then

                if isNearElement(
                    object,
                    INTERACTION_DISTANCE
                ) then

                    nearbyCrate = object
                    break

                end

            end

        end


        if nearbyCrate then

            triggerServerEvent(
                "shipment:cargoInteraction",
                localPlayer
            )

            return

        end


        --------------------------------------------------
        -- 3. SHIPMENT VEHICLE
        --------------------------------------------------

        local nearbyVehicle = nil

        for _, vehicle in ipairs(
            getElementsByType("vehicle")
        ) do

            if isElement(vehicle)
            and getElementData(
                vehicle,
                "shipment:vehicle"
            ) == true then

                if isNearElement(
                    vehicle,
                    INTERACTION_DISTANCE
                ) then

                    nearbyVehicle = vehicle
                    break

                end

            end

        end


        if nearbyVehicle then

            triggerServerEvent(
                "shipment:cargoInteraction",
                localPlayer
            )

            return

        end


        --------------------------------------------------
        -- 4. DELIVERY CHECKPOINT
        --------------------------------------------------

        local nearbyCheckpoint = nil

        for _, marker in ipairs(
            getElementsByType("marker")
        ) do

            if isElement(marker)
            and getElementData(
                marker,
                "shipment:delivery"
            ) == true then

                if isNearElement(
                    marker,
                    7.0
                ) then

                    nearbyCheckpoint = marker
                    break

                end

            end

        end


        if nearbyCheckpoint then

            triggerServerEvent(
                "shipment:deliveryInteraction",
                localPlayer
            )

            return

        end

    end
)
