#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================
; Copilot Key -> ThrottleStop / GPU / Refresh Rate Toggle (MSI B12UC)
; ============================================================
; IMPORTANT: Run this script AS ADMINISTRATOR. ThrottleStop
; runs elevated, and Windows blocks simulated keystrokes from a
; non-elevated process reaching an elevated one (UIPI).
;
;   TAP the Copilot key   -> toggles GAME <-> PERF
;   HOLD the Copilot key  -> switches straight to WORK mode
; ============================================================

; --- EDIT THESE TO MATCH YOUR SETUP ---
TS_PATH   := "C:\Users\antoi\app\ThrottleStop.exe"   ; full path to ThrottleStop.exe
HK_PERF   := "^!{Numpad2}"   ; Profile 1 = Performance -> Ctrl+Alt+NUMPAD 2
HK_GAME   := "^!{Numpad1}"   ; Profile 2 = Game        -> Ctrl+Alt+NUMPAD 1
HK_WORK   := "^!{Numpad3}"   ; Profile 4 = Battery     -> Ctrl+Alt+NUMPAD 3

; NVIDIA Profile Inspector (used instead of powercfg since MSI Center overrides Windows power plans)
NVI_PATH  := "C:\Users\antoi\app\nvidiaprofileinspec\nvidiaProfileInspector.exe"
NIP_GAME  := "C:\Users\antoi\app\nvidiaprofileinspec\global_profile_game.nip"
NIP_PERF  := "C:\Users\antoi\app\nvidiaprofileinspec\global_profile_perf.nip"   ; also used for Work mode (Optimal Power)

; Display refresh rates (no external tool needed - uses the Windows API directly)
REFRESH_NATIVE := 144   ; your normal Game/Perf refresh rate
REFRESH_WORK   := 60    ; refresh rate while in Work mode

LONGPRESS_MS := 600     ; how long to hold the Copilot key to trigger Work mode
; ----------------------------------------

StateFile := A_ScriptDir "\ts_profile_state.txt"

CurrentProfile := "game"
if FileExist(StateFile) {
    saved := Trim(FileRead(StateFile))
    if (saved = "perf" || saved = "game" || saved = "work")
        CurrentProfile := saved
}

ShowIndicator(CurrentProfile)

; --- Copilot key sends Left Shift + Win + F23 ---
+#F23:: {
    global CurrentProfile

    ; swallow the default "open Copilot" action
    Send("{Blind}{LShift Up}{LWin Up}")

    startTime := A_TickCount
    KeyWait("F23")   ; wait for physical key release to measure hold duration
    heldMs := A_TickCount - startTime

    if !ProcessExist("ThrottleStop.exe") {
        Run(TS_PATH)
        WinWait("ahk_exe ThrottleStop.exe",, 8)
        Sleep(800)
    }

    if (heldMs >= LONGPRESS_MS) {
        newProfile := "work"
    } else if (CurrentProfile = "game") {
        newProfile := "perf"
    } else {
        newProfile := "game"
    }

    ApplyProfile(newProfile)
}

ApplyProfile(profile) {
    global CurrentProfile, StateFile
    global HK_GAME, HK_PERF, HK_WORK
    global NVI_PATH, NIP_GAME, NIP_PERF
    global REFRESH_NATIVE, REFRESH_WORK

    if (profile = "game") {
        Send(HK_GAME)
        Run('"' NVI_PATH '" -silentImport "' NIP_GAME '"',, "Hide")
        SetRefreshRate(REFRESH_NATIVE)
    } else if (profile = "perf") {
        Send(HK_PERF)
        Run('"' NVI_PATH '" -silentImport "' NIP_PERF '"',, "Hide")
        SetRefreshRate(REFRESH_NATIVE)
    } else { ; work
        Send(HK_WORK)
        Run('"' NVI_PATH '" -silentImport "' NIP_PERF '"',, "Hide")  ; reuse Optimal Power profile
        SetRefreshRate(REFRESH_WORK)
    }

    CurrentProfile := profile

    try FileDelete(StateFile)
    FileAppend(CurrentProfile, StateFile)

    ShowIndicator(CurrentProfile)
}

; Change display refresh rate using the Windows API directly - no external tool needed
SetRefreshRate(hz) {
    static DM_DISPLAYFREQUENCY := 0x400000

    dm := Buffer(220, 0)
    NumPut("UShort", 220, dm, 36)   ; dmSize

    if !DllCall("EnumDisplaySettingsA", "Ptr", 0, "Int", -1, "Ptr", dm)
        return false

    existingFields := NumGet(dm, 40, "UInt")
    NumPut("UInt", existingFields | DM_DISPLAYFREQUENCY, dm, 40)   ; dmFields
    NumPut("UInt", hz, dm, 120)                                    ; dmDisplayFrequency

    result := DllCall("ChangeDisplaySettingsA", "Ptr", dm, "UInt", 0)
    return (result = 0)   ; DISP_CHANGE_SUCCESSFUL
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
        subtitle := "Downclocked  ·  GPU Optimal  ·  60Hz"
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
