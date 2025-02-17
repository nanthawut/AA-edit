#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Image.ahk
#Include Functions.ahk

; Basic Application Info
global aaTitle := "Anime Adventure "
global version := "v1"
global rblxID := "ahk_exe RobloxPlayerBeta.exe"
;Coordinate and Positioning Variables
global targetWidth := 816
global targetHeight := 638
global offsetX := -5
global offsetY := 1
global WM_SIZING := 0x0214
global WM_SIZE := 0x0005
global centerX := 408
global centerY := 320
global successfulCoordinates := []
;Hotkeys
global F1Key := "F1"
global F2Key := "F2"
global F3Key := "F3"
global F4Key := "F4"
;Statistics Tracking
global Wins := 0
global loss := 0
global mode := ""
global StartTime := A_TickCount
global currentTime := GetCurrentTime()
;Auto Challenge
global challengeStartTime := A_TickCount
global inChallengeMode := false
global firstStartup := true
;Gui creation
global uiBorders := []
global uiBackgrounds := []
global uiTheme := []
global aaMainUI := Gui("+AlwaysOnTop")
aaMainUI.Title := "Anime Adventure v.1"
global lastlog := ""
global aaMainUIHwnd := aaMainUI.Hwnd
;Theme colors
uiTheme.Push("0xffffff")  ; Header color
uiTheme.Push("0c000a")  ; Background color
uiTheme.Push("0xffffff")    ; Border color
uiTheme.Push("0c000a")  ; Accent color
uiTheme.Push("0x3d3c36")   ; Trans color
uiTheme.Push("000000")    ; Textbox color
uiTheme.Push("00ffb3") ; HighLight
;Logs/Save settings
global settingsGuiOpen := false
global SettingsGUI := ""
global currentOutputFile := A_ScriptDir "\Logs\LogFile.txt"
global WebhookURLFile := "Settings\WebhookURL.txt"
global DiscordUserIDFile := "Settings\DiscordUSERID.txt"
global SendActivityLogsFile := "Settings\SendActivityLogs.txt"
;Custom Pictures
GithubImage := "Images\github-logo.png"
DiscordImage := "Images\another_discord.png"

global uIUnitSetting := { enabled: [], placement: [], priority: [], maxUnit: [] }

if !DirExist(A_ScriptDir "\Logs") {
    DirCreate(A_ScriptDir "\Logs")
}
if !DirExist(A_ScriptDir "\Settings") {
    DirCreate(A_ScriptDir "\Settings")
}

setupOutputFile()

;------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------
aaMainUI.BackColor := uiTheme[2]
global Webhookdiverter := aaMainUI.Add("Edit", "x0 y0 w1 h1 +Hidden", "") ; diversion
uiBorders.Push(aaMainUI.Add("Text", "x0 y0 w600 h1 +Background" uiTheme[3]))  ;Top line
uiBorders.Push(aaMainUI.Add("Text", "x0 y0 w1 h700 +Background" uiTheme[3]))   ;Left line
uiBorders.Push(aaMainUI.Add("Text", "x599 y0 w1 h700 +Background" uiTheme[3])) ;Right line
uiBorders.Push(aaMainUI.Add("Text", "x0 y30 w599 h1 +Background" uiTheme[3])) ;Title bottom
uiBorders.Push(aaMainUI.Add("Text", "x0 y433 w600 h1 +Background" uiTheme[3])) ;Process Top
uiBorders.Push(aaMainUI.Add("Text", "x0 y461 w600 h1 +Background" uiTheme[3])) ;Process bottom
uiBorders.Push(aaMainUI.Add("Text", "x0 y630 w600 h1 +Background" uiTheme[3], "")) ;Roblox bottom
uiBorders.Push(aaMainUI.Add("Text", "x0 y697 w600 h1 +Background" uiTheme[3], "")) ;Roblox second bottom

global robloxHolder := aaMainUI.Add("Text", "3 33 w797 h597 +Background" uiTheme[3], "") ;Roblox window box
global Discord := aaMainUI.Add("Picture", "553 y-4 w42 h42 +BackgroundTrans", Discord) ;Discord logo
Discord.OnEvent("Click", (*) => OpenDiscordLink()) ;Open discord
Alwayontop := aaMainUI.Add("Checkbox", "x500 y40 cffffff Checked", "AlwaysOnTop") ;Minimize gui
Alwayontop.OnEvent("Click", (*) => AlwayTop()) ;Minimize gui
aaMainUI.SetFont("Bold s16 c" uiTheme[1], "Verdana") ;Font
global windowTitle := aaMainUI.Add("Text", "x10 y3 w500 h29 +BackgroundTrans", aaTitle "" . "" version) ;Title

aaMainUI.Add("Text", "x5 y435 w558 h25 +Center +BackgroundTrans", "Process") ;Process header
global Process := []
aaMainUI.SetFont("norm s11 c" uiTheme[1]) ;Font
Process.Push(aaMainUI.Add("Text", "x10 y470 w538 h18 +BackgroundTrans c" uiTheme[7], ""))
loop 6 {
    Process.Push(aaMainUI.Add("Text", "xp yp+22 w538 h18 +BackgroundTrans", ""))
}
WinSetTransColor(uiTheme[5], aaMainUI) ;Roblox window box

;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS
ShowSettingsGUI(*) {
    global settingsGuiOpen, SettingsGUI

    ; Check if settings window already exists
    if (SettingsGUI && WinExist("ahk_id " . SettingsGUI.Hwnd)) {
        WinActivate("ahk_id " . SettingsGUI.Hwnd)
        return
    }

    if (settingsGuiOpen) {
        return
    }

    settingsGuiOpen := true
    SettingsGUI := Gui("-MinimizeBox +Owner" aaMainUIHwnd)
    SettingsGui.Title := "Settings"
    SettingsGUI.OnEvent("Close", OnSettingsGuiClose)
    SettingsGUI.BackColor := uiTheme[2]

    ; Window border
    SettingsGUI.Add("Text", "x0 y0 w1 h600 +Background" uiTheme[3])     ; Left
    SettingsGUI.Add("Text", "x599 y0 w1 h600 +Background" uiTheme[3])   ; Right
    SettingsGUI.Add("Text", "x0 y399 w600 h1 +Background" uiTheme[3])   ; Bottom

    ; Right side sections
    SettingsGUI.SetFont("s10", "Verdana")
    SettingsGUI.Add("GroupBox", "x310 y5 w280 h160 c" uiTheme[1], "Discord Webhook")  ; Box

    SettingsGUI.SetFont("s9", "Verdana")
    SettingsGUI.Add("Text", "x320 y30 c" uiTheme[1], "Webhook URL")     ; Webhook Text
    global WebhookURLBox := SettingsGUI.Add("Edit", "x320 y50 w260 h20 c" uiTheme[6])  ; Store webhook
    SettingsGUI.Add("Text", "x320 y83 c" uiTheme[1], "Discord ID (optional)")  ; Discord Id Text
    global DiscordUserIDBox := SettingsGUI.Add("Edit", "x320 y103 w260 h20 c" uiTheme[6])  ; Store Discord ID
    global SendActivityLogsBox := SettingsGUI.Add("Checkbox", "x320 y135 c" uiTheme[1], "Send Process")  ; Enable Activity

    ; HotKeys
    SettingsGUI.Add("GroupBox", "x10 y90 w160 h160 c" uiTheme[1], "Keybinds")
    SettingsGUI.Add("Text", "x20 y110 c" uiTheme[1], "Position Roblox:")
    global F1Box := SettingsGUI.Add("Edit", "x125 y110 w30 h20 c" uiTheme[6], F1Key)
    SettingsGUI.Add("Text", "x20 y140 c" uiTheme[1], "Start Macro:")
    global F2Box := SettingsGUI.Add("Edit", "x100 y140 w30 h20 c" uiTheme[6], F2Key)
    SettingsGUI.Add("Text", "x20 y170 c" uiTheme[1], "Stop Macro:")
    global F3Box := SettingsGUI.Add("Edit", "x100 y170 w30 h20 c" uiTheme[6], F3Key)
    SettingsGUI.Add("Text", "x20 y200 c" uiTheme[1], "Pause Macro:")
    global F4Box := SettingsGUI.Add("Edit", "x110 y200 w30 h20 c" uiTheme[6], F4Key)

    ; Banner section
    SettingsGUI.Add("GroupBox", "x310 y175 w280 h100 c" uiTheme[1], "Banner Checker")  ; Box
    SettingsGUI.Add("Text", "x320 y195 c" uiTheme[1], "Banner Unit Name (Adding later)")  ; Banner Text
    global BannerUnitBox := SettingsGUI.Add("Edit", "x320 y215 w260 h20 c" uiTheme[6])  ; Store banner
    testBannerBtn := SettingsGUI.Add("Button", "x320 y240 w120 h25", "Test Banner")
    testBannerBtn.OnEvent("Click", (*) => CheckBanner(BannerUnitBox.Value))

    ; Private Server section
    SettingsGUI.Add("GroupBox", "x310 y280 w280 h100 c" uiTheme[1], "PS Link")  ; Box
    SettingsGUI.Add("Text", "x320 y300 c" uiTheme[1], "Private Server Link (optional)")  ; Ps text
    global PsLinkBox := SettingsGUI.Add("Edit", "x320 y320 w260 h20 c" uiTheme[6])  ;  ecit box

    SettingsGUI.Add("GroupBox", "x10 y10 w115 h70 c" uiTheme[1], "UI Navigation")
    SettingsGUI.Add("Text", "x20 y30 c" uiTheme[1], "Navigation Key")
    global UINavBox := SettingsGUI.Add("Edit", "x20 y50 w20 h20 c" uiTheme[6], "\")

    SettingsGUI.Add("GroupBox", "x160 y10 w115 h70 c" uiTheme[1], "Card Priority")
    ;SettingsGUI.Add("Text", "x170 y30 c" uiTheme[1], "Navigation Key")
    global PriorityPicker := SettingsGUI.Add("Button", "x170 y50 w95 h20", "Edit")

    PriorityPicker.OnEvent("Click", (*) => OpenPriorityPicker())

    ; Save buttons
    webhookSaveBtn := SettingsGUI.Add("Button", "x460 y135 w120 h25", "Save Webhook")
    webhookSaveBtn.OnEvent("Click", (*) => SaveWebhookSettings())

    keybindSaveBtn := SettingsGUI.Add("Button", "x20 y220 w50 h20", "Save")
    keybindSaveBtn.OnEvent("Click", SaveKeybindSettings)

    bannerSaveBtn := SettingsGUI.Add("Button", "x460 y240 w120 h25", "Save Banner")
    bannerSaveBtn.OnEvent("Click", (*) => SaveBannerSettings())

    PsSaveBtn := SettingsGUI.Add("Button", "x460 y345 w120 h25", "Save PsLink")
    PsSaveBtn.OnEvent("Click", (*) => SavePsSettings())

    UINavSaveBtn := SettingsGUI.Add("Button", "x50 y50 w60 h20", "Save")
    UINavSaveBtn.OnEvent("Click", (*) => SaveUINavSettings())

    ; Loadsettings
    if FileExist(WebhookURLFile)
        WebhookURLBox.Value := FileRead(WebhookURLFile, "UTF-8")
    if FileExist(DiscordUserIDFile)
        DiscordUserIDBox.Value := FileRead(DiscordUserIDFile, "UTF-8")
    if FileExist(SendActivityLogsFile)
        SendActivityLogsBox.Value := (FileRead(SendActivityLogsFile, "UTF-8") = "1")
    if FileExist("Settings\BannerUnit.txt")
        BannerUnitBox.Value := FileRead("Settings\BannerUnit.txt", "UTF-8")
    if FileExist("Settings\PrivateServer.txt")
        PsLinkBox.Value := FileRead("Settings\PrivateServer.txt", "UTF-8")
    if FileExist("Settings\UINavigation.txt")
        UINavBox.Value := FileRead("Settings\UINavigation.txt", "UTF-8")

    ; Show the settings window
    SettingsGUI.Show("w600 h400")
    Webhookdiverter.Focus()
}

OpenGuide(*) {
    GuideGUI := Gui("+AlwaysOnTop")
    GuideGUI.SetFont("s10 bold", "Segoe UI")
    GuideGUI.Title := "Anime adventures settings (Thank you faxi)"

    GuideGUI.BackColor := "0c000a"
    GuideGUI.MarginX := 20
    GuideGUI.MarginY := 20

    ; Add Guide content
    GuideGUI.SetFont("s16 bold", "Segoe UI")

    GuideGUI.Add("Text", "x0 w800 cWhite +Center",
        "1 - In your AA settings make sure you have these 2 settings set to this")
    GuideGUI.Add("Picture", "x100 w600 h160 cWhite +Center", "Images\aasettings.png")

    GuideGUI.Add("Text", "x0 w800 cWhite +Center",
        "2 - In your ROBLOX settings, make sure your keyboard is set to click to move and your graphics are set to 1 and enable UI navigation"
    )
    GuideGUI.Add("Picture", "x50 w700   cWhite +Center", "Images\Clicktomove.png")
    GuideGUI.Add("Picture", "x50 w700   cWhite +Center", "Images\graphics1.png")
    GuideGUI.Add("Text", "x0 w800 cWhite +Center",
        "3 - Set up the unit setup however you want, however I'd avoid hill only units       if you can since it might break"
    )

    GuideGUI.Add("Text", "x0 w800 cWhite +Center",
        "4 - Rejoin Anime Adventures, dont move your camera at all and press F2 to start the macro. Good luck!")

    GuideGUI.Show("w800")
}

aaMainUI.SetFont("s12 Bold c" uiTheme[1])
global settingsBtn := aaMainUI.Add("Button", "x504 y0 w90 h30", "Settings")
settingsBtn.OnEvent("Click", ShowSettingsGUI)
global guideBtn := aaMainUI.Add("Button", "x410 y0 w90 h30", "Guide")
guideBtn.OnEvent("Click", OpenGuide)

aaMainUI.SetFont("s9")
global NextLevelBox := aaMainUI.Add("Checkbox", "x5 y385 cffffff Checked", "Next Level")
global MatchMaking := aaMainUI.Add("Checkbox", "x+5 y385 cffffff ", "Matchmaking")
global ReturnLobbyBox := aaMainUI.Add("Checkbox", "x+5 y385 cffffff", "Return To Lobby")
global AutoAbilityBox := aaMainUI.Add("CheckBox", "x5 y410 cffffff Checked", "Auto Ability")
global ChallengeBox := aaMainUI.Add("CheckBox", "x+5 y410 cffffff Checked", "Auto Challenge")
global AverageUpgrade := aaMainUI.Add("CheckBox", "x+5 y410 cffffff", "Average Upgrade")
global PlacementPatternDropdown := aaMainUI.Add("DropDownList", "x490 y662 w100 h180 Choose2 +Center", ["Random",
    "Grid", "Circle", "Spiral", "Up and Down"])
PlacementPatternText := aaMainUI.Add("Text", "x490 y642 w105 h20", "Placement Type")
PlaceSpeedText := aaMainUI.Add("Text", "x360 y642 w115 h20", "Placement Speed")
global PlaceSpeed := aaMainUI.Add("DropDownList", "x360 y662 w100 h180 Choose1 +Center", ["2.25 sec", "2 sec",
    "2.5 sec", "2.75 sec", "3 sec"])

NextLevelBox.OnEvent("Click", SaveSettings)
MatchMaking.OnEvent("Click", SaveSettings)
ReturnLobbyBox.OnEvent("Click", SaveSettings)
AutoAbilityBox.OnEvent("Click", SaveSettings)
ChallengeBox.OnEvent("Click", SaveSettings)
AverageUpgrade.OnEvent("Click", SaveSettings)
PlacementPatternDropdown.OnEvent("Change", SaveSettings)
PlaceSpeed.OnEvent("Change", SaveSettings)

GithubButton := aaMainUI.Add("Picture", "x10 y640 w40 h40 +BackgroundTrans cffffff", GithubImage)
GithubButton.OnEvent("Click", (*) => OpenGithub())
DiscordButton := aaMainUI.Add("Picture", "x60 y645 w60 h34 +BackgroundTrans cffffff", DiscordImage)
DiscordButton.OnEvent("Click", (*) => OpenDiscord())

;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS;--------------SETTINGS
;--------------MODE SELECT;--------------MODE SELECT;--------------MODE SELECT;--------------MODE SELECT;--------------MODE SELECT;--------------MODE SELECT

global modeSelectionGroup := aaMainUI.Add("GroupBox", "x10 y38 w450 h45 Background" uiTheme[2], "Mode Select")
aaMainUI.SetFont("s10 c" uiTheme[6])
global MDo := {
    UI: aaMainUI.Add("DropDownList", "x20 y53 w140 h180 Choose0 +Center", ["", "Story", "Legend", "Raid",
        "Infinity Castle", "Contract", "Cursed Womb", "Portal", "Winter Event"]),
    Story: {
        UI: aaMainUI.Add("DropDownList", "x170 y53 w150 h180 Choose0 +Center", ["Planet Greenie",
            "Walled City", "Snowy Town", "Sand Village", "Navy Bay", "Fiend City", "Spirit World", "Ant Kingdom",
            "Magic Town",
            "Haunted Academy", "Magic Hills", "Space Center", "Alien Spaceship", "Fabled Kingdom", "Ruined City",
            "Puppet Island", "Virtual Dungeon", "Snowy Kingdom", "Dungeon Throne", "Mountain Temple", "Rain Village"]),
        Act: aaMainUI.Add("DropDownList", "x330 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2",
            "Act 3", "Act 4", "Act 5", "Act 6", "Infinity"])
    },
    Legend: {
        UI: aaMainUI.Add("DropDownlist", "x170 y53 w150 h180 Choose0 +Center", ["Magic Hills",
            "Space Center", "Fabled Kingdom", "Virtual Dungeon", "Dungeon Throne", "Rain Village"]),
        Act: aaMainUI.Add("DropDownList", "x330 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2",
            "Act 3"])
    },
    Raid: {
        UI: aaMainUI.Add("DropDownList", "x170 y53 w150 h180 Choose0 +Center", ["The Spider",
            "Sacred Planet", "Strange Town", "Ruined City"]),
        Act: aaMainUI.Add("DropDownList", "x330 y53 w80 h180 Choose0 +Center", ["Act 1", "Act 2", "Act 3",
            "Act 4", "Act 5"])
    },
    Infinity_Castle: aaMainUI.Add("DropDownList", "x170 y53 w80 h180 Choose0 +Center", ["Normal", "Hard"]),
    Contract: {
        UI: aaMainUI.Add("DropDownList", "x170 y53 w80 h180 Choose0 +Center", ["Page 1", "Page 2",
            "Page 3", "Page 4", "Page 5", "Page 6", "Page 4-5"]),
        Type: aaMainUI.Add("DropDownList", "x259 y53 w120 h180 Choose0 +Center", ["Creating",
            "Joining", "Matchmaking", "Solo"])
    },
    Portal: {
        UI: aaMainUI.Add("DropDownList", "x170 y53 w150 h180 Choose0 +Center", ["Alien Portal",
            "Puppet Portal", "Demon Leader's Portal", "Eclipse Portal", "Noble Portal"]),
        Type: aaMainUI.Add("DropDownList", "x330 y53 w80 h180 Choose0 +Center", ["Creating", "Joining"])
    }
}

MDo.Story.Act.OnEvent("Change", OnConfirmClick)
MDo.Legend.Act.OnEvent("Change", OnConfirmClick)
MDo.Raid.Act.OnEvent("Change", OnConfirmClick)
MDo.Infinity_Castle.OnEvent("Change", OnConfirmClick)
MDo.Contract.UI.OnEvent("Change", OnConfirmClick)
MDo.Contract.Type.OnEvent("Change", OnConfirmClick)
MDo.Portal.UI.OnEvent("Change", OnConfirmClick)
MDo.Portal.Type.OnEvent("Change", OnConfirmClick)

MDo.Story.UI.Visible := false
MDo.Story.Act.Visible := false
MDo.Legend.UI.Visible := false
MDo.Legend.Act.Visible := false
MDo.Raid.UI.Visible := false
MDo.Raid.Act.Visible := false
MDo.Infinity_Castle.Visible := false
MDo.Contract.UI.Visible := false
MDo.Contract.Type.Visible := false
MDo.Portal.UI.Visible := false
MDo.Portal.Type.Visible := false
MatchMaking.Visible := false
ReturnLobbyBox.Visible := false
NextLevelBox.Visible := false
MDo.UI.OnEvent("Change", OnModeChange)
MDo.Story.UI.OnEvent("Change", OnStoryChange)
MDo.Legend.UI.OnEvent("Change", OnLegendChange)
MDo.Raid.UI.OnEvent("Change", OnRaidChange)
;------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI------MAIN UI
;------UNIT CONFIGURATION------UNIT CONFIGURATION------UNIT CONFIGURATION/------UNIT CONFIGURATION/------UNIT CONFIGURATION/------UNIT CONFIGURATION/

AddUnitCard(aaMainUI, index, x, y) {
    unit := {}

    unit.Background := aaMainUI.Add("Text", Format("x{} y{} w550 h45 +Background{}", x, y, uiTheme[4]))
    unit.BorderTop := aaMainUI.Add("Text", Format("x{} y{} w550 h2 +Background{}", x, y, uiTheme[3]))
    unit.BorderBottom := aaMainUI.Add("Text", Format("x{} y{} w552 h2 +Background{}", x, y + 45, uiTheme[3]))
    unit.BorderLeft := aaMainUI.Add("Text", Format("x{} y{} w2 h45 +Background{}", x, y, uiTheme[3]))
    unit.BorderRight := aaMainUI.Add("Text", Format("x{} y{} w2 h45 +Background{}", x + 550, y, uiTheme[3]))
    unit.BorderRight := aaMainUI.Add("Text", Format("x{} y{} w2 h45 +Background{}", x + 250, y, uiTheme[3]))

    aaMainUI.SetFont("s11 Bold c" uiTheme[1])
    unit.Title := aaMainUI.Add("Text", Format("x{} y{} w60 h25 +BackgroundTrans", x + 30, y + 18), "Unit " index)

    aaMainUI.SetFont("s9 c" uiTheme[1])
    unit.PlacementText := aaMainUI.Add("Text", Format("x{} y{} w70 h20 +BackgroundTrans", x + 100, y + 2), "Placement")
    unit.PriorityText := aaMainUI.Add("Text", Format("x{} y{} w60 h20 BackgroundTrans", x + 180, y + 2),
    "Priority")

    unit.MaxUnitText := aaMainUI.Add("Text", Format("x{} y{} w130 h20 BackgroundTrans", x + 260, y + 2
    ), "Max Unit")
}

;Create Unit slot
y_start := 85
y_spacing := 50

arraySet := ["1", "2", "3", "4", "5", "6"]
loop 6 {
    AddUnitCard(aaMainUI, A_Index, 10, y_start + ((A_Index - 1) * y_spacing))
}
aaMainUI.SetFont("s8 c" uiTheme[6])
loop 6 {
    sizeY := (105 + ((A_Index - 1) * y_spacing))
    uIUnitSetting.enabled.Push(aaMainUI.Add("CheckBox", Format("x20 y{} w15 h15", sizeY), ""))
    uIUnitSetting.placement.Push(aaMainUI.Add("DropDownList", Format("x110 y{} w60 h180 Choose1 +Center", sizeY),
    arraySet))
    uIUnitSetting.priority.Push(aaMainUI.Add("DropDownList", Format("x190 y{} w60 h180 Choose{} +Center", sizeY,
        A_Index), arraySet))
    uIUnitSetting.maxUnit.Push(aaMainUI.Add("DropDownList", Format("x270 y{} w60 h180 Choose1 +Center", sizeY,
    ), arraySet))

    uIUnitSetting.enabled[A_Index].OnEvent("Click", SaveSettings)
    uIUnitSetting.placement[A_Index].OnEvent("Change", SaveSettings)
    uIUnitSetting.priority[A_Index].OnEvent("Change", SaveSettings)
    uIUnitSetting.maxUnit[A_Index].OnEvent("Change", SaveSettings)
}

readInSettings()
aaMainUI.Show("w600 h700")
WinMove(810, 0, , , "ahk_id " aaMainUIHwnd)
forceRobloxSize()  ; Initial force size and position
SetTimer(checkRobloxSize, 600000)  ; Check every 10 minutes

;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION ;------UNIT CONFIGURATION
;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS;------FUNCTIONS

;Process text
AddToLog(current) {
    global currentOutputFile, lastlog

    ; Remove arrow from all lines first
    Process[7].Value := StrReplace(Process[6].Value, "➤ ", "")
    Process[6].Value := StrReplace(Process[5].Value, "➤ ", "")
    Process[5].Value := StrReplace(Process[4].Value, "➤ ", "")
    Process[4].Value := StrReplace(Process[3].Value, "➤ ", "")
    Process[3].Value := StrReplace(Process[2].Value, "➤ ", "")
    Process[2].Value := StrReplace(Process[1].Value, "➤ ", "")

    ; Add arrow only to newest process
    Process[1].Value := "➤ " . current

    elapsedTime := getElapsedTime()
    Sleep(50)
    FileAppend(current . " " . elapsedTime . "`n", currentOutputFile)

    ; Add webhook logging
    lastlog := current
    if FileExist("Settings\SendActivityLogs.txt") {
        SendActivityLogsStatus := FileRead("Settings\SendActivityLogs.txt", "UTF-8")
        if (SendActivityLogsStatus = "1") {
            WebhookLog()
        }
    }
}

;Timer
getElapsedTime() {
    global StartTime
    ElapsedTime := A_TickCount - StartTime
    Minutes := Mod(ElapsedTime // 60000, 60)
    Seconds := Mod(ElapsedTime // 1000, 60)
    return Format("{:02}:{:02}", Minutes, Seconds)
}

;Basically the code to move roblox, below

sizeDown() {
    global rblxID

    if !WinExist(rblxID)
        return

    WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)

    ; Exit fullscreen if needed
    if (OutWidth >= A_ScreenWidth && OutHeight >= A_ScreenHeight) {
        Send "{F11}"
        Sleep(100)
    }

    ; Force the window size and retry if needed
    loop 3 {
        WinMove(X, Y, targetWidth, targetHeight, rblxID)
        Sleep(100)
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
        if (OutWidth == targetWidth && OutHeight == targetHeight)
            break
    }
}

moveRobloxWindow() {
    global aaMainUIHwnd, offsetX, offsetY, rblxID

    if !WinExist(rblxID) {
        AddToLog("Waiting for Roblox window...")
        return
    }

    ; First ensure correct size
    sizeDown()

    ; Then move relative to main UI
    WinGetPos(&x, &y, &w, &h, aaMainUIHwnd)
    WinMove(offsetX, offsetY, , , rblxID)
    WinActivate(rblxID)
}

forceRobloxSize() {
    global rblxID

    if !WinExist(rblxID) {
        checkCount := 0
        while !WinExist(rblxID) {
            Sleep(5000)
            if (checkCount >= 5) {
                AddToLog("Attempting to locate the Roblox window")
            }
            checkCount += 1
            if (checkCount > 12) { ; Give up after 1 minute
                AddToLog("Could not find Roblox window")
                return
            }
        }
        AddToLog("Found Roblox window")
    }

    WinActivate(rblxID)
    sizeDown()
    moveRobloxWindow()
}
; Function to periodically check window size
checkRobloxSize() {
    global rblxID
    if WinExist(rblxID) {
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, rblxID)
        if (OutWidth != targetWidth || OutHeight != targetHeight) {
            sizeDown()
            moveRobloxWindow()
        }
    }
}
;Basically the code to move roblox, Above

OnSettingsGuiClose(*) {
    global settingsGuiOpen, SettingsGUI
    settingsGuiOpen := false
    if SettingsGUI {
        SettingsGUI.Destroy()
        SettingsGUI := ""  ; Clear the GUI reference
    }
}

checkSizeTimer() {
    if (WinExist("ahk_exe RobloxPlayerBeta.exe")) {
        WinGetPos(&X, &Y, &OutWidth, &OutHeight, "ahk_exe RobloxPlayerBeta.exe")
        if (OutWidth != 816 || OutHeight != 638) {
            AddToLog("Fixing Roblox window size")
            moveRobloxWindow()
        }
    }
}
