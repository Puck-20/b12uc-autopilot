# b12uc-autopilot, a Copilot Key Toggle for the MSI 15 B12UC

Turns the useless "Copilot" key on an MSI 15 B12UC into a 3-way power/performance switcher, using [AutoHotkey](https://www.autohotkey.com/) + [ThrottleStop](https://www.techpowerup.com/download/techpowerup-throttlestop/) + [NVIDIA Profile Inspector](https://github.com/Orbmu2k/nvidiaProfileInspector) + [MSI Afterburner](https://www.msi.com/Landing/afterburner/graphics-cards). This project can technically be used for any pc or key (instead of copilot), if you try and tweak it your own way.

> Built by one person, on their own time, for their own (slightly modified) B12UC. Not a corporate QA'd tool, read the [Disclaimer](#disclaimer) before you dive in, take in mind to take safety precaution when tweaking parameters that affect your cpu gpu and pc integrity. Dropped idle temps from **70°C → 52°C** in Perf mode on my machine, your temps will vary. Will not make a linux one, you can try if you want.

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2-green)
![Status](https://img.shields.io/badge/status-personal%20project-yellow)
![Version](https://img.shields.io/badge/version-1.3.0-orange)

> **Important, before you touch anything:** every path in the script and in this guide uses the literal text `place holder` instead of a real username. Do a **Ctrl+F** (or Find & Replace) for `place holder` in `CopilotThrottleStopToggle.ahk` or my own config files in the .rar, and swap it for your own Windows username, that's it, that's the only thing that has to change to make this yours. Everything else below explains why and where. But i kindly advise to make the config files yourself, it will suit better your own laptop.

> Also check out the **full beginner readme**, might suit some people better, and if you want to use ai copy the quickstart one (and read it a bit) and copy the other one.
**This .md is mostly to have a good looking github page**, you can switch between both the md and the txt readmes if you want to fully understand how i made this work.

> I have truly no way of telling **when i will update this**, and copying from the disclaimer below, **feel free to modify anything** to fit your setup, **with or without AI help** (i did use ai since i'm all alone on this, and yeah yeah ai coding but at least it works no?). Issues, PRs, **and forks welcome**,
this was **built for fun** and to hopefully **save someone else the trial and error**.

---

## What it does

| Action | Result |
|---|---|
| **Tap** the Copilot key | Toggles **GAME** ↔ **PERF** |
| **Hold** the Copilot key for 1 second | Switches to **WORK** mode (fires the instant 1s hits, doesn't wait for you to release) |

| Mode | CPU | GPU clocks | Screen | Extra |
|---|---|---|---|---|
| GAME | Turbo ON | Afterburner +0 offset | 144Hz | full power, fans can spin up |
| PERF | Turbo OFF | Afterburner +0 offset | 144Hz | quieter/cooler, still gaming-refresh screen |
| WORK | Turbo OFF + Power Saver | Afterburner -300 offset, auto-launches Afterburner if it's closed | 60Hz | speakers muted, MSI Center opens, Windows Energy Saver forced on |

A small rounded popup appears in the top-right corner every time you switch, confirming the active mode, and it's timed to show up **before** the screen actually changes.

---

## Table of contents

- [Prerequisites](#prerequisites)
- [Folder structure](#folder-structure)
- [Setup](#setup)
  - [1. Install](#1-install)
  - [2. Create your folder](#2-create-your-folder)
  - [3. ThrottleStop profiles](#3-throttlestop-profiles)
  - [4. NVIDIA GPU profiles](#4-nvidia-gpu-profiles)
  - [5. Edit script paths](#5-edit-script-paths)
  - [6. Autostart (Scheduled Tasks)](#6-autostart-scheduled-tasks)
  - [7. Test](#7-test)
- [What each ThrottleStop setting does](#what-each-throttlestop-setting-does)
- [Measured clock speeds](#measured-clock-speeds-my-machine)
- [Afterburner behavior](#afterburner-behavior)
- [Logging](#logging)
- [Troubleshooting](#troubleshooting)
- [Known issues / limitations](#known-issues--limitations)
- [Roadmap / notes](#roadmap--notes)
- [Fan curve (WIP)](#fan-curve-wip-personal-numbers-not-a-recommendation)
- [Disclaimer](#disclaimer)

---

## Prerequisites

| Software | Required? | Link |
|---|---|---|
| AutoHotkey v2 | Yes | https://www.autohotkey.com/ |
| ThrottleStop | Yes | https://www.techpowerup.com/download/techpowerup-throttlestop/ |
| NVIDIA Profile Inspector | Yes | https://github.com/Orbmu2k/nvidiaProfileInspector |
| MSI Center | Yes (usually preinstalled) | MSI's support site for your model |
| MSI Afterburner | Yes, wired into the script now for Work mode's downclock | https://www.msi.com/Landing/afterburner/graphics-cards |

> ⚠️ **Do not install NirCmd.** An earlier version of this project used it for refresh-rate switching, it's no longer needed (refresh rate is done via a direct Windows API call in the script) and a VirusTotal scan flagged it as suspicious.

---

## Folder structure

Everything lives in one folder, name and location are up to you, just keep the script's path variables (Step 5) matching wherever you put it:

```
app/
├── CopilotThrottleStopToggle.ahk
├── ts_profile_state.txt              # auto-created on first run, leave it alone
├── toggle.log                        # auto-created, only writes on failures, leave it alone
├── ThrottleStop.exe
├── ThrottleStop.ini                  # created once you save profiles inside ThrottleStop
└── nvidiaprofileinspec/
    ├── nvidiaProfileInspector.exe
    ├── global_profile_game.nip       # created in Step 4
    └── global_profile_perf.nip       # created in Step 4
```

MSI Afterburner installs and lives wherever its own installer puts it (usually `C:\Program Files (x86)\MSI Afterburner\`), it doesn't need to sit inside this folder.

---

## Setup

### 1. Install

Install in this order: AutoHotkey v2 → ThrottleStop → NVIDIA Profile Inspector → MSI Afterburner → confirm MSI Center is present. ThrottleStop and NVIDIA Profile Inspector are both portable, no installer, just extract the zip. Afterburner has a normal installer.

### 2. Create your folder

```
C:\Users\place holder\app\
```

Save `CopilotThrottleStopToggle.ahk` directly into it. (Can be named anything or put anywhere, just make sure every path in the script points at wherever you actually put it.)

### 3. ThrottleStop profiles

ThrottleStop saves up to 8 CPU presets ("profiles"). This project uses 3:

| Profile | Purpose | Settings |
|---|---|---|
| 1 | Performance | `Disable Turbo` ✔ · optional: Speed Shift EPP ≈ 128 |
| 2 | Game | Turbo ON, defaults |
| 4 | Work / Battery | `Disable Turbo` ✔ · `SpeedStep` ✔ · `C1E` ✔ · `Power Saver` ✔ · EPP ≈ 255 |

Assign hotkeys under **Options → Hotkeys** (tick **NUMPAD**, keep NumLock ON):

| Profile | Hotkey |
|---|---|
| 1 (Perf) | `Ctrl + Alt + Numpad 2` |
| 2 (Game) | `Ctrl + Alt + Numpad 1` |
| 4 (Work) | `Ctrl + Alt + Numpad 3` |

These must exactly match `HK_PERF` / `HK_GAME` / `HK_WORK` in the script. Once saved, ThrottleStop writes a `ThrottleStop.ini` next to its exe, back that file up so you never have to redo this from scratch.

### 4. NVIDIA GPU profiles

This flips the driver's **Power Management Mode** (Base Profile → `0x1 - Common`) between *Prefer Maximum Performance* and *Optimal Power*, exported as two `.nip` files the script silently imports on switch:

```powershell
cd C:\Users\place holder\app\nvidiaprofileinspec
nvidiaProfileInspector.exe -exportCustomized
```

Set the mode, apply, export, then rename the generated file to `global_profile_game.nip`. Repeat with the mode set to *Optimal Power* → `global_profile_perf.nip`. (Work mode reuses `global_profile_perf.nip` too, Optimal Power is what you want there as well.)

Also set up **two Afterburner profiles** while you're at it: Profile 1 with a `+0` core/memory offset (Game & Perf), Profile 2 with a negative core offset, e.g. `-200` to `-300` (Work). Voltage/power-limit sliders are usually vendor-locked on OEM laptops like this one, but the Core/Memory clock offset sliders should still work.

### 5. Edit script paths

Open `CopilotThrottleStopToggle.ahk` and update every `place holder`:

```ahk
TS_PATH   := "C:\Users\place holder\app\ThrottleStop.exe"
NVI_PATH  := "C:\Users\place holder\app\nvidiaprofileinspec\nvidiaProfileInspector.exe"
NIP_GAME  := "C:\Users\place holder\app\nvidiaprofileinspec\global_profile_game.nip"
NIP_PERF  := "C:\Users\place holder\app\nvidiaprofileinspec\global_profile_perf.nip"
AB_PATH   := "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe"
```

Change `place holder` to your own actual Windows username in the four lines above. To find your username: open File Explorer, your personal folder under **This PC → Local Disk (C:) → Users** shows it. Confirm `AB_PATH` matches where Afterburner actually installed on your machine (right-click its shortcut → **Open file location**).

`MSI_CENTER_APPID` is different, it's not a normal file path. On newer machines MSI Center is a packaged Windows app, not a regular exe, so you can't just point at an install folder. Open PowerShell and run:

```powershell
Get-StartApps | Where-Object {$_.Name -like "*MSI Center*"}
```

Copy the `AppID` value it prints out (yours will differ from mine) and paste it into `MSI_CENTER_APPID`, keeping the quote marks. If your install turns out to be a normal exe instead, swap that line for a plain path and change the launch call to a regular `Run()`, `toggle.log` will tell you if the AppID method fails.

### 6. Autostart (Scheduled Tasks)

Two elevated Scheduled Tasks so both programs launch silently at login, no UAC prompt:

| Task | Program | Arguments |
|---|---|---|
| `ThrottleStopAutoStart` | `ThrottleStop.exe` | , |
| `CopilotToggleAutoStart` | `AutoHotkey64.exe` | `"C:\Users\place holder\app\CopilotThrottleStopToggle.ahk"` |

Both need: **Run with highest privileges**, trigger **At log on**, and **AC power required** unchecked (laptop).

### 7. Test

1. Run both tasks manually from Task Scheduler (no reboot needed).
2. Task Manager → Details tab → confirm both show `Elevated = Yes`.
3. Tap the Copilot key → popup switches Game/Perf instantly, no UAC.
4. Hold 1 second → WORK popup appears *before* the 60Hz flicker, MSI Center opens, sound mutes.
5. Tap again from Work → back to Game, unmuted, 144Hz restored.
6. Check `toggle.log`, an empty or missing file is a good sign, it only writes when something actually fails.

---

## What each ThrottleStop setting does

> Disclaimer: gathered from ThrottleStop community guides, not independently verified against CPU internals, treat as "why this probably works," not gospel.

- **Disable Turbo**, stops the CPU boosting above base clock. The main lever for heat/noise.
- **SpeedStep**, legacy Intel clock scaling at the software level. Usually best left on, disabling can lock a fixed frequency/voltage rather than a lower one.
- **C1E**, governs deep idle states. ON = better idle efficiency/lower temps, OFF = clocks stay "ready" at the cost of idle power draw.
- **Power Saver** (checkbox), forces the lowest available multiplier. Does most of the work for how low Work mode goes.
- **Speed Shift EPP** (0-255), hardware-level successor to SpeedStep. `0` ≈ prefer max frequency, `255` ≈ prefer minimum/efficiency. Low values (0-32) suit Perf, high values (128-255) suit Work.

## Measured clock speeds (my machine)

Watched live via ThrottleStop's monitor + Task Manager, not spec-sheet numbers, just what happened on this specific B12UC (modified SSD/RAM, particular BIOS). Expect the same general shape on yours (Game > Perf > Work), not identical figures.

| Mode | Observed |
|---|---|
| GAME (Turbo ON) | ~2.2GHz light load → 3.8GHz under load (touched ~4.2GHz in Elden Ring) |
| PERF (Turbo OFF) | ~1.1-1.5GHz, light browser use |
| WORK (Turbo OFF + Power Saver) | ~1GHz, down to 0.60GHz |

A `-200MHz` Afterburner core offset in Work mode visibly drops GPU clocks too, confirmed under real load (a light-load test alone won't show it, that's a false negative from not enough load, not a broken offset).

---

## Afterburner behavior

Afterburner is fully wired in now, but on purpose it does **not** behave the same in every mode:

- **Game/Perf**: only applies the clock profile if Afterburner is already running. Never launches it if it's closed.
- **Work**: allowed to launch Afterburner fresh if it's closed, so the downclock profile actually gets applied.

If you want Afterburner active during Game/Perf too, just open it yourself once, the script will pick it up from there.

---

## Logging

`toggle.log` only writes a line when something actually **fails** (a launch, the refresh-rate change, etc), not on every successful switch, so an empty or short log is a good sign, not a broken one. It auto-rotates to `toggle.log.old` once it passes about 500KB, so it won't grow forever.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Popup shows but profile doesn't change | ThrottleStop hotkeys don't match the script exactly, check digit, NUMPAD tick, NumLock |
| Windows security prompt on switch | Script or ThrottleStop isn't running elevated, redo the Scheduled Tasks |
| Nothing happens on key press | MSI Center may be grabbing the Copilot/AI key itself, check its settings |
| Screen doesn't drop to 60Hz | Can vary by display driver, other actions (CPU/GPU/mute/MSI Center) still work |
| Afterburner clocks don't change in Game/Perf | Expected if Afterburner was closed, it only auto-opens for Work mode |
| Energy Saver doesn't seem to turn on | See [Known issues](#known-issues--limitations), only confirmed reliable on battery so far |

---

## Known issues / limitations

- Windows Energy Saver only reliably turns on while on battery, not confirmed working the same way plugged in.
- Refresh-rate target display (`TARGET_DISPLAY`) is hardcoded to the internal panel, might hit the wrong screen on multi-monitor setups. Configurable, not bulletproof.
- MSI Center's launch method is tied to a specific AppID, might need re-finding on your machine after an update (see Step 5).
- The Copilot key's exact signal (`Shift+Win+F23`) is what my firmware sends, could differ on other units or Windows versions.
- Not fully fool-proofed against every laptop configuration, built and tested on one B12UC (mine).
- No tray icon or GUI, no battery-percentage-aware auto-switching, both deliberately out of scope for now.
- Other bugs i don't know about yet.

---

## Roadmap / notes

- `ts_profile_state.txt` remembers the last mode across reboots, don't delete it.
- `toggle.log` is error-only now and auto-rotates, see [Logging](#logging).
- If MSI Center ever updates and its AppID changes, re-run the PowerShell command from Step 5 to get the new one.
- Heads up, not everything here has been fully fool-proofed, a few edge cases might still be unchecked. If something's off, open an issue or fix it yourself.
- If you'd rather not get into the weeds, hand this repo (script + README) to Claude or another AI assistant and ask it to walk you through setup, or to modify it for your own laptop.

### Fan curve (WIP personal numbers not a recommendation)

> ⚠️ Still in progress and not fully tested against all three modes yet. This is what I'm currently running, tuned to my own decibel/temp preference and my phase-change thermal pad, **not** a validated or "best" curve. Don't copy it blindly onto your own unit, use it as a rough starting point at most, and adjust to your own fan-noise tolerance and thermal setup.

Set via MSI Center's custom fan curve editor:

| Step | Fan speed |
|---|---|
| 1 | 0% |
| 2 | 25% |
| 3 | 38% |
| 4 | 44% |
| 5 | 60% |
| 6 | 110% | 

Tuned alongside a phase-change thermal pad, results will differ with stock thermal paste/pad. (150% dont changes the temp that much tbh)

---

## Disclaimer

This is a solo hobby project, tuned on one person's own (slightly modified) MSI 15 B12UC, not a lab benchmark, not vendor-tested, no guarantees for your exact unit. Again, all config paths use the literal placeholder text `place holder`, Ctrl+F it and swap in your own Windows username wherever it appears. Feel free to modify anything to fit your setup, with or without AI help (i did use ai since i'm all alone on this, and yeah yeah ai coding but at least it works no?). Issues, PRs, and forks welcome, this was built for fun and to hopefully save someone else the trial and error.

Licensed under MIT, forking and personal use welcome, resale isn't.
