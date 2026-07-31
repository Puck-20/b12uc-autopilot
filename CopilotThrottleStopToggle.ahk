#V1.3.0
#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================
; Copilot Key -> ThrottleStop / GPU / Refresh Rate / Work-Mode Toggle
; MSI 15 B12UC — built by one person for their own laptop, see README.
; ============================================================
;   TAP the Copilot key         -> toggles GAME <-> PERF
;   HOLD the Copilot key (1s)   -> switches to WORK mode
;                                  (fires the instant 1s is reached,
;                                   does NOT wait for you to release)
;
; Requires: AutoHotkey v2, ThrottleStop, NVIDIA Profile Inspector,
; MSI Center, MSI Afterburner. Script must run ELEVATED (Administrator).
; See README.md for full setup.
; ============================================================

; ============================================================
; CONFIG — everything you need to edit lives in this block.
; Every "place holder" must be swapped for your real Windows username.
; ============================================================

TS_PATH   := "C:\Users\place holder\app\ThrottleStop.exe"
HK_PERF   := "^!{Numpad2}"   ; ThrottleStop Profile 1 = Performance -> Ctrl+Alt+NUMPAD 2
HK_GAME   := "^!{Numpad1}"   ; ThrottleStop Profile 2 = Game        -> Ctrl+Alt+NUMPAD 1
HK_WORK   := "^!{Numpad3}"   ; ThrottleStop Profile 4 = Battery     -> Ctrl+Alt+NUMPAD 3

NVI_PATH  := "C:\Users\place holder\app\nvidiaprofileinspec\nvidiaProfileInspector.exe"
NIP_GAME  := "C:\Users\place holder\app\nvidiaprofileinspec\global_profile_game.nip"
NIP_PERF  := "C:\Users\place holder\app\nvidiaprofileinspec\global_profile_perf.nip"   ; also used for Work (Optimal Power)

AB_PATH   := "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe"
AB_GAME   := "-profile1"   ; Afterburner profile with +0 clock offset (Game & Perf)
AB_WORK   := "-profile2"   ; Afterburner profile with a negative Core offset (e.g. -300) for Work

MSI_CENTER_APPID := "9426MICRO-STARINTERNATION.MSICenter_kzh8wxbdkxb8p!App"   ; packaged app - MSI Center isn't a normal exe on this machine, launched via explorer.exe shell:AppsFolder instead

REFRESH_NATIVE  := 144   ; Game/Perf refresh rate
REFRESH_WORK    := 60    ; Work mode refresh rate
TARGET_DISPLAY  := "\\.\DISPLAY1"   ; internal laptop panel; try DISPLAY2 if it hits the wrong screen

LONGPRESS_SEC := 1.0     ; seconds held to trigger Work mode
DEBOUNCE_MS   := 400     ; ignore repeat triggers faster than this (accidental double-press guard)

; ============================================================
; End of config
; ============================================================

ScriptDir  := A_ScriptDir
StateFile  := ScriptDir "\ts_profile_state.txt"
LogFile    := ScriptDir "\toggle.log"

CurrentProfile := "game"
LastSwitchTick := 0

; --- Elevation check: everything below silently fails without this ---
if !A_IsAdmin {
    Log("WARNING: script started WITHOUT admin rights. Elevated tools (ThrottleStop, "
        . "NVIDIA Profile Inspector, Afterburner) will likely fail or trigger UAC prompts.")
    MsgBox(
        "This script is not running as Administrator.`n`n"
        "ThrottleStop and the other tools run elevated, so switching probably "
        "won't work correctly until this script is also run elevated.`n`n"
        "See README.md -> Autostart (Scheduled Tasks) for the fix.",
        "Copilot Toggle - Not Elevated",
        "Icon!"
    )
}

if FileExist(StateFile) {
    saved := Trim(FileRead(StateFile))
    if (saved = "perf" || saved = "game" || saved = "work")
        CurrentProfile := saved
}

ShowIndicator(CurrentProfile)

; --- Copilot key sends Left Shift + Win + F23 ---
+#F23:: {
    global CurrentProfile, LONGPRESS_SEC, LastSwitchTick, DEBOUNCE_MS

    ; swallow the default "open Copilot" action
    Send("{Blind}{LShift Up}{LWin Up}")

    ; debounce: ignore this press if we just switched a moment ago
    if (A_TickCount - LastSwitchTick < DEBOUNCE_MS) {
        KeyWait("F23")
        return
    }

    ; KeyWait with a timeout: returns 1 if released before the timeout (tap),
    ; or 0 if the timeout hit while the key was still down (long-press) —
    ; in that case this line returns AT the 1s mark, not on release.
    released := KeyWait("F23", "T" LONGPRESS_SEC)

    EnsureThrottleStopRunning()

    if !released {
        ApplyProfile("work")
        KeyWait("F23")   ; consume the eventual physical release
    } else if (CurrentProfile = "game") {
        ApplyProfile("perf")
    } else {
        ApplyProfile("game")
    }

    LastSwitchTick := A_TickCount
}

EnsureThrottleStopRunning() {
    global TS_PATH
    if ProcessExist("ThrottleStop.exe")
        return
    try {
        Run(TS_PATH)
        WinWait("ahk_exe ThrottleStop.exe",, 8)
        Sleep(800)
    } catch as err {
        Log("Failed to launch ThrottleStop: " err.Message)
    }
}

ApplyProfile(profile) {
    global CurrentProfile, StateFile
    global HK_GAME, HK_PERF, HK_WORK
    global NVI_PATH, NIP_GAME, NIP_PERF
    global AB_PATH, AB_GAME, AB_WORK
    global MSI_CENTER_APPID
    global REFRESH_NATIVE, REFRESH_WORK

    ; show the popup FIRST, before anything that can blank the screen,
    ; so WORK MODE is visibly confirmed before the 60Hz drop hits
    ShowIndicator(profile)
    Sleep(120)   ; let the popup actually paint before the refresh-rate change

    if (profile = "game") {
        SafeRun(HK_GAME, "")
        SafeRun('"' NVI_PATH '" -silentImport "' NIP_GAME '"', "NVIDIA Profile Inspector (game)")
        RunAfterburnerProfile(AB_GAME, false)
        SetRefreshRate(REFRESH_NATIVE)
        SetEnergySaver(0)
        SoundSetMute(0)

    } else if (profile = "perf") {
        SafeRun(HK_PERF, "")
        SafeRun('"' NVI_PATH '" -silentImport "' NIP_PERF '"', "NVIDIA Profile Inspector (perf)")
        RunAfterburnerProfile(AB_GAME, false)   ; keep full GPU clocks in Perf too
        SetRefreshRate(REFRESH_NATIVE)
        SetEnergySaver(0)
        SoundSetMute(0)

    } else { ; work
        SafeRun(HK_WORK, "")
        SafeRun('"' NVI_PATH '" -silentImport "' NIP_PERF '"', "NVIDIA Profile Inspector (work)")
        RunAfterburnerProfile(AB_WORK, true)   ; Work mode is allowed to launch Afterburner if it's closed
        SetRefreshRate(REFRESH_WORK)
        SetEnergySaver(100)
        SoundSetMute(1)
        try {
            Run('explorer.exe shell:AppsFolder\' MSI_CENTER_APPID)
        } catch as err {
            Log("Failed to launch MSI Center: " err.Message)
        }
    }

    CurrentProfile := profile

    try FileDelete(StateFile)
    FileAppend(CurrentProfile, StateFile)
}

; Game/Perf: only talks to Afterburner if it's already running, never launches it.
; Work mode: allowed to launch it fresh so the downclock profile actually applies.
RunAfterburnerProfile(argument, allowLaunch) {
    global AB_PATH
    if !allowLaunch && !ProcessExist("MSIAfterburner.exe")
        return
    try {
        Run('"' AB_PATH '" ' argument,, "Hide")
    } catch as err {
        Log("Failed to run Afterburner: " err.Message)
    }
}

; Wrapper: sends a hotkey string OR runs a command line, catching failures either way.
SafeRun(target, label) {
    try {
        if InStr(target, "^") = 1 || InStr(target, "!") = 1 || InStr(target, "{") = 1
            Send(target)
        else
            Run(target,, "Hide")
    } catch as err {
        if (label != "")
            Log("Failed to run " label ": " err.Message)
    }
}

; Forces Windows' Energy Saver via powercfg's threshold setting rather than
; switching the whole power scheme (which MSI Center overrides on this laptop).
; 100 = Always on, 0 = Never (off unless toggled by hand). Sets both AC and DC
; so it applies whether plugged in or on battery.
SetEnergySaver(percent) {
    try Run('powercfg /setacvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD ' percent,, "Hide")
    try Run('powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD ' percent,, "Hide")
}

; Change display refresh rate using the Windows API directly - no external tool needed
SetRefreshRate(hz) {
    global TARGET_DISPLAY
    static DM_DISPLAYFREQUENCY := 0x400000

    dm := Buffer(220, 0)
    NumPut("UShort", 220, dm, 36)   ; dmSize

    if !DllCall("EnumDisplaySettingsA", "AStr", TARGET_DISPLAY, "Int", -1, "Ptr", dm) {
        Log("SetRefreshRate: EnumDisplaySettingsA failed for " TARGET_DISPLAY)
        return false
    }

    existingFields := NumGet(dm, 40, "UInt")
    NumPut("UInt", existingFields | DM_DISPLAYFREQUENCY, dm, 40)   ; dmFields
    NumPut("UInt", hz, dm, 120)                                    ; dmDisplayFrequency

    result := DllCall("ChangeDisplaySettingsExA", "AStr", TARGET_DISPLAY, "Ptr", dm, "Ptr", 0, "UInt", 0, "Ptr", 0)
    if (result != 0)
        Log("SetRefreshRate: ChangeDisplaySettingsExA returned " result " (non-zero = failure)")
    return (result = 0)
}

ShowIndicator(profile) {
    if (profile = "game") {
        title    := "GAME MODE"
        subtitle := "Turbo On  ·  GPU Max Perf  ·  144Hz"
        accent   := "2ecc71"
    } else if (profile = "perf") {
        title    := "PERF MODE"
        subtitle := "Turbo Off  ·  GPU Optimal  ·  144Hz"
        accent   := "3498db"
    } else {
        title    := "WORK MODE"
        subtitle := "Downclocked  ·  Muted  ·  60Hz"
        accent   := "9b59b6"
    }

    w := 280, h := 72, radius := 22

    ind := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound")
    ind.BackColor := "1E1E1E"
    ind.MarginX := 0
    ind.MarginY := 0

    ind.Add("Text", "x0 y0 w6 h" h " Background" accent)

    ind.SetFont("s13 cFFFFFF Bold", "Segoe UI")
    ind.Add("Text", "x26 y16 w" (w - 40), title)

    ind.SetFont("s10 c9AA0A6 Norm", "Segoe UI")
    ind.Add("Text", "x26 y42 w" (w - 40), subtitle)

    ind.Show("w" w " h" h " x" (A_ScreenWidth - w - 24) " y24 NoActivate")

    WinSetRegion("0-0 w" w " h" h " R" radius "-" radius, ind)

    SetTimer(() => ind.Destroy(), -1800)
}

Log(msg) {
    global LogFile
    try {
        ; keep the log from growing forever: once it passes ~500KB, keep one
        ; rotated backup (.old) and start a fresh file instead of appending forever
        if FileExist(LogFile) && FileGetSize(LogFile) > 500000 {
            try FileDelete(LogFile ".old")
            FileMove(LogFile, LogFile ".old")
        }
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " - " msg "`n", LogFile)
    }
}

; Safety net: if the script is closed or reloaded normally, drop back to the
; quieter Perf profile rather than leaving an aggressive Game/Work state
; active with nothing left running to revert it. Skipped on shutdown/logoff
; so it doesn't delay Windows closing down.
OnExit(SafeExit)
SafeExit(reason, code) {
    if (reason = "Shutdown" || reason = "Logoff")
        return
    try ApplyProfile("perf")
}
