--------------------------------------------------
-- SET SHIPMENT LOCATION
--------------------------------------------------

addCommandHandler(
    "setshipmentpos",
    function(player, command, locationType)

        if not ShipmentConfig.testMode then

            outputChatBox(
                "[SHIPMENT] Test mode is disabled.",
                player,
                255, 0, 0
            )

            return

        end


        if locationType ~= "pickup"
        and locationType ~= "destination" then

            outputChatBox(
                "[SHIPMENT] Usage:",
                player,
                255, 255, 255
            )

            outputChatBox(
                "/setshipmentpos pickup",
                player,
                255, 255, 255
            )

            outputChatBox(
                "/setshipmentpos destination",
                player,
                255, 255, 255
            )

            return

        end


        local x, y, z =
            getElementPosition(player)


        local interior =
            getElementInterior(player)


        local dimension =
            getElementDimension(player)


        ShipmentConfig.testLocations[
            locationType
        ] = {

            x = x,

            y = y,

            z = z,

            interior = interior,

            dimension = dimension

        }


        outputChatBox(
            "[SHIPMENT] "
            .. locationType
            .. " location saved!",
            player,
            0, 255, 0
        )


        outputChatBox(
            string.format(
                "[SHIPMENT] X: %.4f | Y: %.4f | Z: %.4f",
                x,
                y,
                z
            ),
            player,
            255, 255, 255
        )


        outputChatBox(
            "[SHIPMENT] Interior: "
            .. interior
            .. " | Dimension: "
            .. dimension,
            player,
            255, 255, 255
        )

    end
)


--------------------------------------------------
-- SHOW SHIPMENT LOCATIONS
--------------------------------------------------

addCommandHandler(
    "shipmentlocations",
    function(player)

        local pickup =
            ShipmentConfig.testLocations.pickup


        local destination =
            ShipmentConfig.testLocations.destination


        outputChatBox(
            "========== SHIPMENT LOCATIONS ==========",
            player,
            255, 200, 0
        )


        if pickup then

            outputChatBox(
                string.format(
                    "Pickup: %.4f, %.4f, %.4f",
                    pickup.x,
                    pickup.y,
                    pickup.z
                ),
                player,
                255, 255, 255
            )

        else

            outputChatBox(
                "Pickup: NOT SET",
                player,
                255, 100, 100
            )

        end


        if destination then

            outputChatBox(
                string.format(
                    "Destination: %.4f, %.4f, %.4f",
                    destination.x,
                    destination.y,
                    destination.z
                ),
                player,
                255, 255, 255
            )

        else

            outputChatBox(
                "Destination: NOT SET",
                player,
                255, 100, 100
            )

        end

    end
)


--------------------------------------------------
-- START SHIPMENT
--------------------------------------------------

addCommandHandler(
    "startshipment",
    function(player)

        local success, result =
            createShipment()


        if not success then

            outputChatBox(
                "[SHIPMENT] Failed to start shipment.",
                player,
                255, 0, 0
            )


            outputChatBox(
                "[SHIPMENT] Reason: "
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
            "[SHIPMENT] Shipment ID: "
            .. result.id,
            player,
            255, 255, 255
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


--------------------------------------------------
-- STOP SHIPMENT
--------------------------------------------------

addCommandHandler(
    "stopshipment",
    function(player)

        local shipment =
            getActiveShipment()


        if not shipment then

            outputChatBox(
                "[SHIPMENT] There is no active shipment.",
                player,
                255, 0, 0
            )

            return

        end


        destroyShipment(
            "Manually stopped for testing."
        )


        outputChatBox(
            "[SHIPMENT] Shipment stopped.",
            player,
            255, 200, 0
        )


        outputChatBox(
            "[SHIPMENT] 3-hour cooldown started.",
            player,
            255, 200, 0
        )

    end
)


--------------------------------------------------
-- CHECK COOLDOWN
--------------------------------------------------

addCommandHandler(
    "shipmentcooldown",
    function(player)

        local remaining =
            getShipmentCooldownRemaining()


        if remaining <= 0 then

            outputChatBox(
                "[SHIPMENT] No active cooldown.",
                player,
                0, 255, 0
            )

            return

        end


        local totalSeconds =
            math.ceil(
                remaining / 1000
            )


        local hours =
            math.floor(
                totalSeconds / 3600
            )


        local minutes =
            math.floor(
                (totalSeconds % 3600) / 60
            )


        local seconds =
            totalSeconds % 60


        outputChatBox(
            string.format(
                "[SHIPMENT] Cooldown: %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            ),
            player,
            255, 200, 0
        )

    end
)


--------------------------------------------------
-- RESET COOLDOWN
--------------------------------------------------

addCommandHandler(
    "resetshipmentcooldown",
    function(player)

        resetShipmentCooldown()


        outputChatBox(
            "[SHIPMENT] Cooldown reset.",
            player,
            0, 255, 0
        )

    end
)


--------------------------------------------------
-- SHIPMENT STATUS
--------------------------------------------------

addCommandHandler(
    "shipmentstatus",
    function(player)

        local shipment =
            getActiveShipment()


        if not shipment then

            outputChatBox(
                "[SHIPMENT] No active shipment.",
                player,
                255, 100, 100
            )

            return

        end


        outputChatBox(
            "========== SHIPMENT STATUS ==========",
            player,
            255, 200, 0
        )


        outputChatBox(
            "ID: "
            .. shipment.id,
            player,
            255, 255, 255
        )


        outputChatBox(
            "State: "
            .. shipment.state,
            player,
            255, 255, 255
        )


        outputChatBox(
            "Vehicle: "
            .. shipment.vehicle.name,
            player,
            255, 255, 255
        )


        outputChatBox(
            "Crates: "
            .. shipment.cargo.total,
            player,
            255, 255, 255
        )


        outputChatBox(
            "Vehicle Element: "
            .. tostring(
                isElement(
                    shipment.vehicle.element
                )
            ),
            player,
            255, 255, 255
        )

    end
)
