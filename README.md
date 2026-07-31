# Copilot Key Toggle - MSI 15 B12UC (Fresh Machine Setup)

This guide assumes you're starting from a brand new / freshly reset MSI 15 B12UC with nothing installed yet, or not. Follow it top to bottom.

> Built by one person, on their own time, for their own (slightly modified) B12UC. Not corporate QA'd, read the [Disclaimer](#disclaimer) before you get going. Your temps and clock numbers will differ from mine, don't take my numbers as gospel.

> **You don't have to follow this guide 100%.** Paths, which apps get launched, refresh rates, whether speakers mute, any of it, change whatever fits your own setup. This is just how I set mine up.

> **First time using GitHub for me**, so bear with the repo if anything's a bit off structurally. Also if you want, you can paste this README plus the script into an AI like Claude and have it walk you through setup or tweak the script for your specific machine, that's basically how i fixed bug and added extra thing that were to complicated for me.

> **Use at your own risk.** This touches CPU/GPU power behavior, display settings, and third-party tools. I'm not responsible for anything that goes sideways on your specific hardware/software combo, test each piece manually before trusting the automation.

---

## What it does

| Action | Result |
|---|---|
| **Tap** the Copilot key | Toggles **GAME** <-> **PERF** |
| **Hold** the Copilot key for 1 second | Switches to **WORK** mode, fires the instant 1s is reached, you don't need to release first |

| Mode | CPU (ThrottleStop) | GPU driver | GPU clocks (Afterburner) | Screen | Audio | Energy Saver | Extra |
|---|---|---|---|---|---|---|---|
| GAME | Turbo ON | Max Performance | +0 offset | 144Hz | unmuted | off | full power |
| PERF | Turbo OFF | Optimal Power | +0 offset | 144Hz | unmuted | off | quieter/cooler, still gaming refresh screen |
| WORK | Turbo OFF + Power Saver | Optimal Power | Negative offset (e.g. -300 core) | 60Hz | **muted** | **on (battery only, see known issues)** | **MSI Center launches automatically** |

A small rounded popup confirms the active mode every time you switch. It shows up before any screen blanking, so you actually see the confirmation instead of missing it during the flicker.

---

## Prerequisites (install in this order)

| Software | Required? | Link |
|---|---|---|
| AutoHotkey v2 | Yes | https://www.autohotkey.com/ |
| ThrottleStop | Yes | https://www.techpowerup.com/download/techpowerup-throttlestop/ |
| NVIDIA Profile Inspector | Yes | https://github.com/Orbmu2k/nvidiaProfileInspector |
| MSI Center | Yes (usually preinstalled, reinstall from MSI's support site for your model if it's missing) | your model's MSI support page |
| MSI Afterburner | Yes (used for the GPU clock offset in Work mode) | https://www.msi.com/Landing/afterburner/graphics-cards |

> Do not install NirCmd. Used it in an early version of this for refresh rate switching, don't need it anymore since the script does that with a direct Windows API call now. A VirusTotal scan flagged a NirCmd build I grabbed as suspicious (a sandbox even called it MALWARE outright), so just skip it entirely, not worth the risk for something we don't even need.

ThrottleStop and NVIDIA Profile Inspector are both portable, no installer, just extract the zip and run the exe.

---

## 1. Create your folder

```
C:\Users\<your-username>\app\
```

Put `CopilotThrottleStopToggle.ahk` directly inside it. Location and name are up to you, just make every path in the script's config block match wherever you actually put things.

---

## 2. ThrottleStop profiles

ThrottleStop saves up to 8 CPU presets. This uses 3 of them:

| Profile | Purpose | Settings |
|---|---|---|
| 1 | Performance | `Disable Turbo` checked, optional: Speed Shift EPP around 128 |
| 2 | Game | Turbo ON, defaults |
| 4 | Work / Battery | `Disable Turbo` + `SpeedStep` + `C1E` + `Power Saver` all checked, EPP around 255 |

Assign hotkeys under **Options -> Hotkeys** (tick **NUMPAD**, keep NumLock **ON**):

| Profile | Hotkey |
|---|---|
| 1 (Perf) | `Ctrl + Alt + Numpad 2` |
| 2 (Game) | `Ctrl + Alt + Numpad 1` |
| 4 (Work) | `Ctrl + Alt + Numpad 3` |

These have to match `HK_PERF` / `HK_GAME` / `HK_WORK` in the script's config block exactly, same digit, same checkboxes ticked.

Once saved, ThrottleStop writes `ThrottleStop.ini` next to its exe. Back that file up so you don't have to redo this from scratch if you ever reinstall.

---

## 3. NVIDIA GPU profiles

This flips the NVIDIA driver's Power Management Mode (Base Profile -> `0x1 - Common`) between Prefer Maximum Performance and Optimal Power, exported as two `.nip` files that the script silently imports on each switch.

```powershell
cd C:\Users\<your-username>\app\nvidiaprofileinspec
nvidiaProfileInspector.exe -exportCustomized
```

1. Open the tool, select **Base Profile**.
2. Set Power Management Mode to Prefer Maximum Performance, click the floppy disk Apply icon.
3. Run the export command above, rename the generated file to `global_profile_game.nip`.
4. Repeat with Power Management Mode set to Optimal Power, export again, rename to `global_profile_perf.nip`.

---

## 4. MSI Afterburner GPU clock profiles

1. Open Afterburner. Confirm your Core / Memory clock offset sliders actually move and apply (voltage and power limit are usually locked on laptops by MSI, that's normal, we only need the clock sliders to work).
2. With both sliders at +0, click User Profile "1", then Save. This is your Game/Perf profile.
3. Drag Core (MHz) down to roughly -300 to start (don't jump straight to something aggressive, bigger negative offsets risk a driver crash under sudden load). Apply it, play something demanding for a bit to confirm it's stable.
4. Click User Profile "2", then Save. This is your Work profile.

Test the offset under actual GPU load, not idle. Light games might not show any visible difference just because the GPU never needed to hit max boost in the first place, that doesn't mean the offset isn't working.

---

## 5. Edit the script's config block

Open `CopilotThrottleStopToggle.ahk`. Everything you need to change lives in one block near the top, clearly marked CONFIG:

```ahk
TS_PATH   := "C:\Users\place holder\app\ThrottleStop.exe"
NVI_PATH  := "C:\Users\place holder\app\nvidiaprofileinspec\nvidiaProfileInspector.exe"
NIP_GAME  := "C:\Users\place holder\app\nvidiaprofileinspec\global_profile_game.nip"
NIP_PERF  := "C:\Users\place holder\app\nvidiaprofileinspec\global_profile_perf.nip"
AB_PATH   := "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe"
MSI_CENTER_APPID := "9426MICRO-STARINTERNATION.MSICenter_kzh8wxbdkxb8p!App"
```

MSI Center ships as a packaged Windows app on a lot of newer MSI machines, not a normal exe you can right click and "Open file location" on. If yours is like that too, find your AppID by running this in PowerShell:

```powershell
Get-StartApps | Where-Object {$_.Name -like "*MSI Center*"}
```

and drop the `AppID` it prints into `MSI_CENTER_APPID` above. If your MSI Center install actually does have a normal exe, you can swap that line for a plain `Run()` call on the exe path instead, check `toggle.log`, it'll tell you if a launch attempt fails either way.

Do a Ctrl+F / Find & Replace for `place holder` and swap in your real Windows username (find it in File Explorer under This PC -> Local Disk (C:) -> Users).

Confirm `AB_PATH` yourself via right click its shortcut, Open file location, it varies by install and version so don't just trust the default I've put here. For `MSI_CENTER_APPID`, use the PowerShell command above rather than trusting my value, it's specific to how MSI Center is packaged on my machine.

---

## 6. Autostart (Scheduled Tasks)

Two elevated Scheduled Tasks so both ThrottleStop and the script launch silently at login, no UAC prompt:

| Task | Program | Arguments |
|---|---|---|
| `ThrottleStopAutoStart` | `ThrottleStop.exe` | none |
| `CopilotToggleAutoStart` | `AutoHotkey64.exe` (usually `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`) | `"C:\Users\<you>\app\CopilotThrottleStopToggle.ahk"` |

For each one: General tab, check "Run with highest privileges", Triggers, New, At log on, your account, Actions, New, point at the program above, Conditions, uncheck "Start only on AC power" since it's a laptop, OK, enter your password once when it asks.

If you've got `.xml` exports of these tasks already, just Import Task instead of building from scratch.

---

## 7. Test

1. Run both tasks manually from Task Scheduler (right click, Run), no reboot needed.
2. Task Manager, Details tab, confirm both `ThrottleStop.exe` and `AutoHotkey64.exe` show Elevated = Yes.
3. Tap the Copilot key, popup switches Game/Perf instantly, no UAC prompt.
4. Hold for 1 second, WORK MODE popup appears before the 60Hz drop, MSI Center opens, audio mutes.
5. Tap again from Work, back to Game, unmuted, 144Hz restored.

If something in Work mode doesn't fire (screen stays at 144Hz, ThrottleStop doesn't go to Power Saver, MSI Center doesn't open), check `toggle.log` in your app folder first before assuming the whole thing is broken. It logs exactly which step failed and why, way faster to diagnose than guessing.

---

## Folder contents, what to put where

```
app/
├── CopilotThrottleStopToggle.ahk
├── ts_profile_state.txt              (auto-created on first run, leave it alone)
├── toggle.log                        (auto-created, only writes when something fails, not every switch, rotates to .old past ~500KB)
├── ThrottleStop.exe
├── ThrottleStop.ini                  (created once you save profiles inside ThrottleStop, BACK THIS UP)
└── nvidiaprofileinspec/
    ├── nvidiaProfileInspector.exe
    ├── global_profile_game.nip
    └── global_profile_perf.nip
```

If you're restoring from a backup/export (Scheduled Task `.xml` files + `.nip` profiles):
- Add `CopilotThrottleStopToggle.ahk` itself.
- Add `ThrottleStop.exe` (fresh download) plus your backed up `ThrottleStop.ini` next to it.
- Put your `.nip` files inside `nvidiaprofileinspec\` alongside a fresh `nvidiaProfileInspector.exe`.
- Re-import your two Scheduled Task `.xml` files via Task Scheduler, Import Task.
- Redo your two Afterburner profiles by hand, they're not simple portable files by default, easier to just redo the slider setup on the new machine, only takes a couple minutes.
- Don't bundle the actual `.exe` files (ThrottleStop, NVIDIA Profile Inspector, Afterburner) if you push this to a public GitHub repo, just link the official download pages instead. Keeps the repo small and avoids any redistribution weirdness.

---

## What each ThrottleStop setting does

Gathered this from ThrottleStop community guides, not something I've personally verified against CPU internals, so treat it as "why this probably works" rather than gospel.

- Disable Turbo: stops the CPU boosting above base clock. The main lever for heat and noise.
- SpeedStep: legacy Intel clock scaling at the software level, usually best left on.
- C1E: governs deep idle states, ON means better idle efficiency and lower temps.
- Power Saver (the checkbox): forces the lowest available multiplier, does most of the work for how low Work mode goes.
- Speed Shift EPP (0 to 255): hardware level successor to SpeedStep, 0 prefers max frequency, 255 prefers minimum/efficiency.

## Measured clock speeds (my machine, yours will vary)

| Mode | Observed |
|---|---|
| GAME (Turbo ON) | ~2.2GHz light load, 3.8GHz under load (touched ~4.2GHz in Elden Ring) |
| PERF (Turbo OFF) | ~1.1 to 1.5GHz, light browser use |
| WORK (Turbo OFF + Power Saver) | ~1GHz, down to 0.60GHz |

---

## Known issues / limitations

Things that are either not fully solved, or behave a bit differently than you'd expect. Worth reading before you file an issue on something that's already a known quirk.

- **Energy Saver only reliably engages on battery, not while plugged in.** The script sets both the AC and DC threshold via `powercfg`, but on my machine the plugged-in side doesn't seem to force it the same way. Best guess is this is a Windows 11 24H2 Energy Saver quirk (the "also use on AC power" behavior might need to be toggled once by hand in Settings before the AC threshold actually does anything), not something fully confirmed. If you figure out the real cause, a PR would be very welcome.
- **Windows power plan switching (`powercfg /setactive`) doesn't work on this laptop at all**, MSI Center overrides it. That's the whole reason this project routes CPU control through ThrottleStop and GPU behavior through NVIDIA Profile Inspector / Afterburner instead of just using Windows' own power plans, they get silently ignored here.
- **MSI Center's launch method is machine specific.** It's shipped as a packaged Windows app on my unit, not a normal exe, so it's launched via its AppID rather than a file path. If your MSI Center install is a normal exe instead, swap the launch line for a plain `Run()` call on the exe path. Find your AppID (if you need it) with:
  ```powershell
  Get-StartApps | Where-Object {$_.Name -like "*MSI Center*"}
  ```
- **Refresh rate targeting uses a hardcoded display device name** (`TARGET_DISPLAY`, defaults to `\\.\DISPLAY1`). On a single-monitor laptop this is usually right, but if you've got an external monitor plugged in, it might hit the wrong screen, try `\\.\DISPLAY2` if so.
- **The Copilot key's signal (Shift+Win+F23) might not be universal.** This is what it sends on my unit's current firmware/Windows build. If the hotkey never fires at all, use AutoHotkey's Window Spy or a KeyHistory check to confirm what your specific key actually sends, then update the hotkey definition accordingly.
- **The script must run elevated, and there's no clean error when it isn't.** If it's not admin, the Copilot key still "does something" (popup shows, screen might even flicker) but ThrottleStop and the other elevated tools silently ignore the simulated keystrokes, Windows blocks synthetic input across privilege levels and doesn't report it as a failure. The startup warning popup is the only real signal, watch for it.
- **No tray icon or GUI**, everything is driven by the Copilot key alone. If you want a way to check current mode without pressing the key, that's not built, feel free to add one.
- **Battery percentage aware auto-switching isn't implemented** (see Design notes below).

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Popup shows but profile doesn't change | ThrottleStop hotkeys don't match the script exactly, check the digit, NUMPAD tick, and NumLock |
| Windows security prompt on switch | Script or ThrottleStop isn't running elevated, redo the Scheduled Tasks |
| Nothing happens on key press | MSI Center may be grabbing the Copilot/AI key itself, check its settings |
| Screen doesn't drop to 60Hz | Wrong `TARGET_DISPLAY` (try switching between `\\.\DISPLAY1` and `\\.\DISPLAY2`), or a driver quirk, check `toggle.log` for the exact error |
| Afterburner clocks don't seem to change | Confirm the sliders aren't locked (voltage/power limit usually are, that's fine, only Core/Mem offset needs to actually work), and test under real GPU load, not idle |
| MSI Center doesn't open | Confirm `MSI_CENTER_APPID` matches your actual install, re-run the `Get-StartApps` PowerShell command from step 5 to check |
| Something's silently not working | Check `toggle.log` in the app folder, it only writes when something actually fails (launches, refresh rate, etc), so anything in there is worth reading |
| Afterburner doesn't apply in Game/Perf | That's intentional now, Afterburner only auto-launches for Work mode. If it's closed during Game/Perf, the clock offset just doesn't apply until you open it yourself |

---

## Design notes, what's deliberately not here

Had a GitHub AI reviewer look at an earlier version of this and it gave a pretty solid list of suggestions. Here's what made it in versus what I skipped, and why.

Implemented:
- Config values centralized in one block at the top of the script.
- Elevation check on startup, warns with a popup if it's not running as admin.
- Logging (`toggle.log`) for failed tool launches only, doesn't log successful switches, stays small.
- A debounce guard against accidental double triggers.
- Safe exit behavior, reverts to Perf if the script gets closed or reloaded normally (skipped on shutdown/logoff so it doesn't hold up Windows closing).

Skipped for now, on purpose:
- Tray GUI / mode picker. The popup plus tap/hold already covers what I actually need day to day, a tray menu is just more surface area to maintain for something I'm building solo.
- EXE packaging / digital signing. Adds a build step and signing cost for a personal tool, running through the `.ahk` file and the AutoHotkey interpreter directly works fine and stays way easier to edit.
- Battery percentage aware auto switching. Interesting idea, not implemented, would need real testing to make sure it doesn't switch modes mid game just because the battery crossed some threshold.

Feel free to build any of these yourself if you want them, issues, PRs, and forks welcome.

---

## Disclaimer

This is a solo hobby project, tuned on my own (slightly modified) MSI 15 B12UC, not a lab benchmark, not vendor tested, no guarantees it'll behave the same on your exact unit. Every path in the script uses the literal placeholder text `place holder`, Ctrl+F it and swap in your own Windows username wherever it shows up. Feel free to modify anything to fit your setup, with or without AI help (I used AI since I'm doing this completely solo, yeah yeah AI coding, but hey, it works, no?). Issues, PRs, and forks welcome, this was built for fun and to hopefully save someone else the trial and error I went through.
