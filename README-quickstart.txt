COPILOT KEY TOGGLE - QUICKSTART
(MSI 15 B12UC, Copilot key -> ThrottleStop / GPU / Refresh Rate switch)

WHAT IT DOES
- Tap Copilot key            : toggle GAME <-> PERF
- Hold Copilot key ~1s       : switch to WORK mode
- Right-click the tray icon  : force Game/Perf/Work manually
- Ctrl+Alt+F9                : pause/resume the whole script

FILES NEEDED (same folder, config.ahk is the only one you should ever edit)
- CopilotThrottleStopToggle.ahk
- config.ahk

1. INSTALL
   - AutoHotkey v2                 https://www.autohotkey.com/download/
   - ThrottleStop                  https://www.techpowerup.com/download/techpowerup-throttlestop/  (unzip, no installer)
   - NVIDIA Profile Inspector      https://github.com/Orbmu2k/nvidiaProfileInspector/releases  (NVIDIA GPUs only, unzip)
   - MSI Afterburner (optional)    https://www.msi.com/Landing/afterburner/graphics-cards
   - MSI Center (optional)         Microsoft Store, MSI laptops only

2. THROTTLESTOP PROFILES
   Open ThrottleStop as Administrator -> Options -> set up 3 profiles, each with
   its own hotkey:
     Perf profile -> Ctrl+Alt+Numpad2
     Game profile -> Ctrl+Alt+Numpad1
     Work profile -> Ctrl+Alt+Numpad3
   These MUST match HK_PERF / HK_GAME / HK_WORK in config.ahk.

3. NVIDIA PROFILES (optional, skip if you're not on NVIDIA)
   In NVIDIA Profile Inspector, export two .nip files into its own folder:
     global_profile_game.nip
     global_profile_perf.nip

4. DROP THE SCRIPT FILES
   Put CopilotThrottleStopToggle.ahk and config.ahk together in one folder,
   e.g. C:\Users\<you>\app\CopilotToggle\

5. FIRST RUN
   Right-click CopilotThrottleStopToggle.ahk -> Run as administrator.
   A popup asks for your Windows username and your tools' folder name ->
   confirm, it writes the answer into config.ahk for you. Only asked once.
   If a path doesn't exist you'll get told exactly which one, fix it in
   config.ahk, or set that tool's ENABLE_* to false if you don't have it.

6. TEST
   Tap the key -> GAME/PERF popup switches instantly.
   Hold ~1s -> WORK popup, screen may briefly flicker to 60Hz.
   Right-click the tray icon -> force a mode manually.
   Ctrl+Alt+F9 -> pauses/resumes.

7. AUTOSTART (recommended)
   Task Scheduler -> Create Task -> check "Run with highest privileges" ->
   Trigger: At log on -> Action: Start a program
     Program:   C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
     Arguments: "C:\path\to\CopilotThrottleStopToggle.ahk"
   If this is a laptop, uncheck "Start only if on AC power".

CONFIG.AHK CHEAT SHEET
   WIN_USERNAME / APPS_FOLDER_NAME  -> builds tool paths (set by the wizard)
   AB_PATH                          -> path to MSIAfterburner.exe
   HK_PERF / HK_GAME / HK_WORK      -> keystrokes sent to trigger each ThrottleStop profile
   MSI_CENTER_APPID                 -> packaged-app ID used to launch MSI Center
   REFRESH_NATIVE / REFRESH_WORK    -> refresh rate (Hz) for Game/Perf vs Work
   TARGET_DISPLAY                   -> which display to change the refresh rate on
   ENABLE_*                         -> turn a whole tool on/off
   AUTOLAUNCH_*                     -> auto-launch a tool if it's not running, or just warn

Full explanations, every setting, and troubleshooting: see README-full-beginner.txt
