addEventHandler("onResourceStart",getResourceRootElement(getThisResource()),
    function()
        call(getResourceFromName("scoreboard"),"addScoreboardColumn","FPS")
    end
)