#Include %A_ScriptDir%\Lib\GUI.ahk
global settingsFile := ""

setupFilePath() {
    global settingsFile

    if !DirExist(A_ScriptDir "\Settings") {
        DirCreate(A_ScriptDir "\Settings")
    }

    settingsFile := A_ScriptDir "\Settings\Configuration.ini"
    return settingsFile
}

readInSettings() {
    global mode
    global PlacementPatternDropdown, PlaceSpeed, MatchMaking, ChallengeBox, AverageUpgrade

    settingsFile := setupFilePath()

    try {
        MDo.UI.Text := IniRead(settingsFile, "Mode", "Mode")
        loop 6 {
            uIUnitSetting.enabled[A_Index].Value := IniRead(settingsFile, "Enabled Unit", "Enabled" A_Index)
            uIUnitSetting.placement[A_Index].Text := IniRead(settingsFile, "Placement", "Placement" A_Index)
            uIUnitSetting.priority[A_Index].Text := IniRead(settingsFile, "Priority", "Priority" A_Index)
            uIUnitSetting.maxUnit[A_Index].Text := IniRead(settingsFile, "Max Unit", "MaxUnit" A_Index)
        }

        Alwayontop.Value := IniRead(settingsFile, "UI", "AlwaysOnTop")
        PlaceSpeed.Value := IniRead(settingsFile, "PlaceSpeed", "Speed")
        PlacementPatternDropdown.Value := IniRead(settingsFile, "PlacementLogic", "Logic")
        MatchMaking.Value := IniRead(settingsFile, "Matchmaking", "Matchmake")
        ChallengeBox.Value := IniRead(settingsFile, "AutoChallenge", "Challenge")
        AverageUpgrade.Value := IniRead(settingsFile, "Upgrade", "UpgradeSwitch")
        AlwayTop()

    }

    AddToLog("Configuration settings loaded successfully")

}

SaveSettings(*) {
    global mode
    global PlacementPatternDropdown, PlaceSpeed, MatchMaking, ChallengeBox, AverageUpgrade

    ; MsgBox(uIUnitSetting.enabled[1].Value)
    try {
        settingsFile := A_ScriptDir "\Settings\Configuration.ini"
        IniWrite MDo.Story.UI.Text, settingsFile, "Mode", "Mode"
        if (mode = "Story") {
            IniWrite MDo.Story.UI.Text, settingsFile, "Mode", "Map"
        } else if (mode = "Raid") {
            IniWrite MDo.Raid.UI.Text, settingsFile, "Mode", "Map"
        }

        ; Save settings for each unit
        loop 6 {
            IniWrite(uIUnitSetting.enabled[A_Index].Value, settingsFile, "Enabled Unit", "Enabled" A_Index)
            IniWrite(uIUnitSetting.placement[A_Index].Text, settingsFile, "Placement", "Placement" A_Index)
            IniWrite(uIUnitSetting.priority[A_Index].Text, settingsFile, "Priority", "Priority" A_Index)
            IniWrite(uIUnitSetting.maxUnit[A_Index].Text, settingsFile, "Max Unit", "MaxUnit" A_Index)
        }

        for index, dropDown in dropDowns {
            IniWrite dropDown.Text, settingsFile, "CardPriority", "Card" index
        }
        IniWrite(Alwayontop.Value, settingsFile, "UI", "AlwaysOnTop")

        IniWrite PlacementPatternDropdown.Value, settingsFile, "PlacementLogic", "Logic"

        IniWrite PlaceSpeed.Value, settingsFile, "PlaceSpeed", "Speed"

        IniWrite MatchMaking.Value, settingsFile, "Matchmaking", "Matchmake"

        IniWrite ChallengeBox.Value, settingsFile, "AutoChallenge", "Challenge"

        IniWrite AverageUpgrade.Value, settingsFile, "Upgrade", "UpgradeSwitch"

        ; AddToLog("Configuration settings saved successfully")
    }
}

LoadSettings() {
    global mode
    try {
        settingsFile := A_ScriptDir "\Settings\Configuration.ini"
        MsgBox(IniRead(settingsFile, "Enabled Unit", "Enabled1"))
        MDo.UI.Text := IniRead(settingsFile, "Mode", "Mode")
        loop 6 {
            uIUnitSetting.enabled[A_Index].Value := IniRead(settingsFile, "Enabled Unit", "Enabled" A_Index)
            uIUnitSetting.placement[A_Index].Text := IniRead(settingsFile, "Placement", "Placement" A_Index)
            uIUnitSetting.priority[A_Index].Text := IniRead(settingsFile, "Priority", "Priority" A_Index)
            uIUnitSetting.maxUnit[A_Index].Text := IniRead(settingsFile, "Max Unit", "MaxUnit" A_Index)
        }
        PlaceSpeed.Value := IniRead(settingsFile, "PlaceSpeed", "Speed")
        PlacementPatternDropdown.Value := IniRead(settingsFile, "PlacementLogic", "Logic")
        MatchMaking.Value := IniRead(settingsFile, "Matchmaking", "Matchmake")
        ChallengeBox.Value := IniRead(settingsFile, "AutoChallenge", "Challenge")
        AverageUpgrade.Value := IniRead(settingsFile, "Upgrade", "UpgradeSwitch")
        Alwayontop.Value := IniRead(settingsFile, "UI", "AlwaysOnTop")
        for index, dropDown in dropDowns {
            dropDown.Text := IniRead(settingsFile, "CardPriority", "Card" index)
        }
        AlwayTop()
        AddToLog("Auto settings loaded successfully")
    }
}

SaveKeybindSettings(*) {
    try {
        AddToLog("Saving Keybind Configuration")
        settingsFiles := A_ScriptDir "\Settings\Keybinds.ini"
        IniWrite F1Box.Value, settingsFiles, "Key Bind", "F1"
        IniWrite F2Box.Value, settingsFiles, "Key Bind", "F2"
        IniWrite F3Box.Value, settingsFiles, "Key Bind", "F3"
        IniWrite F4Box.Value, settingsFiles, "Key Bind", "F4"
        ; Update globals
        global F1Key := F1Box.Value
        global F2Key := F2Box.Value
        global F3Key := F3Box.Value
        global F4Key := F4Box.Value

        ; Update hotkeys
        Hotkey(F1Key, (*) => moveRobloxWindow())
        Hotkey(F2Key, (*) => StartMacro())
        Hotkey(F3Key, (*) => Reload())
        Hotkey(F4Key, (*) => TogglePause())
    }
}

LoadKeybindSettings() {
    try {
        settingsFiles := A_ScriptDir "\Settings\Keybinds.ini"
        global F1Key := IniRead(settingsFiles, "Key Bind", "F1")
        global F2Key := IniRead(settingsFiles, "Key Bind", "F2")
        global F3Key := IniRead(settingsFiles, "Key Bind", "F3")
        global F4Key := IniRead(settingsFiles, "Key Bind", "F4")
    }
}
