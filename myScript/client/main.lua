
bindKey(
    "e",
    "down",
    function()

        triggerServerEvent(
            "shipment:requestStart",
            localPlayer
        )

    end
)



addEvent(
    "shipment:stateChanged",
    true
)


addEventHandler(
    "shipment:stateChanged",
    root,
    function(shipmentId, state)

        outputChatBox(
            "[SHIPMENT] Shipment #"
            .. shipmentId
            .. " state: "
            .. state,
            255, 200, 0
        )

    end
)
