COPILOT KEY -> THROTTLESTOP / GPU / REFRESH RATE TOGGLE
=========================================================

Turns the dedicated Copilot key on your keyboard into a physical switch
for your laptop's performance mode, no Windows Copilot popup, just
instant profile switching.

Built for one specific laptop (MSI 15 B12UC) by one person, for their
own use, shared as-is. It'll very likely need small tweaks (paths,
hotkeys, display target) to work on a different machine. This guide
walks you through all of them.

WHAT IT DOES
------------
- Tap the Copilot key              : toggles between Game and Perf mode
- Hold the Copilot key for 1 second: switches to Work mode
- Ctrl+Alt+F9                      : pause/resume the whole script
- Right-click the tray icon        : manually force Game / Perf / Work,
                                      in case the key ever misbehaves

  Game  - Full turbo, max GPU clocks, native refresh rate (144Hz), sound on
  Perf  - Turbo off but still "optimal" GPU settings, native refresh rate,
          sound on
  Work  - Downclocked CPU, GPU dialed back, 60Hz, sound muted, Energy
          Saver on, opens MSI Center


1. WHAT YOU'LL NEED
--------------------

You don't need all of these. Every tool can be switched off in
config.ahk if you don't use it. But for the full experience:

  AutoHotkey v2
    Runs the script itself. Required.
    https://www.autohotkey.com/download/

  ThrottleStop
    CPU power/clock profile switching.
    https://www.techpowerup.com/download/techpowerup-throttlestop/

  NVIDIA Profile Inspector
    Imports GPU driver profiles per mode (NVIDIA GPUs only).
    https://github.com/Orbmu2k/nvidiaProfileInspector/releases

  MSI Afterburner (optional)
    GPU clock offsets.
    https://www.msi.com/Landing/afterburner/graphics-cards
    or https://www.guru3d.com/download/msi-afterburner-beta-download/
    (the two only official sources)

  MSI Center (optional, MSI laptops only)
    Auto-opens in Work mode.
    Microsoft Store, or https://www.msi.com/Landing/MSI-Center

Grab the two script files too:
  - CopilotThrottleStopToggle.ahk
  - config.ahk

They must sit in the same folder, and config.ahk is the only file you
should ever need to edit.


2. INSTALL THE TOOLS
---------------------

1. Install AutoHotkey v2 (run the installer, keep the default options).
2. Install ThrottleStop (it doesn't have a real installer, it's a
   folder you unzip). A tidy spot is something like
   C:\Users\<you>\app\ThrottleStop\ , just remember the path, you'll
   need it in a minute.
3. Install NVIDIA Profile Inspector (skip if you're not on NVIDIA),
   just a folder to unzip, e.g. C:\Users\<you>\app\nvidiaprofileinspec\ .
4. Install MSI Afterburner if you want GPU clock offsets tied to your
   modes (this one has a real installer).
5. Install MSI Center from the Microsoft Store if you want it to pop
   up automatically in Work mode.


3. SET UP THROTTLESTOP PROFILES
---------------------------------

The script doesn't configure ThrottleStop for you. It just presses
whatever hotkey you tell it to, and trusts that hotkey is already
wired to a ThrottleStop profile with the settings you want.

1. Open ThrottleStop as Administrator.
2. Find its hotkey / profile-switching settings (usually under the
   Options button, the exact spot has moved around between
   ThrottleStop versions, so check the on-screen help "?" if you
   don't spot it right away).
3. Set up (at minimum) three profile slots with the CPU behavior you
   want for Game / Perf / Work, and assign each one a keyboard
   shortcut:
     Perf profile -> Ctrl+Alt+Numpad2
     Game profile -> Ctrl+Alt+Numpad1
     Work profile -> Ctrl+Alt+Numpad3

These three key combos are what config.ahk sends by default
(HK_PERF, HK_GAME, HK_WORK). If you'd rather use different keys,
that's fine, just make sure config.ahk matches whatever you actually
assigned inside ThrottleStop.


4. SET UP NVIDIA PROFILE INSPECTOR (OPTIONAL)
------------------------------------------------

If you use it, you'll need two .nip profile files:
  - global_profile_game.nip
  - global_profile_perf.nip

Open NVIDIA Profile Inspector, configure the global driver settings
you want for each mode, then use its export function to save them
under those names in the same folder as the .exe (e.g.
C:\Users\<you>\app\nvidiaprofileinspec\).


5. DROP THE SCRIPT FILES IN PLACE
------------------------------------

Put CopilotThrottleStopToggle.ahk and config.ahk together in one
folder, anywhere you like, e.g. C:\Users\<you>\app\CopilotToggle\ .


6. FIRST RUN
-------------

1. Right-click CopilotThrottleStopToggle.ahk -> Run as administrator.
   (It needs admin rights to talk to ThrottleStop and the GPU driver,
   see step 8 for why.)
2. A small popup will ask for your Windows username and the folder
   name your tools live in (pre-filled with sensible guesses). Confirm
   or edit, and it saves your answer straight into config.ahk, you
   won't be asked again.
3. If a path doesn't exist, you'll get a popup telling you exactly
   which one. Fix the path in config.ahk, or if you simply don't have
   that tool, set its ENABLE_* toggle to false instead.


7. TRY IT OUT
---------------

- Tap the Copilot key -> you should see a small on-screen popup switch
  between "GAME MODE" and "PERF MODE."
- Hold the Copilot key for about a second -> "WORK MODE" popup, screen
  may briefly flicker as the refresh rate drops to 60Hz.
- Right-click the tray icon (look for it near the clock, click the
  little "^" arrow to show hidden icons if needed) to force a mode
  manually.
- Ctrl+Alt+F9 pauses or resumes the whole script.


8. MAKE IT START AUTOMATICALLY, ELEVATED (RECOMMENDED)
----------------------------------------------------------

Running the .ahk file directly means you have to remember to "Run as
administrator" every time, and it won't survive a reboot. A
Scheduled Task fixes both:

1. Press Win+R, type taskschd.msc, hit Enter.
2. In the right-hand panel, click "Create Task..." (not "Create Basic
   Task", you need the extra options).
3. General tab: Name it something like "Copilot Toggle". Check
   "Run with highest privileges."
4. Triggers tab: Click "New..." -> Begin the task: "At log on" -> OK.
5. Actions tab: Click "New..." -> Action: "Start a program".
     Program/script: the AutoHotkey v2 executable, typically
       C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
     Add arguments: the full path to your script, in quotes, e.g.
       "C:\Users\you\app\CopilotToggle\CopilotThrottleStopToggle.ahk"
6. Conditions tab: if this is a laptop, uncheck "Start the task only
   if the computer is on AC power" so it also runs on battery.
7. Click OK, enter your Windows password if prompted.

Now it'll launch elevated, automatically, every time you log in.


9. UNDERSTANDING CONFIG.AHK
------------------------------

  WIN_USERNAME / APPS_FOLDER_NAME
    Builds the paths to ThrottleStop and NVIDIA Profile Inspector.
    Set automatically by the first-run wizard.

  AB_PATH
    Path to MSIAfterburner.exe

  HK_PERF / HK_GAME / HK_WORK
    The keystrokes sent to trigger each ThrottleStop profile

  AB_GAME / AB_WORK
    Afterburner profile arguments (-profile1, -profile2, etc.)

  MSI_CENTER_APPID
    The packaged-app ID used to launch MSI Center in Work mode

  REFRESH_NATIVE / REFRESH_WORK
    Refresh rate (Hz) for Game/Perf vs. Work

  TARGET_DISPLAY
    Which display to change the refresh rate on (\\.\DISPLAY1 is
    usually the built-in laptop screen)

  LONGPRESS_SEC
    How long you need to hold the key to trigger Work mode

  DEBOUNCE_MS
    Minimum gap between switches, to ignore accidental double-taps

  ENABLE_THROTTLESTOP / ENABLE_NVIDIA_INSPECTOR / ENABLE_AFTERBURNER /
  ENABLE_MSI_CENTER
    Turn a whole tool on/off, the script skips it entirely if false

  AUTOLAUNCH_THROTTLESTOP / AUTOLAUNCH_AFTERBURNER
    If a tool isn't already running, should the script start it, or
    just warn you?


10. TROUBLESHOOTING
----------------------

"config.ahk still has 'place holder' in one or more paths"
  The first-run wizard got skipped or cancelled. Either restart the
  script to see the popup again, or open config.ahk and set
  WIN_USERNAME yourself.

"This path doesn't seem to exist"
  Double-check WIN_USERNAME / APPS_FOLDER_NAME in config.ahk, and that
  the tool is actually unzipped where you think it is. If you don't
  have that tool installed at all, flip its ENABLE_* setting to false.

"This script is not running as Administrator"
  ThrottleStop, NVIDIA Profile Inspector, and Afterburner all need
  elevation to apply changes. Without it, switching will silently
  fail. Use the Scheduled Task method in step 8, or right-click ->
  Run as administrator each time.

The Copilot key still opens Windows Copilot instead of switching modes
  Make sure the script is actually running (check the tray). If it
  was recently paused with Ctrl+Alt+F9, resume it the same way.

Refresh rate doesn't change, or changes the wrong screen
  TARGET_DISPLAY in config.ahk may be pointing at the wrong monitor.
  Try \\.\DISPLAY2 instead of \\.\DISPLAY1 (or check Windows Settings
  -> System -> Display -> Identify to see how your displays are
  numbered).

Something else looks off
  Check toggle.log in the same folder as the script. Every action and
  warning gets a timestamped line there, including the script version,
  which makes it easier to tell exactly what happened and when.


11. UNINSTALLING / DISABLING
-------------------------------

- To stop it temporarily: Ctrl+Alt+F9, or right-click the tray icon ->
  Exit.
- To stop it permanently: remove the Scheduled Task from step 8 (or
  just delete the script files if you never set one up).
- Nothing this script does is permanent. It only flips existing
  settings in ThrottleStop / the NVIDIA driver / Afterburner /
  Windows display settings, all of which you can change back by hand
  at any time.


DISCLAIMER
----------

This was built for one specific laptop and one specific setup.
Changing CPU voltage/clock limits and GPU driver profiles carries the
same general risks as using ThrottleStop, NVIDIA Profile Inspector, or
Afterburner on their own, use at your own risk, and keep an eye on
temperatures if you're pushing performance settings higher than stock.
