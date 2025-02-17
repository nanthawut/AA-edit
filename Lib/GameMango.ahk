#Requires AutoHotkey v2.0
#Include Image.ahk
global macroStartTime := A_TickCount
global stageStartTime := A_TickCount
global contractPageCounter := 0
global contractSwitchPattern := 0

LoadKeybindSettings()  ; Load saved keybinds
Hotkey(F1Key, (*) => moveRobloxWindow())
Hotkey(F2Key, (*) => StartMacro())
Hotkey(F3Key, (*) => Reload())
Hotkey(F4Key, (*) => TogglePause())
Hotkey("F5", (*) => RestartStage())
Hotkey("F6", (*) => mtstate())

mtstate(*) {
    AddToLog("MonitorStage By F6")
    MonitorStage()
}
StartMacro(*) {
    if (!ValidateMode()) {
        return
    }
    StartSelectedMode()
}

TogglePause(*) {
    Pause -1
    if (A_IsPaused) {
        AddToLog("Macro Paused")
        Sleep(1000)
    } else {
        AddToLog("Macro Resumed")
        Sleep(1000)
    }
}

PlacingUnits(wSlot, state?) {
    global successfulCoordinates, pointCounts

    placementPoints := PlacementPatternDropdown.Text = "Circle" ? GenerateCirclePoints() : PlacementPatternDropdown.Text =
        "Grid" ? GenerateGridPoints() : PlacementPatternDropdown.Text = "Spiral" ? GenerateMoreGridPoints(5) :
            PlacementPatternDropdown.Text = "Up and Down" ? GenerateUpandDownPoints() : GenerateRandomPoints()
    slotNumCheck := 0
    ; Go through each slot
    for slotNum in wSlot {

        ; Get number of placements wanted for this slot
        placements := uIUnitSetting.placement[slotNum].Text
        maxUnit := uIUnitSetting.maxUnit[slotNum].Text
        placedCounts := 0
        for placed in successfulCoordinates {
            if (placed.slot = slotNum)
                placedCounts++
        }

        placements := state = "f" ? Integer(placements) : Integer(maxUnit) - placedCounts
        ; If enabled, place all units for this slot
        if (placements > 0) {
            AddToLog("Placing Unit " slotNum " (" placedCounts "/" placements ")")

            ; Place all units for this slot
            while (placedCounts < placements) {
                for point in placementPoints {
                    strPoint := "" point.x point.y

                    ; Skip if this coordinate was already used successfully
                    alreadyUsed := false
                    for coord in successfulCoordinates {
                        if (coord.x = point.x && coord.y = point.y) {
                            alreadyUsed := true
                            break
                        }
                    }
                    if (pointCounts.Count >= placementPoints.Length) {
                        pointCounts.Clear()
                        if (slotNumCheck = slotNum) {
                            placementPoints := GenerateMoreGridPoints(10)
                        } else {
                            slotNumCheck := slotNum
                        }
                    }

                    if !pointCounts.Has(strPoint)
                        pointCounts[strPoint] := 0

                    if (alreadyUsed || pointCounts[strPoint] > 0)
                        continue
                    if CheckForXp()
                        return MonitorStage()
                    CheckEndAndRoute()
                    CheckForCardSelection()
                    pointCounts[strPoint]++

                    if PlaceUnit(point.x, point.y, slotNum) {
                        successfulCoordinates.Push({ x: point.x, y: point.y, slot: slotNum, maxLevel: false })
                        placedCounts++
                        AddToLog("Placed Unit " slotNum " (" placedCounts "/" placements ")")

                        CheckAbility()
                        FixClick(560, 560) ; Move Click
                        CheckForCardSelection()

                        break
                    }
                    Reconnect()
                    if (state = "l")
                        UpgradeUnits("m", true)
                }
            }

        }
    }

    AddToLog("All units placed to requested amounts")
    UpgradeUnits(state, false)
}

UpgradeUnits(state, oneTick) {
    global successfulCoordinates, AverageUpgrade
    totalUnits := Map()
    upgradedCount := Map()
    hasSuccessAll := true
    for coord in successfulCoordinates {
        if (!coord.maxLevel) {
            hasSuccessAll := false
        }
        ; Initialize counters
        if (!totalUnits.Has(coord.slot)) {
            totalUnits[coord.slot] := 0
            upgradedCount[coord.slot] := 0
        }
        totalUnits[coord.slot]++
    }

    if (hasSuccessAll)
        return

    AddToLog("Initiating Unit Upgrades...")

    AddToLog("Using priority upgrade system")

    ; Go through each priority level (1-6)
    for priorityNum in [1, 2, 3, 4, 5, 6] {
        ; Find which slot has this priority number
        loop {
            unitFinish := true
            for index, coord in successfulCoordinates {
                if (uIUnitSetting.priority[coord.slot].Text = priorityNum) {

                    if CheckForXp() {
                        AddToLog("Stage ended during upgrades, proceeding to results")
                        successfulCoordinates := []
                        MonitorStage()
                        return
                    }
                    Reconnect()
                    CheckEndAndRoute()

                    if (!coord.maxLevel) {
                        CheckForCardSelection()
                        UpgradeUnit(coord.x, coord.y)
                        unitFinish := false
                        if MaxUpgrade() {
                            upgradedCount[coord.slot]++
                            AddToLog("Max upgrade reached for Unit " coord.slot " (" upgradedCount[coord.slot
                                ] "/" totalUnits[coord.slot] ")")
                            successfulCoordinates[index].maxLevel := true
                            Sleep (100)
                            FixClick(325, 185) ;Close upg menu
                            if (oneTick)
                                return

                            break
                        }
                        if (oneTick) {
                            FixClick(560, 560)
                            return
                        }

                        CheckAbility()
                        FixClick(560, 560) ; Move Click
                        Reconnect()
                        CheckEndAndRoute()
                        if (!AverageUpgrade.Value) {
                            break
                        }
                    }
                }
            }
            if unitFinish {
                AddToLog("Finished upgrades for priority " priorityNum)
                break

            }
        }
    }

    if (state = "l") {
        AddToLog("Priority upgrading completed")
    }
    return
}

ChallengeMode() {
    AddToLog("Moving to Challenge mode")
    ChallengeMovement()

    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        ChallengeMovement()
    }

    RestartStage()
}

StoryMode() {

    ; Get current map and act
    currentStoryMap := MDo.Story.UI.Text
    currentStoryAct := MDo.Story.Act.Text

    ; Execute the movement pattern
    AddToLog("Moving to position for " currentStoryMap)
    StoryMovement()

    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        StoryMovement()
    }
    AddToLog("Starting " currentStoryMap " - " currentStoryAct)
    StartStory(currentStoryMap, currentStoryAct)

    ; Handle play mode selection
    if (MDo.Story.Act.Text != "Infinity") {
        PlayHere()  ; Always PlayHere for normal story acts
    } else {
        if (MatchMaking.Value) {
            FindMatch()
        } else {
            PlayHere()
        }
    }

    RestartStage()
}

LegendMode() {

    ; Get current map and act
    currentLegendMap := MDo.Legend.UI.Text
    currentLegendAct := MDo.Legend.Act.Text

    ; Execute the movement pattern
    AddToLog("Moving to position for " currentLegendMap)
    StoryMovement()

    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        StoryMovement()
    }
    AddToLog("Starting " currentLegendMap " - " currentLegendAct)
    StartLegend(currentLegendMap, currentLegendAct)

    ; Handle play mode selection
    if (MatchMaking.Value) {
        FindMatch()
    } else {
        PlayHere()
    }

    RestartStage()
}

RaidMode() {
    ; Get current map and act
    currentRaidMap := MDo.Raid.Text
    currentRaidAct := MDo.Raid.Act.Text

    ; Execute the movement pattern
    AddToLog("Moving to position for " currentRaidMap)
    RaidMovement()

    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        RaidMovement()
    }
    AddToLog("Starting " currentRaidMap " - " currentRaidAct)
    StartRaid(currentRaidMap, currentRaidAct)
    ; Handle play mode selection
    if (MatchMaking.Value) {
        FindMatch()
    } else {
        PlayHere()
    }

    RestartStage()
}

InfinityCastleMode() {

    ; Get current difficulty
    currentDifficulty := MDo.Infinity_Castle.Text

    ; Execute the movement pattern
    AddToLog("Moving to position for Infinity Castle")
    InfCastleMovement()

    ; Start stage
    while !(ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        InfCastleMovement()
    }
    AddToLog("Starting Infinity Castle - " currentDifficulty)

    ; Select difficulty with direct clicks
    if (currentDifficulty = "Normal") {
        FixClick(418, 375)  ; Click Easy Mode
    } else {
        FixClick(485, 375)  ; Click Hard Mode
    }

    ;Start Inf Castle
    if (ok := FindText(&X, &Y, 325, 520, 489, 587, 0, 0, ModeCancel)) {
        ClickUntilGone(0, 0, 325, 520, 489, 587, ModeCancel, -10, -120)
    }

    RestartStage()
}

WinterEvent() {
    ; Execute the movement pattern
    AddToLog("Moving to position for Winter Event")
    WinterEventMovement()

    ; Start stage
    while !(ok := FindText(&X, &Y, 468 - 150000, 386 - 150000, 468 + 150000, 386 + 150000, 0, 0, JoinMatchmaking)) {
        WinterEventMovement()
    }

    ; Handle play mode selection
    if (MatchMaking.Value) {
        FindMatch()
    } else {
        PlayHere()
    }

    AddToLog("Starting Winter Event")
    RestartStage()
}

CursedWombMode() {
    AddToLog("Moving to Cursed womb")
    CursedWombMovement()

    while !(ok := FindText(&X, &Y, 445, 440, 650, 487, 0, 0, Capacity)) {
        if (ok := FindText(&X, &Y, 434 - 150000, 383 - 150000, 434 + 150000, 383 + 150000, 0, 0, RobuxPurchaseKey)) {
            AddToLog("Found Key Purchase Attempt")
            Sleep 50000
        }
        CursedWombMovement()
    }

    FixClick(500, 190)
    SendInput("Key (Cursed Womb)")
    sleep (1000)
    FixClick(215, 285)
    sleep (500)
    FixClick(345, 370)
    sleep (500)

    RestartStage()
}

ContractMode() {
    Sleep(15000)
    FixClick(33, 400)
    Sleep(2500)
    HandleContractJoin()
    Sleep(2500)
    RestartStage()
}

PortalMode() {
    HandlePortalJoin()
    Sleep(2500)
    RestartStage()
}

MonitorEndScreen() {
    global mode, ReturnLobbyBox, MatchMaking, challengeStartTime, inChallengeMode

    loop {
        Sleep(3000)

        FixClick(560, 560)
        FixClick(560, 560)

        if (ok := FindText(&X, &Y, 300, 190, 360, 250, 0, 0, UnitExit)) {
            ClickUntilGone(0, 0, 300, 190, 360, 250, UnitExit, -4, -35)
        }

        if (ok := FindText(&X, &Y, 260, 400, 390, 450, 0, 0, NextText)) {
            ClickUntilGone(0, 0, 260, 400, 390, 450, NextText, 0, -40)
        }

        ; Now handle each mode
        if (ok := FindText(&X, &Y, 80, 85, 739, 224, 0, 0, LobbyText) or (ok := FindText(&X, &Y, 80, 85, 739, 224,
            0, 0,
            LobbyText2))) {
            AddToLog("Found Lobby Text - Current Mode: " (inChallengeMode ? "Challenge" : mode))
            Sleep(2000)

            ; Challenge mode logic first
            if (inChallengeMode) {
                AddToLog("Challenge completed - returning to " mode " mode")
                inChallengeMode := false
                challengeStartTime := A_TickCount
                ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                return CheckLobby()
            }

            ; Check if it's time for challenge mode
            if (!inChallengeMode && ChallengeBox.Value) {
                timeElapsed := A_TickCount - challengeStartTime
                if (timeElapsed >= 1800000) {
                    AddToLog("30 minutes passed - switching to Challenge mode")
                    inChallengeMode := true
                    challengeStartTime := A_TickCount
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                    return CheckLobby()
                }
            }

            if (mode = "Story") {
                AddToLog("Handling Story mode end")
                if (MDo.Story.Act.Text != "Infinity") {
                    if (NextLevelBox.Value && lastResult = "win") {
                        AddToLog("Next level")
                        ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +260, -35, LobbyText2)
                    } else {
                        AddToLog("Replay level")
                        ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +120, -35, LobbyText2)
                    }
                } else {
                    AddToLog("Story Infinity replay")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +120, -35, LobbyText2)
                }
                return RestartStage()
            }
            else if (mode = "Raid") {
                AddToLog("Handling Raid end")
                if (ReturnLobbyBox.Value) {
                    AddToLog("Return to lobby")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                    return CheckLobby()
                } else {
                    AddToLog("Replay raid")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +120, -35, LobbyText2)
                    return RestartStage()
                }
            }
            else if (mode = "Infinity Castle") {
                AddToLog("Handling Infinity Castle end")
                if (lastResult = "win") {
                    AddToLog("Next floor")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +120, -35, LobbyText2)
                } else {
                    AddToLog("Restart floor")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +120, -35, LobbyText2)
                }
                return RestartStage()
            }
            else if (mode = "Cursed Womb") {
                AddToLog("Handling Cursed Womb End")
                AddToLog("Returning to lobby")
                ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                return CheckLobby()
            }
            else {
                AddToLog("Handling end case")
                if (ReturnLobbyBox.Value) {
                    AddToLog("Return to lobby enabled")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                    return CheckLobby()
                } else {
                    AddToLog("Replaying")
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +120, -35, LobbyText2)
                    return RestartStage()
                }
            }
        }

        Reconnect()
    }
}

MonitorStage() {
    global Wins, loss, mode

    lastClickTime := A_TickCount

    loop {
        Sleep(1000)

        if (mode = "Story" && MDo.Story.Act.Text = "Infinity" || MDo.UI.Text = "Winter Event") {
            timeElapsed := A_TickCount - lastClickTime
            if (timeElapsed >= 300000) {  ; 5 minutes
                AddToLog("Performing anti-AFK click")
                FixClick(560, 560)  ; Move click
                lastClickTime := A_TickCount
            }
        }

        if (MDo.UI.Text = "Winter Event") {
            CheckForCardSelection()
        }

        ; Check for XP screen
        if CheckForXp() {
            AddToLog("Checking win/loss status")

            ; Calculate stage end time here, before checking win/loss
            stageEndTime := A_TickCount
            stageLength := FormatStageTime(stageEndTime - stageStartTime)

            if (ok := FindText(&X, &Y, 300, 190, 360, 250, 0, 0, UnitExit)) {
                ClickUntilGone(0, 0, 300, 190, 360, 250, UnitExit, -4, -35)
            }

            ; Check for Victory or Defeat
            if (ok := FindText(&X, &Y, 150, 180, 350, 260, 0, 0, VictoryText) or (ok := FindText(&X, &Y, 150, 180,
                350,
                260, 0, 0, VictoryText2))) {
                AddToLog("Victory detected - Stage Length: " stageLength)
                Wins += 1
                SendWebhookWithTime(true, stageLength)
                if (mode = "Portal") {
                    return HandlePortalEnd()
                } else if (mode = "Contract") {
                    return HandleContractEnd()
                } else {
                    return MonitorEndScreen()
                }
            }
            else if (ok := FindText(&X, &Y, 150, 180, 350, 260, 0, 0, DefeatText) or (ok := FindText(&X, &Y, 150,
                180,
                350, 260, 0, 0, DefeatText2))) {
                AddToLog("Defeat detected - Stage Length: " stageLength)
                loss += 1
                SendWebhookWithTime(false, stageLength)
                if (mode = "Portal") {
                    return HandlePortalEnd()
                } else if (mode = "Contract") {
                    return HandleContractEnd()
                } else {
                    return MonitorEndScreen()
                }
            }
        }
        Reconnect()
    }
}

StoryMovement() {
    FixClick(85, 295)
    sleep (1000)
    SendInput ("{w down}")
    Sleep(300)
    SendInput ("{w up}")
    Sleep(300)
    SendInput ("{d down}")
    SendInput ("{w down}")
    Sleep(4500)
    SendInput ("{d up}")
    SendInput ("{w up}")
    Sleep(500)
}

ChallengeMovement() {
    FixClick(765, 475)
    Sleep (500)
    FixClick(300, 415)
    SendInput ("{a down}")
    sleep (7000)
    SendInput ("{a up}")
}

RaidMovement() {
    FixClick(765, 475) ; Click Area
    Sleep(300)
    FixClick(495, 410)
    Sleep(500)
    SendInput ("{a down}")
    Sleep(400)
    SendInput ("{a up}")
    Sleep(500)
    SendInput ("{w down}")
    Sleep(5000)
    SendInput ("{w up}")
}

InfCastleMovement() {
    FixClick(765, 475)
    Sleep (300)
    FixClick(370, 330)
    Sleep (500)
    SendInput ("{w down}")
    Sleep (500)
    SendInput ("{w up}")
    Sleep (500)
    SendInput ("{a down}")
    sleep (4000)
    SendInput ("{a up}")
    Sleep (500)
}

CursedWombMovement() {
    FixClick(85, 295)
    Sleep (500)
    SendInput ("{a down}")
    sleep (3000)
    SendInput ("{a up}")
    sleep (1000)
    SendInput ("{s down}")
    sleep (4000)
    SendInput ("{s up}")
}

WinterEventMovement() {
    FixClick(592, 204) ; Close Matchmaking UI (Just in case)
    Sleep (200)
    FixClick(85, 295) ; Click Play
    sleep (1000)
    SendInput ("{a up}")
    Sleep 100
    SendInput ("{a down}")
    Sleep 6000
    SendInput ("{a up}")
    KeyWait "a" ; Wait for "d" to be fully processed
    Sleep 1200
}

StartStory(map, StoryAct) {
    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)

    downArrows := GetStoryDownArrows(map) ; Map selection down arrows
    loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select storymode
    Sleep(500)

    loop 4 {
        SendInput("{Up}") ; Makes sure it selects act
        Sleep(200)
    }

    SendInput("{Left}") ; Go to act selection
    Sleep(1000)

    actArrows := GetStoryActDownArrows(StoryAct) ; Act selection down arrows
    loop actArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select Act
    Sleep(500)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

StartLegend(map, LegendAct) {

    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)
    SendInput("{Down}")
    Sleep(500)
    SendInput("{Enter}") ; Opens Legend Stage

    downArrows := GetLegendDownArrows(map) ; Map selection down arrows
    loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select LegendStage
    Sleep(500)

    loop 4 {
        SendInput("{Up}") ; Makes sure it selects act
        Sleep(200)
    }

    SendInput("{Left}") ; Go to act selection
    Sleep(1000)

    actArrows := GetLegendActDownArrows(LegendAct) ; Act selection down arrows
    loop actArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select Act
    Sleep(500)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

StartRaid(map, RaidAct) {
    FixClick(640, 70) ; Closes Player leaderboard
    Sleep(500)
    navKeys := GetNavKeys()
    for key in navKeys {
        SendInput("{" key "}")
    }
    Sleep(500)

    downArrows := GetRaidDownArrows(map) ; Map selection down arrows
    loop downArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select Raid

    loop 4 {
        SendInput("{Up}") ; Makes sure it selects act
        Sleep(200)
    }

    SendInput("{Left}") ; Go to act selection
    Sleep(500)

    actArrows := GetRaidActDownArrows(MDo.Raid.Act) ; Act selection down arrows
    loop actArrows {
        SendInput("{Down}")
        Sleep(200)
    }

    SendInput("{Enter}") ; Select Act
    Sleep(300)
    for key in navKeys {
        SendInput("{" key "}")
    }
}

PlayHere() {
    FixClick(400, 435)  ; Play Here or Find Match
    Sleep (300)
    FixClick(330, 325) ;Click Play here
    Sleep (300)
    FixClick(400, 465) ;
    Sleep (300)
}

FindMatch() {
    startTime := A_TickCount

    loop {
        if (A_TickCount - startTime > 50000) {
            AddToLog("Matchmaking timeout, restarting mode")
            FixClick(400, 520)
            return StartSelectedMode()
        }

        FixClick(400, 435)  ; Play Here or Find Match
        Sleep(300)
        FixClick(460, 330)  ; Click Find Match
        Sleep(300)

        ; Try captcha
        if (!CaptchaDetect(252, 292, 300, 50, 400, 335)) {
            AddToLog("Captcha not detected, retrying...")
            FixClick(585, 190)  ; Click close
            Sleep(1000)
            continue
        }
        FixClick(300, 385)  ; Enter captcha
        return true
    }
}

GetStoryDownArrows(map) {
    switch map {
        case "Planet Greenie": return 2
        case "Walled City": return 3
        case "Snowy Town": return 4
        case "Sand Village": return 5
        case "Navy Bay": return 6
        case "Fiend City": return 7
        case "Spirit World": return 8
        case "Ant Kingdom": return 9
        case "Magic Town": return 10
        case "Haunted Academy": return 11
        case "Magic Hills": return 12
        case "Space Center": return 13
        case "Alien Spaceship": return 14
        case "Fabled Kingdom": return 15
        case "Ruined City": return 16
        case "Puppet Island": return 17
        case "Virtual Dungeon": return 18
        case "Snowy Kingdom": return 19
        case "Dungeon Throne": return 20
        case "Mountain Temple": return 21
        case "Rain Village": return 22
    }
}

GetStoryActDownArrows(StoryAct) {
    switch StoryAct {
        case "Infinity": return 1
        case "Act 1": return 2
        case "Act 2": return 3
        case "Act 3": return 4
        case "Act 4": return 5
        case "Act 5": return 6
        case "Act 6": return 7
    }
}

GetLegendDownArrows(map) {
    switch map {
        case "Magic Hills": return 1
        case "Space Center": return 3
        case "Fabled Kingdom": return 4
        case "Virtual Dungeon": return 6
        case "Dungeon Throne": return 7
        case "Rain Village": return 8
    }
}

GetLegendActDownArrows(LegendAct) {
    switch LegendAct {
        case "Act 1": return 1
        case "Act 2": return 2
        case "Act 3": return 3
    }
}

GetRaidDownArrows(map) {
    switch map {
        case "The Spider": return 1
        case "Sacred Planet": return 2
        case "Strange Town": return 3
        case "Ruined City": return 4
    }
}

GetRaidActDownArrows(RaidAct) {
    switch RaidAct {
        case "Act 1": return 1
        case "Act 2": return 2
        case "Act 3": return 3
        case "Act 4": return 4
        case "Act 5": return 5
    }
}

Zoom() {
    MouseMove(400, 300)
    Sleep 100

    ; Zoom in smoothly
    loop 10 {
        Send "{WheelUp}"
        Sleep 50
    }

    ; Look down
    Click
    MouseMove(400, 400)  ; Move mouse down to angle camera down

    ; Zoom back out smoothly
    loop 20 {
        Send "{WheelDown}"
        Sleep 50
    }

    ; Move mouse back to center
    MouseMove(400, 300)
}

TpSpawn() {
    FixClick(26, 570) ;click settings
    Sleep 300
    FixClick(400, 215)
    Sleep 300
    loop 4 {
        Sleep 150
        SendInput("{WheelDown 1}") ;scroll
    }
    Sleep 300
    if (ok := FindText(&X, &Y, 215, 160, 596, 480, 0, 0, Spawn)) {
        AddToLog("Found Teleport to Spawn button")
        FixClick(X + 100, Y - 30)
    } else {
        AddToLog("Could not find Teleport button")
    }
    Sleep 300
    FixClick(583, 147)
    Sleep 300

    ;

}

CloseChat() {
    if (ok := FindText(&X, &Y, 123, 50, 156, 79, 0, 0, OpenChat)) {
        AddToLog "Closing Chat"
        FixClick(138, 30) ;close chat
    }
}

BasicSetup() {
    SendInput("{Tab}") ; Closes Player leaderboard
    Sleep 300
    FixClick(564, 72) ; Closes Player leaderboard
    Sleep 300
    CloseChat()
    Sleep 300
    Zoom()
    Sleep 300
    TpSpawn()
}

DetectMap() {
    AddToLog("Determining Movement Necessity on Map...")
    startTime := A_TickCount

    loop {
        ; Check if we waited more than 5 minute for votestart
        if (A_TickCount - startTime > 300000) {
            if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
                AddToLog("Found in lobby - restarting selected mode")
                return StartSelectedMode()
            }
            AddToLog("Could not detect map after 5 minutes - proceeding without movement")
            return "no map found"
        }

        ; Check for vote screen
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart) or (ok := FindText(&X, &Y, 340, 537, 468,
            557, 0,
            0, Yen))) {
            AddToLog("No Map Found or Movement Unnecessary")
            return "no map found"
        }

        mapPatterns := Map(
            "Ant Kingdom", Ant,
            "Sand Village", Sand,
            "Magic Town", MagicTown,
            "Magic Hill", MagicHills,
            "Navy Bay", Navy,
            "Snowy Town", SnowyTown,
            "Fiend City", Fiend,
            "Spirit World", Spirit,
            "Haunted Academy", Academy,
            "Space Center", SpaceCenter,
            "Mountain Temple", Mount,
            "Cursed Festival", Cursed,
            "Nightmare Train", Nightmare,
            "Air Craft", AirCraft,
            "Hellish City", Hellish,
            "Contracts", ContractLoadingScreen,
            "Winter Event", Winter
        )

        for mapName, pattern in mapPatterns {
            if (MDo.UI.Text = "Winter Event" or MDo.UI.Text = "Contracts") {
                if (ok := FindText(&X, &Y, 10, 70, 350, 205, 0, 0, pattern)) {
                    AddToLog("Detected map: " mapName)
                    return mapName
                }
            } else {
                if (ok := FindText(&X, &Y, 10, 90, 415, 160, 0, 0, pattern)) {
                    AddToLog("Detected map: " mapName)
                    return mapName
                }
            }
        }

        Sleep 1000
        Reconnect()
    }
}

HandleMapMovement(MapName) {
    AddToLog("Executing Movement for: " MapName)

    switch MapName {
        case "Snowy Town":
            MoveForSnowyTown()
        case "Sand Village":
            MoveForSandVillage()
        case "Ant Kingdom":
            MoveForAntKingdom()
        case "Magic Town":
            MoveForMagicTown()
        case "Magic Hill":
            MoveForMagicHill()
        case "Navy Bay":
            MoveForNavyBay()
        case "Fiend City":
            MoveForFiendCity()
        case "Spirit World":
            MoveForSpiritWorld()
        case "Haunted Academy":
            MoveForHauntedAcademy()
        case "Space Center":
            MoveForSpaceCenter()
        case "Mountain Temple":
            MoveForMountainTemple()
        case "Cursed Festival":
            MoveForCursedFestival()
        case "Nightmare Train":
            MoveForNightmareTrain()
        case "Air Craft":
            MoveForAirCraft()
        case "Hellish City":
            MoveForHellish()
        case "Winter Event":
            MoveForWinterEvent()
        case "Contracts":
            MoveForContracts()
    }
}

MoveForSnowyTown() {
    Fixclick(700, 125, "Right")
    Sleep (6000)
    Fixclick(615, 115, "Right")
    Sleep (3000)
    Fixclick(725, 300, "Right")
    Sleep (3000)
    Fixclick(715, 395, "Right")
    Sleep (3000)
}

MoveForNavyBay() {
    SendInput ("{a down}")
    SendInput ("{w down}")
    Sleep (1700)
    SendInput ("{a up}")
    SendInput ("{w up}")
}

MoveForSandVillage() {
    Fixclick(777, 415, "Right")
    Sleep (3000)
    Fixclick(560, 555, "Right")
    Sleep (3000)
    Fixclick(125, 570, "Right")
    Sleep (3000)
    Fixclick(200, 540, "Right")
    Sleep (3000)
}

MoveForFiendCity() {
    Fixclick(185, 410, "Right")
    Sleep (3000)
    SendInput ("{a down}")
    Sleep (3000)
    SendInput ("{a up}")
    Sleep (500)
    SendInput ("{s down}")
    Sleep (2000)
    SendInput ("{s up}")
}

MoveForSpiritWorld() {
    SendInput ("{d down}")
    SendInput ("{w down}")
    Sleep(7000)
    SendInput ("{d up}")
    SendInput ("{w up}")
    sleep(500)
    Fixclick(400, 15, "Right")
    sleep(4000)
}

MoveForAntKingdom() {
    Fixclick(130, 550, "Right")
    Sleep (3000)
    Fixclick(130, 550, "Right")
    Sleep (4000)
    Fixclick(30, 450, "Right")
    Sleep (3000)
    Fixclick(120, 100, "Right")
    sleep (3000)
}

MoveForMagicTown() {
    Fixclick(700, 315, "Right")
    Sleep (2500)
    Fixclick(585, 535, "Right")
    Sleep (3000)
    SendInput ("{d down}")
    Sleep (3800)
    SendInput ("{d up}")
}

MoveForMagicHill() {
    color := PixelGetColor(630, 125)
    if (!IsColorInRange(color, 0xFFD100)) {
        Fixclick(500, 20, "Right")
        Sleep (3000)
        Fixclick(500, 20, "Right")
        Sleep (3500)
        Fixclick(285, 15, "Right")
        Sleep (2500)
        Fixclick(285, 25, "Right")
        Sleep (3000)
        Fixclick(410, 25, "Right")
        Sleep (3000)
        Fixclick(765, 150, "Right")
        Sleep (3000)
        Fixclick(545, 30, "Right")
        Sleep (3000)
    } else {
        Fixclick(45, 185, "Right")
        Sleep (3000)
        Fixclick(140, 250, "Right")
        Sleep (2500)
        Fixclick(25, 485, "Right")
        Sleep (3000)
        Fixclick(110, 455, "Right")
        Sleep (3000)
        Fixclick(40, 340, "Right")
        Sleep (3000)
        Fixclick(250, 80, "Right")
        Sleep (3000)
        Fixclick(230, 110, "Right")
        Sleep (3000)
    }
}

MoveForHauntedAcademy() {
    color := PixelGetColor(647, 187)
    ; if (!IsColorInRange(color, 0xFDF0B3)) {
    ;     SendInput ("{s down}")
    ;     sleep (3500)
    ;     SendInput ("{s up}")
    ; } else {
    SendInput ("{d down}")
    sleep (3500)
    SendInput ("{d up}")
    ; }
}

MoveForSpaceCenter() {
    Fixclick(160, 280, "Right")
    Sleep (7000)
}

MoveForMountainTemple() {
    Fixclick(40, 500, "Right")
    Sleep (4000)
}

MoveForCursedFestival() {
    SendInput ("{d down}")
    sleep (1800)
    SendInput ("{d up}")
}

MoveForNightmareTrain() {
    SendInput ("{a down}")
    sleep (1800)
    SendInput ("{a up}")
}

MoveForAirCraft() {
    SendInput ("{s down}")
    sleep (800)
    SendInput ("{s up}")
}

MoveForHellish() {
    Fixclick(600, 300, "Right")
    Sleep (7000)
}

MoveForWinterEvent() {
    loop {
        if FindAndClickColor() {
            break
        }
        else {
            AddToLog("Color not found. Turning again.")
            SendInput ("{Left up}")
            Sleep 200
            SendInput ("{Left down}")
            Sleep 750
            SendInput ("{Left up}")
            KeyWait "Left" ; Wait for key to be fully processed
            Sleep 200
        }
    }
}

MoveForContracts() {
    FixClick(590, 15) ; click on paths
    loop {
        if FindAndClickColor() {
            FixClick(590, 15) ; click on paths
            break
        }
        else {
            AddToLog("Color not found. Turning again.")
            SendInput ("{Left up}")
            Sleep 200
            SendInput ("{Left down}")
            Sleep 750
            SendInput ("{Left up}")
            KeyWait "Left" ; Wait for key to be fully processed
            Sleep 200
        }
    }
}

RestartStage() {
    currentMap := DetectMap()

    ; Wait for loading
    CheckLoaded()

    ; Do initial setup and map-specific movement during vote timer
    BasicSetup()
    if (currentMap != "no map found") {
        HandleMapMovement(currentMap)
    }

    ; Wait for game to actually start
    StartedGame()

    ; Begin unit placement and management
    global pointCounts
    pointCounts := Map()
    global successfulCoordinates
    successfulCoordinates := []
    firstplace := []
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := uIUnitSetting.enabled[slotNum].Value
        if (enabled) {
            firstplace.Push(slotNum)
        }
    }
    PlacingUnits(firstplace, "f")
    PlacingUnits([1, 2, 3, 4, 5, 6], "l")

    ; Monitor stage progress
    MonitorStage()
}

Reconnect() {
    ; Check for Disconnected Screen using FindText
    if (ok := FindText(&X, &Y, 330, 218, 474, 247, 0, 0, Disconnect)) {
        AddToLog("Lost Connection! Attempting To Reconnect To Private Server...")

        psLink := FileExist("Settings\PrivateServer.txt") ? FileRead("Settings\PrivateServer.txt", "UTF-8") : ""

        ; Reconnect to Ps
        if FileExist("Settings\PrivateServer.txt") && (psLink := FileRead("Settings\PrivateServer.txt", "UTF-8")) {
            AddToLog("Connecting to private server...")
            Run(psLink)
        } else {
            Run("roblox://placeID=8304191830")  ; Public server if no PS file or empty
        }

        Sleep(300000)

        ; Restore window if it exists
        if WinExist(rblxID) {
            forceRobloxSize()
            Sleep(1000)
        }

        ; Keep checking until we're back in
        loop {
            AddToLog("Reconnecting to Roblox...")
            Sleep(5000)

            ; Check if we're back in lobby
            if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
                AddToLog("Reconnected Successfully!")
                return StartSelectedMode() ; Return to raids
            }
            else {
                ; If not in lobby, try reconnecting again
                Reconnect()
            }
        }
    }
}

RejoinPrivateServer() {
    ; Check for Disconnected Screen using FindText
    AddToLog("Attempting To Reconnect To Private Server...")

    psLink := FileExist("Settings\PrivateServer.txt") ? FileRead("Settings\PrivateServer.txt", "UTF-8") : ""

    ; Reconnect to Ps
    if FileExist("Settings\PrivateServer.txt") && (psLink := FileRead("Settings\PrivateServer.txt", "UTF-8")) {
        AddToLog("Connecting to private server...")
        Run(psLink)
    } else {
        Run("roblox://placeID=8304191830")  ; Public server if no PS file or empty
    }

    Sleep(300000)
    ; Restore window if it exists
    if WinExist(rblxID) {
        forceRobloxSize()
        Sleep(1000)
    }

    ; Keep checking until we're back in
    loop {
        AddToLog("Reconnecting to Roblox...")
        Sleep(5000)

        ; Check if we're back in lobby
        if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
            AddToLog("Reconnected Successfully!")
            return StartSelectedMode() ; Return to raids
        } else {
            ; If not in lobby, try reconnecting again
            Reconnect()
        }
    }
}

PlaceUnit(x, y, slot := 1) {
    if (MDo.UI.Text = "Winter Event") {
        CheckForCardSelection()
    }
    SendInput(slot)
    Sleep 50
    FixClick(x, y)
    Sleep 50
    SendInput("q")

    if UnitPlaced() {
        Sleep 15
        return true
    }
    return false
}

MaxUpgrade() {
    Sleep 500
    ; Check for max text
    if (ok := FindText(&X, &Y, 160, 215, 330, 420, 0, 0, MaxText) or (ok := FindText(&X, &Y, 160, 215, 330, 420, 0,
        0,
        MaxText2))) {
        return true
    }
    return false
}

UnitPlaced() {
    PlacementSpeed() ; Custom Placement Speed
    ; Check for upgrade text
    if (ok := FindText(&X, &Y, 160, 215, 330, 420, 0, 0, UpgradeText) or (ok := FindText(&X, &Y, 160, 215, 330, 420,
        0,
        0, UpgradeText2))) {
        AddToLog("Unit Placed Successfully")
        FixClick(325, 185) ; close upg menu
        return true
    }
    return false
}

CheckAbility() {
    global AutoAbilityBox  ; Reference your checkbox

    ; Only check ability if checkbox is checked
    if (AutoAbilityBox.Value) {
        if (ok := FindText(&X, &Y, 342, 253, 401, 281, 0, 0, AutoOff)) {
            FixClick(373, 237)  ; Turn ability on
            AddToLog("Auto Ability Enabled")
        }
    }
}

CheckForCardSelection() {
    if (MDo.UI.Text = "Winter Event") {
        if (ok := FindText(&cardX, &cardY, 196, 204, 568, 278, 0, 0, pick_card)) {
            cardSelector()
        }
    }
}

CheckForXp() {
    ; Check for lobby text
    if (ok := FindText(&X, &Y, 340, 369, 437, 402, 0, 0, XpText) or (ok := FindText(&X, &Y, 539, 155, 760, 189, 0,
        0,
        XpText2))) {
        FixClick(325, 185)
        FixClick(560, 560)
        return true
    }
    return false
}

UpgradeUnit(x, y) {
    FixClick(x, y - 3)
    SendInput("r")
    SendInput("r")
}

CheckLobby() {
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
            break
        }
        Reconnect()
    }
    AddToLog("Returned to lobby, restarting selected mode")
    return StartSelectedMode()
}

CheckLoaded() {
    loop {
        Sleep(1000)

        ; Check for vote screen
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            AddToLog("Successfully Loaded In")
            Sleep(1000)
            break
        }

        Reconnect()
    }
}

StartedGame() {
    loop {
        Sleep(1000)
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            FixClick(350, 103) ; click yes
            FixClick(350, 100)
            FixClick(350, 97)
            continue  ; Keep waiting if vote screen is still there
        }

        ; If we don't see vote screen anymore the game has started
        AddToLog("Game started")
        global stageStartTime := A_TickCount
        break
    }
}

StartSelectedMode() {
    global inChallengeMode, firstStartup, challengeStartTime
    FixClick(400, 340)
    FixClick(400, 390)

    if (ChallengeBox.Value && firstStartup) {
        AddToLog("Auto Challenge enabled - starting with challenge")
        inChallengeMode := true
        firstStartup := false
        challengeStartTime := A_TickCount  ; Set initial challenge time
        ChallengeMode()
        return
    }
    ; If we're in challenge mode, do challenge
    if (inChallengeMode) {
        AddToLog("Starting Challenge Mode")
        ChallengeMode()
        return
    }
    else if (MDo.UI.Text = "Story") {
        StoryMode()
    }
    else if (MDo.UI.Text = "Legend") {
        LegendMode()
    }
    else if (MDo.UI.Text = "Raid") {
        RaidMode()
    }
    else if (MDo.UI.Text = "Infinity Castle") {
        InfinityCastleMode()
    }
    else if (MDo.UI.Text = "Contract") {
        ContractMode()
    }
    else if (MDo.UI.Text = "Winter Event") {
        WinterEvent()
    }
    else if (MDo.UI.Text = "Cursed Womb") {
        CursedWombMode()
    }
    else if (MDo.UI.Text = "Portal") {
        PortalMode()
    }
}

FormatStageTime(ms) {
    seconds := Floor(ms / 1000)
    minutes := Floor(seconds / 60)
    hours := Floor(minutes / 60)

    minutes := Mod(minutes, 60)
    seconds := Mod(seconds, 60)

    return Format("{:02}:{:02}:{:02}", hours, minutes, seconds)
}

ValidateMode() {
    if (MDo.UI.Text = "") {
        RestartStage()
    }
    if (!confirmClicked) {
        AddToLog("Please click the confirm button before starting the macro!")
        return false
    }
    return true
}

GetNavKeys() {
    return StrSplit(FileExist("Settings\UINavigation.txt") ? FileRead("Settings\UINavigation.txt", "UTF-8") :
        "\,#,}",
    ",")
}

HandlePortalEnd() {
    selectedPortal := MDo.Portal.UI.Text

    loop {
        Sleep(3000)

        FixClick(560, 560)

        if (ok := FindText(&X, &Y, 300, 190, 360, 250, 0, 0, UnitExit)) {
            ClickUntilGone(0, 0, 300, 190, 360, 250, UnitExit, -4, -35)
        }

        if (ok := FindText(&X, &Y, 260, 400, 390, 450, 0, 0, NextText)) {
            ClickUntilGone(0, 0, 260, 400, 390, 450, NextText, 0, -40)
        }

        if (ok := FindText(&X, &Y, 80, 85, 739, 224, 0, 0, LobbyText) or (ok := FindText(&X, &Y, 80, 85, 739, 224,
            0, 0,
            LobbyText2))) {
            AddToLog("Found Lobby Text - creating/joining new portal")
            Sleep(2000)

            if (MDo.Portal.Type.Text = "Creating") {
                FixClick(485, 120) ;Select New Portal
                Sleep(1500)
                FixClick(510, 190) ; Click search
                Sleep(1500)
                SendInput(selectedPortal)
                Sleep(1500)
                FixClick(215, 285)  ; Click On Portal
                Sleep (1500)
                FixClick(350, 410)  ; Click On Use
                Sleep(5000)
            } else {
                AddToLog("Waiting for next portal")
                Sleep(5000)
            }
            return RestartStage()
        }

        Reconnect()
        CheckEndAndRoute()
    }
}

HandlePortalJoin() {
    selectedPortal := MDo.Portal.UI.Text
    joinType := MDo.Portal.Type.Text

    if (joinType = "Creating") {

        ; Click items
        FixClick(33, 300)
        Sleep(1500)

        ; Click portals tab
        FixClick(435, 230)
        Sleep(1500)

        ; Click search
        FixClick(510, 190)
        Sleep(1500)

        ; Type portal name
        SendInput(selectedPortal)
        Sleep(1500)

        AddToLog("Creating " selectedPortal)
        FixClick(215, 285)  ; Click On Portal
        Sleep (1500)
        FixClick(354, 392)  ; Click On Use
        Sleep (1500)
        FixClick(250, 350)  ; Click On Open
        AddToLog("Waiting 15 seconds for others to join")
        ; Sleep(15000)
        FixClick(400, 460)  ; Start portal
    } else {
        AddToLog("Please join " selectedPortal " manually")
        Sleep(5000)
    }
}

HandleContractJoin() {
    selectedPage := MDo.Contract.UI.Text
    joinType := MDo.Contract.Type.Text

    ; Handle 4-5 Page pattern selection
    if (selectedPage = "Page 4-5") {
        selectedPage := GetContractPage()
        AddToLog("Pattern selected: " selectedPage)
    }

    pageNum := selectedPage = "Page 4-5" ? GetContractPage() : selectedPage
    pageNum := Integer(RegExReplace(RegExReplace(pageNum, "Page\s*", ""), "-.*", ""))

    ; Define click coordinates for each page
    clickCoords := Map(
        1, { openHere: { x: 170, y: 420 }, matchmaking: { x: 240, y: 420 } },  ; Example coords for page 1
        2, { openHere: { x: 330, y: 420 }, matchmaking: { x: 400, y: 420 } },  ; Example coords for page 2
        3, { openHere: { x: 490, y: 420 }, matchmaking: { x: 560, y: 420 } }, ; Example coords for page 3
        4, { openHere: { x: 237, y: 420 }, matchmaking: { x: 305, y: 420 } },  ; Example coords for page 4
        5, { openHere: { x: 397, y: 420 }, matchmaking: { x: 465, y: 420 } },  ; Example coords for page 5
        6, { openHere: { x: 557, y: 420 }, matchmaking: { x: 625, y: 420 } }  ; Example coords for page 6
    )

    ; First scroll if needed for pages 4-6
    if (pageNum >= 4) {
        FixClick(445, 300)
        Sleep(200)
        loop 5 {
            SendInput("{WheelDown}")
            Sleep(150)
        }
        Sleep(300)
    }

    ; Get coordinates for the selected page
    pageCoords := clickCoords[pageNum]

    ; Handle different join types
    if (joinType = "Creating") {
        AddToLog("Creating contract portal on page " pageNum)
        FixClick(pageCoords.openHere.x, pageCoords.openHere.y)
        Sleep(300)
        FixClick(255, 355)
        Sleep(20000)
        AddToLog("Waiting 20 seconds for others to join")
        FixClick(400, 460)
    } else if (joinType = "Joining") {
        AddToLog("Attempting to join by holding E")
        SendInput("{e down}")
        Sleep(5000)
        SendInput("{e up}")
    } else if (joinType = "Solo") {
        AddToLog("Attempting to start solo")
        FixClick(pageCoords.openHere.x, pageCoords.openHere.y)
        Sleep(300)
        FixClick(255, 355)
        Sleep 300
        FixClick(400, 468) ; Start Contract
    } else if (joinType = "Matchmaking") {
        AddToLog("Joining matchmaking for contract on page " pageNum)
        FixClick(pageCoords.matchmaking.x, pageCoords.matchmaking.y)  ; Click matchmaking button
        Sleep(300)

        ; Try captcha
        if (!CaptchaDetect(252, 292, 300, 50, 400, 335)) {
            AddToLog("Captcha not detected, retrying...")
            FixClick(585, 190)  ; Click close
            return
        }
        FixClick(300, 385)  ; Enter captcha

        startTime := A_TickCount
        while (A_TickCount - startTime < 20000) {  ; Check for 20 seconds
            if !(ok := FindText(&X, &Y, 746, 514, 789, 530, 0, 0, AreaText)) {
                AddToLog("Area text gone - matchmaking successful")
                return true
            }
            Sleep(200)  ; Check every 200ms
        }

        AddToLog("Matchmaking failed - still on area screen after 20s, retrying...")
        FixClick(445, 220)
        Sleep(1000)
        loop 5 {
            SendInput("{WheelUp}")
            Sleep(150)
        }
        Sleep(1000)
        return HandleContractJoin()
    }

    AddToLog("Joining Contract Mode")
    return true
}

HandleNextContract() {
    selectedPage := MDo.Contract.Type.Text
    if (selectedPage = "Page 4-5") {
        selectedPage := GetContractPage()
    }

    pageNum := Integer(RegExReplace(selectedPage, "Page ", ""))

    ; Define click coordinates to vote
    clickCoords := Map(
        1, { x: 205, y: 470 },
        2, { x: 365, y: 470 },
        3, { x: 525, y: 470 },
        4, { x: 272, y: 470 },
        5, { x: 432, y: 470 },
        6, { x: 592, y: 470 }
    )

    ; First scroll if needed for pages 4-6
    if (pageNum >= 4) {
        FixClick(400, 300)
        Sleep(200)
        loop 5 {
            SendInput("{WheelDown}")
            Sleep(150)
        }
        Sleep(300)
    }

    ; Click the Open Here button for the selected page
    AddToLog("Opening contract on page " selectedPage)
    FixClick(clickCoords[pageNum].x, clickCoords[pageNum].y)
    Sleep(500)

    return RestartStage()
}

HandleContractEnd() {
    global inChallengeMode, challengeStartTime

    loop {
        Sleep(3000)

        ; Click to claim any drops/rewards
        FixClick(560, 560)

        if (ok := FindText(&X, &Y, 300, 190, 360, 250, 0, 0, UnitExit)) {
            ClickUntilGone(0, 0, 300, 190, 360, 250, UnitExit, -4, -35)
        }

        if (ok := FindText(&X, &Y, 260, 400, 390, 450, 0, 0, NextText)) {
            ClickUntilGone(0, 0, 260, 400, 390, 450, NextText, 0, -40)
        }

        ; Check for both lobby texts
        if (ok := FindText(&X, &Y, 80, 85, 739, 224, 0, 0, LobbyText) or (ok := FindText(&X, &Y, 80, 85, 739, 224,
            0, 0,
            LobbyText2))) {
            AddToLog("Found Lobby Text - proceeding with contract end options")
            Sleep(2000)  ; Wait for UI to settle

            if (inChallengeMode) {
                AddToLog("Challenge completed - returning to selected mode")
                inChallengeMode := false
                challengeStartTime := A_TickCount
                Sleep(1500)
                ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                return CheckLobby()
            }

            if (!inChallengeMode && ChallengeBox.Value) {
                timeElapsed := A_TickCount - challengeStartTime
                if (timeElapsed >= 1800000) {  ; 30 minutes in milliseconds
                    AddToLog("30 minutes passed - switching to Challenge mode")
                    inChallengeMode := true
                    challengeStartTime := A_TickCount
                    Sleep(1500)
                    ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                    return CheckLobby()
                }
            }

            if (ReturnLobbyBox.Value) {
                AddToLog("Contract complete - returning to lobby")
                Sleep(1500)
                ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, 0, -35, LobbyText2)
                CheckLobby()
                return StartSelectedMode()
            } else {
                AddToLog("Starting next contract")
                Sleep(1500)
                ClickUntilGone(0, 0, 80, 85, 739, 224, LobbyText, +120, -35, LobbyText2)
                return HandleNextContract()
            }
        }
        Reconnect()
    }
}

GenerateRandomPoints() {
    points := []
    gridSize := 40  ; Minimum spacing between units

    ; Center point coordinates
    centerX := 408
    centerY := 320

    ; Define placement area boundaries (adjust these as needed)
    minX := centerX - 180  ; Left boundary
    maxX := centerX + 180  ; Right boundary
    minY := centerY - 140  ; Top boundary
    maxY := centerY + 140  ; Bottom boundary

    ; Generate 40 random points
    loop 40 {
        ; Generate random coordinates
        x := Random(minX, maxX)
        y := Random(minY, maxY)

        ; Check if point is too close to existing points
        tooClose := false
        for existingPoint in points {
            ; Calculate distance to existing point
            distance := Sqrt((x - existingPoint.x) ** 2 + (y - existingPoint.y) ** 2)
            if (distance < gridSize) {
                tooClose := true
                break
            }
        }

        ; If point is not too close to others, add it
        if (!tooClose)
            points.Push({ x: x, y: y })
    }

    ; Always add center point last (so it's used last)
    points.Push({ x: centerX, y: centerY })

    return points
}

GenerateGridPoints() {
    points := []
    gridSize := 40  ; Space between points
    squaresPerSide := 7  ; How many points per row/column (odd number recommended)

    ; Center point coordinates
    centerX := 408
    centerY := 320

    ; Calculate starting position for top-left point of the grid
    startX := centerX - ((squaresPerSide - 1) / 2 * gridSize)
    startY := centerY - ((squaresPerSide - 1) / 2 * gridSize)

    ; Generate grid points row by row
    loop squaresPerSide {
        currentRow := A_Index
        y := startY + ((currentRow - 1) * gridSize)

        ; Generate each point in the current row
        loop squaresPerSide {
            x := startX + ((A_Index - 1) * gridSize)
            points.Push({ x: x, y: y })
        }
    }

    return points
}

GenerateMoreGridPoints(gridWidth := 5) {  ; Adjust grid width (must be an odd number)
    points := []
    gridSize := 30  ; Space between points

    centerX := GetWindowCenter(rblxID).x
    centerY := GetWindowCenter(rblxID).y

    directions := [[1, 0], [0, 1], [-1, 0], [0, -1]]  ; Right, Down, Left, Up (1-based index)

    x := centerX
    y := centerY
    step := 1
    dirIndex := 1  ; Start at index 1 (AutoHotkey is 1-based)
    moves := 0
    stepsTaken := 0

    points.Push({ x: x, y: y })  ; Start at center

    loop (gridWidth * gridWidth - 1) {  ; Fill remaining slots
        dx := directions[dirIndex][1] * gridSize
        dy := directions[dirIndex][2] * gridSize
        x += dx
        y += dy
        points.Push({ x: x, y: y })

        moves++
        stepsTaken++

        if (moves = step) {  ; Change direction
            moves := 0
            dirIndex := (dirIndex = 4) ? 1 : dirIndex + 1  ; Rotate through 1-4

            if (stepsTaken // 2 = step) {  ; Expand step after two full cycles
                step++
                stepsTaken := 0
            }
        }
    }

    return points
}

GenerateUpandDownPoints() {
    points := []
    gridSize := 40  ; Space between points
    squaresPerSide := 7  ; How many points per row/column (odd number recommended)

    ; Center point coordinates
    centerX := 408
    centerY := 320

    ; Calculate starting position for top-left point of the grid
    startX := centerX - ((squaresPerSide - 1) / 2 * gridSize)
    startY := centerY - ((squaresPerSide - 1) / 2 * gridSize)

    ; Generate grid points column by column (left to right)
    loop squaresPerSide {
        currentColumn := A_Index
        x := startX + ((currentColumn - 1) * gridSize)

        ; Generate each point in the current column
        loop squaresPerSide {
            y := startY + ((A_Index - 1) * gridSize)
            points.Push({ x: x, y: y })
        }
    }

    return points
}

; circle coordinates
GenerateCirclePoints() {
    points := []

    ; Define each circle's radius
    radius1 := 45    ; First circle
    radius2 := 90    ; Second circle
    radius3 := 135   ; Third circle
    radius4 := 180   ; Fourth circle

    ; Angles for 8 evenly spaced points (in degrees)
    angles := [0, 45, 90, 135, 180, 225, 270, 315]

    ; First circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius1 * Cos(radians)
        y := centerY + radius1 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }

    ; second circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius2 * Cos(radians)
        y := centerY + radius2 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }

    ; third circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius3 * Cos(radians)
        y := centerY + radius3 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }

    ;  fourth circle points
    for angle in angles {
        radians := angle * 3.14159 / 180
        x := centerX + radius4 * Cos(radians)
        y := centerY + radius4 * Sin(radians)
        points.Push({ x: Round(x), y: Round(y) })
    }

    return points
}

; Spiral coordinates (restricted to a rectangle)
GenerateSpiralPoints(rectX := 4, rectY := 123, rectWidth := 795, rectHeight := 433) {
    points := []

    ; Calculate center of the rectangle
    centerX := rectX + rectWidth // 2
    centerY := rectY + rectHeight // 2

    ; Angle increment per step (in degrees)
    angleStep := 30
    ; Distance increment per step (tighter spacing)
    radiusStep := 10
    ; Initial radius
    radius := 20

    ; Maximum radius allowed (smallest distance from center to edge)
    maxRadiusX := (rectWidth // 2) - 1
    maxRadiusY := (rectHeight // 2) - 1
    maxRadius := Min(maxRadiusX, maxRadiusY)

    ; Generate spiral points until reaching max boundary
    loop {
        ; Stop if the radius exceeds the max boundary
        if (radius > maxRadius)
            break

        angle := A_Index * angleStep
        radians := angle * 3.14159 / 180
        x := centerX + radius * Cos(radians)
        y := centerY + radius * Sin(radians)

        ; Check if point is inside the rectangle
        if (x < rectX || x > rectX + rectWidth || y < rectY || y > rectY + rectHeight)
            break ; Stop if a point goes out of bounds

        points.Push({ x: Round(x), y: Round(y) })

        ; Increase radius for next point
        radius += radiusStep
    }

    return points
}

GetContractPage() {
    global contractPageCounter, contractSwitchPattern

    if (contractSwitchPattern = 0) {  ; During page 4 phase
        contractPageCounter++
        if (contractPageCounter >= 6) {  ; After 6 times on page 4
            contractPageCounter := 0
            contractSwitchPattern := 1  ; Switch to page 5
            return "Page 5"
        }
        return "Page 4"
    } else {  ; During page 5 phase
        contractPageCounter := 0
        contractSwitchPattern := 0  ; Switch back to page 4 pattern
        return "Page 4"
    }
}

CheckEndAndRoute() {
    if (ok := FindText(&X, &Y, 140, 130, 662, 172, 0, 0, LobbyText)) {
        AddToLog("Found end screen")
        if (mode = "Contract") {
            return HandleContractEnd()
        } else {
            return MonitorEndScreen()
        }
    }
    return false
}

ClickUntilGone(x, y, searchX1, searchY1, searchX2, searchY2, textToFind, offsetX := 0, offsetY := 0, textToFind2 :=
    "") {
    while (ok := FindText(&X, &Y, searchX1, searchY1, searchX2, searchY2, 0, 0, textToFind) ||
    textToFind2 && FindText(&X, &Y, searchX1, searchY1, searchX2, searchY2, 0, 0, textToFind2)) {
        if (offsetX != 0 || offsetY != 0) {
            FixClick(X + offsetX, Y + offsetY)
        } else {
            FixClick(x, y)
        }
        Sleep(1000)
    }
}

IsColorInRange(color, targetColor, tolerance := 50) {
    ; Extract RGB components
    r1 := (color >> 16) & 0xFF
    g1 := (color >> 8) & 0xFF
    b1 := color & 0xFF

    ; Extract target RGB components
    r2 := (targetColor >> 16) & 0xFF
    g2 := (targetColor >> 8) & 0xFF
    b2 := targetColor & 0xFF

    ; Check if within tolerance range
    return Abs(r1 - r2) <= tolerance
    && Abs(g1 - g2) <= tolerance
    && Abs(b1 - b2) <= tolerance
}

PlacementSpeed() {
    if PlaceSpeed.Text = "2.25 sec" {
        sleep 2250
    }
    else if PlaceSpeed.Text = "2 sec" {
        sleep 2000
    }
    else if PlaceSpeed.Text = "2.5 sec" {
        sleep 2500
    }
    else if PlaceSpeed.Text = "2.75 sec" {
        sleep 2.75
    }
    else if PlaceSpeed.Text = "3 sec" {
        sleep 3000
    }
}
