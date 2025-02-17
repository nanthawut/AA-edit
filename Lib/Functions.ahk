#Include %A_ScriptDir%\Lib\GUI.ahk
global confirmClicked := false

CheckBanner(unitName) {

    ; First check if Roblox window exists
    if !WinExist(rblxID) {
        AddToLog("Roblox window not found - skipping banner check")
        return false
    }

    ; Get Roblox window position
    WinGetPos(&robloxX, &robloxY, &rblxW, &rblxH, rblxID)

    detectionCount := 0
    AddToLog("Checking for: " unitName)

    ; Split unit name into individual words
    unitName := Trim(unitName)  ; Remove spaces
    unitWords := StrSplit(unitName, " ")

    loop 5 {
        try {
            result := OCR.FromRect(robloxX + 280, robloxY + 293, 250, 55, "en", {
                grayscale: true,
                scale: 2.0
            })

            ; Check if all words are found in the text
            allWordsFound := true
            for word in unitWords {
                if !InStr(result.Text, word) {
                    allWordsFound := false
                    break
                }
            }

            if (allWordsFound) {
                detectionCount++
                Sleep(100)
            }
        }
    }

    if (detectionCount >= 1) {
        AddToLog("Found " unitName " in banner")
        try {
            BannerFound()
        }
        return true
    }

    AddToLog("Did not find " unitName " in banner")
    return false
}

SaveBannerSettings(*) {
    AddToLog("Saving Banner Configuration")

    if FileExist("Settings\BannerUnit.txt")
        FileDelete("Settings\BannerUnit.txt")

    FileAppend(BannerUnitBox.Value, "Settings\BannerUnit.txt", "UTF-8")
}

SavePsSettings(*) {
    AddToLog("Saving Private Server")

    if FileExist("Settings\PrivateServer.txt")
        FileDelete("Settings\PrivateServer.txt")

    FileAppend(PsLinkBox.Value, "Settings\PrivateServer.txt", "UTF-8")
}

SaveUINavSettings(*) {
    AddToLog("Saving UI Navigation Key")

    if FileExist("Settings\UINavigation.txt")
        FileDelete("Settings\UINavigation.txt")

    FileAppend(UINavBox.Value, "Settings\UINavigation.txt", "UTF-8")
}

AlwayTop(*) {
    guiAlwayTop := Alwayontop.Value ? "+AlwaysOnTop" : "-AlwaysOnTop"
    aaMainUI.Opt(guiAlwayTop)
    SaveSettings()
}

Destroy(*) {
    aaMainUI.Destroy()
    ExitApp
}
;Login Text
setupOutputFile() {
    content := "`n==" aaTitle "" version "==`n  Start Time: [" currentTime "]`n"
    FileAppend(content, currentOutputFile)
}

;Gets the current time
getCurrentTime() {
    currentHour := A_Hour
    currentMinute := A_Min
    currentSecond := A_Sec

    return Format("{:d}h.{:02}m.{:02}s", currentHour, currentMinute, currentSecond)
}

OnModeChange(*) {
    global mode
    mode := MDo.UI.Text

    ; Hide all dropdowns first
    MDo.Story.UI.Visible := false
    MDo.Story.Type.Visible := false
    MDo.Legend.UI.Visible := false
    MDo.Legend.Type.Visible := false
    MDo.Raid.UI.Visible := false
    MDo.Raid.Type.Visible := false
    MDo.Infinity_Castle.UI.Visible := false
    MatchMaking.Visible := false
    ReturnLobbyBox.Visible := false
    MDo.Portal.UI.Visible := false
    MDo.Portal.Type.Visible := false
    MDo.Contract.UI.Visible := false
    MDo.Contract.Type.Visible := false

    OnConfirmClick()
    if (MDo.%StrReplace(mode, " ", "_")%) {
        MDo.%StrReplace(mode, " ", "_")%.UI.Visible := true
        if (MDo.%StrReplace(mode, " ", "_")%.Type)
            MDo.%StrReplace(mode, " ", "_")%.Type.Visible := true
    }
}

OnConfirmClick(*) {
    SaveSettings()
    if (MDo.UI.Text = "") {
        AddToLog("Please select a gamemode before F2")
        return
    }

    ; For Story mode, check if both Story and Act are selected
    if (MDo.UI.Text = "Story") {
        if (MDo.Story.UI.Text = "" || MDo.Story.Type.Text = "") {
            AddToLog("Please select both Story and Act before F2")
            return
        }
        AddToLog("Selected " MDo.Story.UI.Text " - " MDo.Story.Type.Text)
        MatchMaking.Visible := (MDo.Story.Type.Text = "Infinity")
        ReturnLobbyBox.Visible := (MDo.Story.Type.Text = "Infinity")
        NextLevelBox.Visible := (MDo.Story.Type.Text != "Infinity")
    }
    ; For Legend mode, check if both Legend and Act are selected
    else if (MDo.UI.Text = "Legend") {
        if (MDo.Legend.UI.Text = "" || MDo.Legend.Type.Text = "") {
            AddToLog("Please select both Legend Stage and Act before F2")
            return
        }
        AddToLog("Selected " MDo.Legend.UI.Text " - " MDo.Legend.Type.Text)
        MatchMaking.Visible := true
        ReturnLobbyBox.Visible := true
    }
    ; For Cursed Womb, check if both Legend and Act are selected
    else if (MDo.UI.Text = "Cursed Womb") {
        AddToLog("Selected " MDo.Legend.UI.Text " - " MDo.Legend.Type.Text)
    }
    ; For Raid mode, check if both Raid and RaidAct are selected
    else if (MDo.UI.Text = "Raid") {
        if (MDo.Raid.UI.Text = "" || MDo.Raid.Type.Text = "") {
            AddToLog("Please select both Raid and Act before F2")
            return
        }
        AddToLog("Selected " MDo.Raid.UI.Text " - " MDo.Raid.Type.Text)
        MatchMaking.Visible := true
        ReturnLobbyBox.Visible := true
    }
    ; For Infinity Castle, check if mode is selected
    else if (MDo.UI.Text = "Infinity Castle") {
        if (MDo.Infinity_Castle.UI.Text = "") {
            AddToLog("Please select an Infinity Castle difficulty before F2")
            return
        }
        AddToLog("Selected Infinity Castle - " MDo.Infinity_Castle.Text)
        MatchMaking.Visible := false
        ReturnLobbyBox.Visible := false
    }
    ; For Portal, check if both Portal and Join Type are selected
    else if (MDo.UI.Text = "Portal") {
        if (MDo.Portal.UI.Text = "" || MDo.Portal.Type.Text = "") {
            AddToLog("Please select both Portal and Join Type before F2")
            return
        }
        AddToLog("Selected " MDo.Portal.UI.Text " - " MDo.Portal.Type.Text)
    }
    ; For Contract mode
    else if (MDo.UI.Text = "Contract") {
        if (MDo.Contract.UI.Text = "" || MDo.Contract.Type.Text = "") {
            AddToLog("Please select both Contract Page and Join Type before F2")
            return
        }
        AddToLog("Selected Contract Page " MDo.Contract.UI.Text " - " MDo.Contract.Type.Text)
        MatchMaking.Visible := false
        ReturnLobbyBox.Visible := true
    }
    ; Winter Event
    else if (MDo.UI.Text = "Winter Event") {
        AddToLog("Selected Winter Event")
        MatchMaking.Visible := true
        ReturnLobbyBox.Visible := true
    }
    else {
        AddToLog("Selected " MDo.UI.Text " mode")
        MatchMaking.Visible := false
        ReturnLobbyBox.Visible := false
    }

    AddToLog("Don't forget to enable Click to Move! (I forget sometimes too!)")

    ; Hide all controls if validation passes
    ; MDo.UI.Visible := false
    ; MDo.Story.UI.Visible := false
    ; MDo.Story.Type.Visible := false
    ; MDo.Legend.UI.Visible := false
    ; MDo.Legend.Type.Visible := false
    ; MDo.Raid.UI.Visible := false
    ; MDo.Raid.Type.Visible := false
    ; MDo.Infinity_Castle.Visible := false
    ; MDo.Portal.UI.Visible := false
    ; MDo.Portal.Type.Visible := false
    ; modeSelectionGroup.Visible := false
    ; MDo.Contract.UI.Visible := false
    ; MDo.Contract.Type.Visible := false
    global confirmClicked := true
}

FixClick(x, y, LR := "Left") {
    MouseMove(x, y)
    MouseMove(1, 0, , "R")
    MouseClick(LR, -1, 0, , , , "R")
    Sleep(50)
}

CaptchaDetect(x, y, w, h, inputX, inputY) {
    detectionCount := 0
    AddToLog("Checking for numbers...")
    loop 10 {
        try {
            result := OCR.FromRect(x, y, w, h, "FirstFromAvailableLanguages", {
                grayscale: true,
                scale: 2.0
            })

            if result {
                ; Get text before any linebreak
                number := StrSplit(result.Text, "`n")[1]

                ; Clean to just get numbers
                number := RegExReplace(number, "[^\d]")

                if (StrLen(number) >= 5 && StrLen(number) <= 7) {
                    detectionCount++

                    if (detectionCount >= 1) {
                        ; Send exactly what we detected in the green text
                        FixClick(inputX, inputY)
                        Sleep(300)

                        AddToLog("Sending number: " number)
                        for digit in StrSplit(number) {
                            Send(digit)
                            Sleep(120)
                        }
                        Sleep(200)
                        return true
                    }
                }
            }
        }
        Sleep(200)
    }
    AddToLog("Could not detect valid captcha")
    return false
}

GetWindowCenter(WinTitle) {
    x := 0 y := 0 Width := 0 Height := 0
    WinGetPos(&X, &Y, &Width, &Height, WinTitle)

    centerX := X + (Width / 2)
    centerY := Y + (Height / 2)

    return { x: centerX, y: centerY, width: Width, height: Height }
}

FindAndClickColor(targetColor := (MDo.UI.Text = "Winter Event" ? 0x006783 : 0xFAFF4D), searchArea := [0, 0,
    GetWindowCenter(rblxID).Width, GetWindowCenter(rblxID).Height]) { ;targetColor := Winter Event Color : 0x006783 / Contracts Color : 0xFAFF4D
    ; Extract the search area boundaries
    x1 := searchArea[1], y1 := searchArea[2], x2 := searchArea[3], y2 := searchArea[4]

    ; Perform the pixel search
    if (PixelSearch(&foundX, &foundY, x1, y1, x2, y2, targetColor, 0)) {
        ; Color found, click on the detected coordinates
        FixClick(foundX, foundY, "Right")
        AddToLog("Color found and clicked at: X" foundX " Y" foundY)
        Sleep 2000
        return true

    }
}

FindAndClickHauntedPath(targetColor := (mode = "Story" ? 0x191622 : 0x1D1414), searchArea := (mode = "Story" ? [708,
    332, 833, 365] : [558, 335, 694, 369])) {

    ; Extract the search area boundaries
    x1 := searchArea[1], y1 := searchArea[2], x2 := searchArea[3], y2 := searchArea[4]

    ; Perform the pixel search
    if (PixelSearch(&foundX, &foundY, x1, y1, x2, y2, targetColor, 0)) {
        ; Color found, click on the detected coordinates
        AddToLog("Color found at: X" foundX " Y" foundY)
        return true

    }
}

cardSelector() {
    AddToLog("Picking card in priority order")
    if (ok := FindText(&X, &Y, 200, 239, 276, 270, 0, 0, UnitExistence)) {
        FixClick(329, 184) ; close upg menu
        sleep 100
    }

    FixClick(59, 572) ; Untarget Mouse
    sleep 100

    for index, priority in priorityOrder {
        if (!textCards.Has(priority)) {
            ;AddToLog(Format("Card {} not available in textCards", priority))
            continue
        }
        if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, textCards.Get(priority))) {

            if (priority == "shield") {
                if (RadioHighest.Value == 1) {
                    AddToLog("Picking highest shield debuff")
                    if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, shield3)) {
                        AddToLog("Found shield 3")
                    }
                    else if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, shield2)) {
                        AddToLog("Found shield 2")
                    }
                    else if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, shield1)) {
                        AddToLog("Found shield 1")
                    }
                }

            }
            else if (priority == "speed") {
                if (RadioHighest.Value == 1) {
                    AddToLog("Picking highest speed debuff")
                    if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, speed3)) {
                        AddToLog("Found speed 3")
                    }
                    else if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, speed2)) {
                        AddToLog("Found speed 2")
                    }
                    else if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, speed1)) {
                        AddToLog("Found speed 1")
                    }
                }
            }
            else if (priority == "health") {
                if (RadioHighest.Value == 1) {
                    AddToLog("Picking highest health debuff")
                    if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, health3)) {
                        AddToLog("Found health 3")
                    }
                    else if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, health2)) {
                        AddToLog("Found health 2")
                    }
                    else if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, health1)) {
                        AddToLog("Found health 1")
                    }
                }
            }
            else if (priority == "regen") {
                if (RadioHighest.Value == 1) {
                    AddToLog("Picking highest regen debuff")
                    if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, regen3)) {
                        AddToLog("Found regen 3")
                    }
                    else if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, regen2)) {
                        AddToLog("Found regen 2")
                    }
                    else if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, regen1)) {
                        AddToLog("Found regen 1")
                    }
                }
            }
            else if (priority == "yen") {
                if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, yen2)) {
                    AddToLog("Found yen 2")
                }
                else {
                    AddToLog("Found yen 1")
                }
            }

            FindText().Click(cardX, cardY, 0)
            MouseMove 0, 10, 2, "R"
            Click 2
            sleep 1000
            MouseMove 0, 120, 2, "R"
            Click 2
            AddToLog(Format("Picked card: {}", priority))
            sleep 1000
            return
        }
    }
    AddToLog("Failed to pick a card")
}

CheckForEmptyKeys() {
    AddToLog("Looking for key purchase prompt")
    if (ok := FindText(&X, &Y, 434 - 150000, 383 - 150000, 434 + 150000, 383 + 150000, 0, 0, RobuxPurchaseKey)) {
        AddToLog("Found an attempt to purchase key for robux, closing macro.")
        return
    }
}

OpenGithub() {
    Run("https://github.com/nanthawut/AA-edit")
}

; OpenDiscord() {
;     Run("")
; }
