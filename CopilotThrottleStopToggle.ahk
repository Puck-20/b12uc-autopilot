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
;   Ctrl+Alt+F9                 -> pause/resume this script
;   Tray icon (right-click)     -> manually force Game / Perf / Work,
;                                  in case the physical key ever misbehaves
;
; Requires: AutoHotkey v2, ThrottleStop, NVIDIA Profile Inspector,
; MSI Center, MSI Afterburner — but each one can be switched off in
; config.ahk if you don't use it (see the ENABLE_* toggles there).
; Script must run ELEVATED (Administrator).
;
; All paths and toggles live in config.ahk, which must sit in the
; same folder as this file. Edit config.ahk, not this file.
; See README.md for full setup.
; ============================================================

; ============================================================
; CONFIG now lives in config.ahk (same folder as this script).
; See that file to set your paths and to enable/disable individual
; tools (ThrottleStop, NVIDIA Profile Inspector, Afterburner, MSI Center).
; ============================================================
#Include config.ahk

SCRIPT_VERSION := "1.4.0"

ScriptDir  := A_ScriptDir
StateFile  := ScriptDir "\ts_profile_state.txt"
LogFile    := ScriptDir "\toggle.log"

CurrentProfile := "game"
LastSwitchTick := 0

; --- v1.4.0: ask for the username/folder once instead of making people hand-edit config.ahk ---
if (WIN_USERNAME = "place holder")
    RunFirstTimeSetup()

; --- v1.4.0: only check paths for tools that are actually enabled in config.ahk ---
CheckPaths := []
if ENABLE_THROTTLESTOP
    CheckPaths.Push(TS_PATH)
if ENABLE_NVIDIA_INSPECTOR
    CheckPaths.Push(NVI_PATH, NIP_GAME, NIP_PERF)
if ENABLE_AFTERBURNER
    CheckPaths.Push(AB_PATH)

; catches a first-run setup that got cancelled/skipped
for p in CheckPaths {
    if InStr(p, "place holder") {
        Log("WARNING: config.ahk still contains 'place holder' - script paths are not set up.")
        MsgBox(
            "config.ahk still has 'place holder' in one or more paths.`n`n"
            "Restart the script to get the setup popup again, or set WIN_USERNAME "
            "in config.ahk yourself. See README.md -> Setup.",
            "Copilot Toggle - Setup Incomplete",
            "Icon!"
        )
        break
    }
}

; also catch typo'd/custom paths that don't exist, even once "place holder" is gone
for p in CheckPaths {
    if !InStr(p, "place holder") && !FileExist(p) {
        Log("WARNING: configured path does not exist: " p)
        MsgBox(
            "This path doesn't seem to exist:`n`n" p "`n`n"
            "Double-check config.ahk (WIN_USERNAME / APPS_FOLDER_NAME, or the path itself), "
            "or set the matching ENABLE_* toggle to false if you don't have that tool installed.",
            "Copilot Toggle - Path Not Found",
            "Icon!"
        )
        break
    }
}

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

; v1.3.1: was ShowIndicator(CurrentProfile) - that only displayed a label without
; actually re-applying it. SafeExit skips the perf-revert on Shutdown/Logoff, so
; StateFile can say "game"/"work" after a reboot while the real hardware booted
; into whatever ThrottleStop's own default is. ApplyProfile() re-syncs both and
; still calls ShowIndicator() itself as its first action.
ApplyProfile(CurrentProfile)

; v1.3.1: Ctrl+Alt+F9 pauses/resumes the script - no tray icon menu originally,
; so this was the only way to stop it short of Task Manager. "S" option keeps this
; specific hotkey working even while the script is suspended.
Hotkey("^!F9", ToggleSuspend, "On S")

; --- v1.4.0: manual fallback via the tray icon's right-click menu, in case the
; physical Copilot key ever misbehaves (remapped by a Windows update, dodgy
; hardware, etc.) - forces a mode the same way the hotkey would. ---
A_TrayMenu.Insert("1&", "Force Game Mode", TrayApplyGame)
A_TrayMenu.Insert("2&", "Force Perf Mode", TrayApplyPerf)
A_TrayMenu.Insert("3&", "Force Work Mode", TrayApplyWork)
A_TrayMenu.Insert("4&")   ; separator, above the standard Open/Reload/Exit items
A_TrayMenu.Default := "Force Game Mode"

TrayApplyGame(*) => ManualSwitch("game")
TrayApplyPerf(*) => ManualSwitch("perf")
TrayApplyWork(*) => ManualSwitch("work")

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
        ; v1.4.0 bugfix: KeyWait used to block here with no timeout, waiting for a
        ; physical release that could in rare cases never arrive (dropped key-up,
        ; sleep/wake mid-press), permanently wedging this hotkey. 5s is generous
        ; for "finger still on the key" but bails out instead of hanging forever.
        if !KeyWait("F23", "T5")
            Log("WARNING: F23 key-up not detected within 5s after long-press - releasing wait.")
    } else if (CurrentProfile = "game") {
        ApplyProfile("perf")
    } else {
        ApplyProfile("game")
    }

    LastSwitchTick := A_TickCount
}

ToggleSuspend(*) {
    Suspend(-1)
    ToolTip(A_IsSuspended
        ? "Copilot Toggle: SUSPENDED  (Ctrl+Alt+F9 to resume)"
        : "Copilot Toggle: resumed")
    SetTimer(() => ToolTip(), -1500)
}

; v1.4.0: shared by both the tray menu and (conceptually) the hotkey path -
; makes sure ThrottleStop is up before forcing a profile, same as a real key press.
ManualSwitch(profile) {
    EnsureThrottleStopRunning()
    ApplyProfile(profile)
}

EnsureThrottleStopRunning() {
    global TS_PATH, ENABLE_THROTTLESTOP, AUTOLAUNCH_THROTTLESTOP
    if !ENABLE_THROTTLESTOP
        return
    if ProcessExist("ThrottleStop.exe")
        return
    if !AUTOLAUNCH_THROTTLESTOP {
        WarnNotRunning("ThrottleStop")
        return
    }
    try {
        ; v1.4.0: launch with its own folder as working directory, so ThrottleStop
        ; can find its local .cfg/.ini next to the exe instead of resolving relative
        ; paths against whatever directory this script happened to start from.
        SplitPath(TS_PATH, , &tsDir)
        Run(TS_PATH, tsDir)
        WinWait("ahk_exe ThrottleStop.exe",, 8)
        Sleep(800)
    } catch as err {
        Log("Failed to launch ThrottleStop: " err.Message)
    }
}

; v1.4.0: asks for the Windows username + apps-folder name once (instead of
; making people hand-edit config.ahk), pre-filled with sensible guesses, and
; writes the answers back into config.ahk so this never runs again.
;
; v1.4.0 bugfix: persisting used to be FileDelete(cfgPath) followed by
; FileAppend(cfgText, cfgPath) - the exact same "delete then append" pattern
; that corrupted the state file (see ApplyProfile). If the delete failed here
; (locked file, permissions, AV), the append would land on top of the OLD
; config.ahk contents, silently duplicating/mangling the file. Now uses
; FileOpen(cfgPath, "w") to truncate-and-write in one step, same fix as below.
RunFirstTimeSetup() {
    global WIN_USERNAME, APPS_FOLDER_NAME

    userBox := InputBox(
        "First run - what's your Windows username?`n`n"
        "(the folder under C:\Users\ where ThrottleStop and NVIDIA Profile "
        "Inspector are installed - pre-filled with your current login)",
        "Copilot Toggle - First-Run Setup",
        "w440 h170",
        A_UserName
    )
    if (userBox.Result = "Cancel" || Trim(userBox.Value) = "")
        return   ; the placeholder check right after this call will warn instead

    newUsername := Trim(userBox.Value)

    folderBox := InputBox(
        "And the folder name under C:\Users\" newUsername "\ that holds "
        "ThrottleStop / NVIDIA Profile Inspector?`n`n"
        "Leave as `"app`" unless you installed them somewhere else.",
        "Copilot Toggle - First-Run Setup",
        "w440 h170",
        APPS_FOLDER_NAME
    )
    newFolder := (folderBox.Result = "Cancel" || Trim(folderBox.Value) = "")
        ? APPS_FOLDER_NAME
        : Trim(folderBox.Value)

    WIN_USERNAME := newUsername
    APPS_FOLDER_NAME := newFolder
    BuildPaths()   ; recompute TS_PATH/NVI_PATH/NIP_* for this run immediately

    ; persist to config.ahk so it's only ever asked once
    try {
        cfgPath := A_ScriptDir "\config.ahk"
        cfgText := FileRead(cfgPath)
        cfgText := StrReplace(cfgText, 'WIN_USERNAME     := "place holder"', 'WIN_USERNAME     := "' newUsername '"')
        cfgText := StrReplace(cfgText, 'APPS_FOLDER_NAME := "app"', 'APPS_FOLDER_NAME := "' newFolder '"')

        cfgHandle := FileOpen(cfgPath, "w")
        cfgHandle.Write(cfgText)
        cfgHandle.Close()

        Log("First-run setup saved: WIN_USERNAME=" newUsername ", APPS_FOLDER_NAME=" newFolder)
    } catch as err {
        Log("Failed to save first-run setup to config.ahk: " err.Message)
        MsgBox(
            "Got your answers, but couldn't save them into config.ahk (" err.Message ").`n`n"
            "You'll be asked again next run, or you can set WIN_USERNAME / "
            "APPS_FOLDER_NAME in config.ahk by hand.",
            "Copilot Toggle - Setup",
            "Icon!"
        )
    }
}

; v1.4.0: shared warning for "tool should be running/launched but AUTOLAUNCH is off,
; or it's not running and we're not allowed to start it" - a short toast + log line
; instead of quietly doing nothing, so it's obvious why a step didn't apply.
WarnNotRunning(label) {
    Log("WARNING: " label " is not running and auto-launch is disabled for it in config.ahk - skipping.")
    ToolTip(label " isn't running - skipped (auto-launch is off in config.ahk)")
    SetTimer(() => ToolTip(), -2500)
}

ApplyProfile(profile) {
    global CurrentProfile, StateFile
    global HK_GAME, HK_PERF, HK_WORK
    global NVI_PATH, NIP_GAME, NIP_PERF
    global AB_PATH, AB_GAME, AB_WORK
    global MSI_CENTER_APPID
    global REFRESH_NATIVE, REFRESH_WORK
    global ENABLE_THROTTLESTOP, ENABLE_NVIDIA_INSPECTOR, ENABLE_AFTERBURNER, ENABLE_MSI_CENTER
    global AUTOLAUNCH_AFTERBURNER

    ; show the popup FIRST, before anything that can blank the screen,
    ; so WORK MODE is visibly confirmed before the 60Hz drop hits
    ShowIndicator(profile)
    Sleep(120)   ; let the popup actually paint before the refresh-rate change

    if (profile = "game") {
        if ENABLE_THROTTLESTOP
            SafeRun(HK_GAME, "")
        if ENABLE_NVIDIA_INSPECTOR
            SafeRun('"' NVI_PATH '" -silentImport "' NIP_GAME '"', "NVIDIA Profile Inspector (game)")
        if ENABLE_AFTERBURNER
            RunAfterburnerProfile(AB_GAME, false)
        SetRefreshRate(REFRESH_NATIVE)
        SetEnergySaver(0)
        SoundSetMute(0)

    } else if (profile = "perf") {
        if ENABLE_THROTTLESTOP
            SafeRun(HK_PERF, "")
        if ENABLE_NVIDIA_INSPECTOR
            SafeRun('"' NVI_PATH '" -silentImport "' NIP_PERF '"', "NVIDIA Profile Inspector (perf)")
        if ENABLE_AFTERBURNER
            RunAfterburnerProfile(AB_GAME, false)   ; keep full GPU clocks in Perf too
        SetRefreshRate(REFRESH_NATIVE)
        SetEnergySaver(0)
        SoundSetMute(0)

    } else { ; work
        if ENABLE_THROTTLESTOP
            SafeRun(HK_WORK, "")
        if ENABLE_NVIDIA_INSPECTOR
            SafeRun('"' NVI_PATH '" -silentImport "' NIP_PERF '"', "NVIDIA Profile Inspector (work)")
        if ENABLE_AFTERBURNER
            RunAfterburnerProfile(AB_WORK, AUTOLAUNCH_AFTERBURNER)   ; config decides if Work may launch Afterburner
        SetRefreshRate(REFRESH_WORK)
        SetEnergySaver(100)
        SoundSetMute(1)
        if ENABLE_MSI_CENTER {
            try {
                Run('explorer.exe shell:AppsFolder\' MSI_CENTER_APPID)
            } catch as err {
                Log("Failed to launch MSI Center: " err.Message)
            }
        } else {
            Log("MSI Center auto-launch skipped (ENABLE_MSI_CENTER = false in config.ahk).")
        }
    }

    CurrentProfile := profile

    ; v1.4.0 bugfix: try FileDelete() followed by FileAppend() would silently
    ; append instead of overwrite if the delete failed (e.g. file briefly locked
    ; by antivirus/backup), leaving a corrupted concatenated state like
    ; "gameperf" that the "perf"/"game"/"work" check above would then reject on
    ; the next launch. FileOpen(..., "w") always truncates first, so a write
    ; either replaces the whole contents cleanly or fails outright - no middle state.
    try {
        stateHandle := FileOpen(StateFile, "w")
        stateHandle.Write(CurrentProfile)
        stateHandle.Close()
    } catch as err {
        Log("Failed to write state file: " err.Message)
    }
}

; Game/Perf: only talks to Afterburner if it's already running, never launches it.
; Work mode: allowed to launch it fresh so the downclock profile actually applies.
;
; v1.4.0: dropped the WarnNotRunning() toast for the "not allowed to launch and
; not currently running" case - Afterburner is never auto-launched in Game/Perf
; by design, so popping a toast every single Game<->Perf tap was just noise.
; Still logged (silently) for anyone who wants to check toggle.log.
RunAfterburnerProfile(argument, allowLaunch) {
    global AB_PATH
    if !allowLaunch && !ProcessExist("MSIAfterburner.exe") {
        Log("MSI Afterburner not running - skipped (not auto-launched in Game/Perf by design).")
        return
    }
    try {
        ; v1.4.0: same working-directory fix as ThrottleStop above - Afterburner
        ; profile files (.cfg) are looked up next to the exe by default.
        SplitPath(AB_PATH, , &abDir)
        Run('"' AB_PATH '" ' argument, abDir, "Hide")
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
    ; The old hardcoded Buffer(220, 0) worked, but 220 was never actually the
    ; real size of DEVMODEA - it was just "big enough" so the extra bytes went
    ; unused. The two-call "probe" version added here to be extra-safe turned
    ; out to be the more fragile path (EnumDisplaySettingsA doesn't reliably
    ; echo back a corrected dmSize, so the probe wasn't actually validating
    ; anything - and it was silently breaking the 60Hz switch in Work mode).
    ; DEVMODEA's real, documented size is 156 bytes on both x86 and x64 -
    ; using that exact value directly is simpler and more correct than either.
    static DEVMODEA_SIZE := 156

    dm := Buffer(DEVMODEA_SIZE, 0)
    NumPut("UShort", DEVMODEA_SIZE, dm, 36)   ; dmSize

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

    ; v1.4.0 bugfix: two taps inside the 1800ms toast lifetime used to spawn a second
    ; Gui before the first's auto-destroy timer fired, leaving overlapping toasts on
    ; screen. Cancel any pending destroy and remove the old one before making a new one.
    static activeInd := ""
    static destroyFunc := ""
    if activeInd {
        try SetTimer(destroyFunc, 0)
        try activeInd.Destroy()
        activeInd := ""
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

    activeInd := ind
    destroyFunc := () => (ind.Destroy(), activeInd := "")
    SetTimer(destroyFunc, -1800)
}

Log(msg) {
    global LogFile, SCRIPT_VERSION
    try {
        ; keep the log from growing forever: once it passes ~500KB, keep one
        ; rotated backup (.old) and start a fresh file instead of appending forever
        if FileExist(LogFile) && FileGetSize(LogFile) > 500000 {
            try FileDelete(LogFile ".old")
            FileMove(LogFile, LogFile ".old")
        }
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " [v" SCRIPT_VERSION "] - " msg "`n", LogFile)
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
