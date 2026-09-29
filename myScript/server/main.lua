addCommandHandler("startshipment", function(player)

    -------------------------------------------------
    -- TEST MODE
    -------------------------------------------------

    if ShipmentConfig.testMode then

        local organization = {
            id = 1,
            name = "Test Organization"
        }

        local success, result = createShipment(organization)


        -------------------------------------------------
        -- FAILED
        -------------------------------------------------

        if not success then

            outputChatBox(
                "[SHIPMENT] Failed to start shipment.",
                player,
                255,
                0,
                0
            )

            outputChatBox(
                "[SHIPMENT] Reason: "
                .. tostring(result),
                player,
                255,
                100,
                100
            )

            outputDebugString(
                "[SHIPMENT] START FAILED: "
                .. tostring(result),
                1
            )

            return
        end


        -------------------------------------------------
        -- SUCCESS
        -------------------------------------------------

        outputChatBox(
            "[SHIPMENT] Test shipment started!",
            player,
            0,
            255,
            0
        )

        outputChatBox(
            "[SHIPMENT] Vehicle: "
            .. tostring(result.vehicle.name),
            player,
            255,
            255,
            255
        )

        outputChatBox(
            "[SHIPMENT] Crates: "
            .. tostring(result.cargo.total),
            player,
            255,
            255,
            255
        )

        return
    end

end)

-------------------------------------------------
-- TEMPORARY STOP SHIPMENT COMMAND
-- LOCALHOST TESTING ONLY
-------------------------------------------------

addCommandHandler("stopshipment", function(player)

    -------------------------------------------------
    -- CHECK ACTIVE SHIPMENT
    -------------------------------------------------

    local shipment = getActiveShipment()

    if not shipment then

        outputChatBox(
            "[SHIPMENT] There is no active shipment.",
            player,
            255,
            0,
            0
        )

        return
    end


    -------------------------------------------------
    -- STOP SHIPMENT
    -------------------------------------------------

    destroyShipment("Manually stopped for testing.")


    -------------------------------------------------
    -- NOTIFY PLAYER
    -------------------------------------------------

    outputChatBox(
        "[SHIPMENT] Current shipment has been stopped.",
        player,
        255,
        200,
        0
    )

    outputChatBox(
        "[SHIPMENT] Global cooldown has started.",
        player,
        255,
        200,
        0
    )

end)

-------------------------------------------------
-- SET SHIPMENT TEST LOCATION
-------------------------------------------------

addCommandHandler("setshipmentpos", function(player, command, locationType)

    if not ShipmentConfig.testMode then
        outputChatBox(
            "[SHIPMENT] Test mode is disabled.",
            player,
            255,
            0,
            0
        )

        return
    end


    -------------------------------------------------
    -- CHECK LOCATION TYPE
    -------------------------------------------------

    if locationType ~= "pickup"
    and locationType ~= "destination" then

        outputChatBox(
            "[SHIPMENT] Usage: /setshipmentpos pickup",
            player,
            255,
            255,
            255
        )

        outputChatBox(
            "[SHIPMENT] Usage: /setshipmentpos destination",
            player,
            255,
            255,
            255
        )

        return
    end


    -------------------------------------------------
    -- GET PLAYER POSITION
    -------------------------------------------------

    local x, y, z = getElementPosition(player)

    local interior = getElementInterior(player)
    local dimension = getElementDimension(player)


    -------------------------------------------------
    -- SAVE LOCATION
    -------------------------------------------------

    ShipmentConfig.testLocations[locationType] = {
        x = x,
        y = y,
        z = z,

        interior = interior,
        dimension = dimension
    }


    -------------------------------------------------
    -- OUTPUT
    -------------------------------------------------

    outputChatBox(
        "[SHIPMENT] "
        .. locationType
        .. " location saved.",
        player,
        0,
        255,
        0
    )

    outputChatBox(
        string.format(
            "[SHIPMENT] X: %.4f | Y: %.4f | Z: %.4f",
            x,
            y,
            z
        ),
        player,
        255,
        255,
        255
    )

    outputChatBox(
        "[SHIPMENT] Interior: "
        .. interior
        .. " | Dimension: "
        .. dimension,
        player,
        255,
        255,
        255
    )

end)