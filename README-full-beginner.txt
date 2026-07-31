============================================================
 COPILOT KEY TOGGLE -- COMPLETE BEGINNER SETUP GUIDE (v1.2)
============================================================

This guide assumes you are starting from a brand new / freshly reset
Windows install on an MSI 15 B12UC or not, and have never done any of this
before. Follow it top to bottom, in order. Don't skip steps.

-small long note- 

important : to modify any of the config file from my folder just search "place holder" and put your user name, -if- you took the path of making the "app folder"(see below it will make sense)

heads up i did not fool proof everything, tried but i think i left some files unchecked. Also if you are to lazy to modify or get in the mud, just give everything to claude, read a bit of this txt or the quick start one to understand how it works. After give it what what's needed to claude to understand and modify, as myself a lazy men a lot of thing here were made by the goat claude, yeah yeah ai coding, but at least it worked really well FOR ME (dropped for 70°c idling to 52°c with perf mode)*

* made a custom fan curve in msi center still in PROGRESS and testing with the modes, but good result (if you use phase changing thermal pad)  1: 0%,  2: 25%,  3: 38%,  4: 44%,  5: 60%,  6: 150% *
(custom made for me, and decibel to temp ratio (still for my liking)i don't say that this is the best fan curve just putting a base line with this project)



WHAT THIS PROJECT DOES, IN PLAIN WORDS:

Your laptop has a "Copilot" key on the keyboard that normally just
opens the Windows Copilot app. This project reprograms that key so
instead it switches your laptop between 3 power/performance modes:

  GAME  - full power, fans can spin up, best for gaming
  PERF  - CPU turbo off, quieter/cooler, still full 144Hz screen
  WORK  - CPU downclocked, screen dropped to 60Hz, speakers muted,
          MSI Center opens to manual switch user scenario -- meant for office work / browsing

  TAP the Copilot key once   -> switches between GAME and PERF
  HOLD the Copilot key for a full second -> jumps to WORK mode

A small popup box appears in the corner of your screen every time you
switch, telling you which mode you're now in.

This is done with 3 pieces of software working together:
  1. AutoHotkey  -- runs the actual script that listens for the key
  2. ThrottleStop -- controls the CPU (turbo on/off, downclocking)
  3. NVIDIA Profile Inspector -- controls the GPU's power behaviour


------------------------------------------------------------
STEP 1 -- INSTALL THE REQUIRED PROGRAMS
------------------------------------------------------------

Install these one at a time, in this order.

  1a. AutoHotkey v2
      Go to: https://www.autohotkey.com/
      Click Download, then run the installer.
      During install, nothing special to pick -- default options are fine.
      This installs the "engine" that runs our script.

  1b. ThrottleStop
      Go to: https://www.techpowerup.com/download/techpowerup-throttlestop/
      Download the zip file. This program does NOT have an installer --
      you just extract the zip somewhere and run the exe directly from
      inside that folder.
      Extract it to: C:\Users\<your username>\app\
      (so you end up with C:\Users\<you>\app\ThrottleStop.exe)

  1c. NVIDIA Profile Inspector
      Go to: https://github.com/Orbmu2k/nvidiaProfileInspector
      Click "Releases" on the right side of the page, download the
      newest zip, and extract it.
      Extract it to: C:\Users\<you>\app\nvidiaprofileinspec\
      (so you end up with
       C:\Users\<you>\app\nvidiaprofileinspec\nvidiaProfileInspector.exe)
      This also has no installer, it's a single portable program.

  1d. MSI Center
      Check your Start Menu first -- MSI laptops usually come with
      this already installed. If it's missing, search "MSI Center"
      on MSI's official support site for your model and install it.

  1e. MSI Afterburner (OPTIONAL -- skip this if you just want the
      basic 3-mode toggle. This is only needed if you later want to
      also underclock the GPU core/memory speed in Work mode.)
      Go to: https://www.msi.com/Landing/afterburner/graphics-cards
      This one DOES have a normal installer, just run it and follow
      the prompts.

  DO NOT install "NirCmd" -- an earlier version of this project used
  it, but it's not needed anymore and an virustotal scan flagged it
  as suspicious. The current script doesn't use it at all.


------------------------------------------------------------
STEP 2 -- CREATE YOUR FOLDER
------------------------------------------------------------

Open File Explorer and create this folder if it doesn't already exist (can be named anything or put anywhere, but every file is configured on my own path, you can modify anything):

  C:\Users\<your username>\app\

This is where everything lives. By the end of this guide it should contain:

  C:\Users\<you>\app\
    CopilotThrottleStopToggle.ahk     (the script -- save it here)
    ThrottleStop.exe                  (from step 1b)
    (ThrottleStop's other files)
    ThrottleStop.ini                  (created automatically once you
                                        save settings inside ThrottleStop)
    nvidiaprofileinspec\
      nvidiaProfileInspector.exe      (from step 1c)
      global_profile_game.nip         (you will create this in step 4)
      global_profile_perf.nip         (you will create this in step 4)

Save the CopilotThrottleStopToggle.ahk file (provided separately)
directly into this app folder now.


------------------------------------------------------------
STEP 3 -- SET UP THROTTLESTOP PROFILES (from scratch)
------------------------------------------------------------

ThrottleStop lets you save up to 8 "profiles" -- basically saved CPU
setting presets you can jump between. We're using 3 of them.

  3a. Open ThrottleStop.exe. If Windows shows a "clock disabled"
      warning popup on first run, just click OK -- this is normal.

  3b. You'll see a main window with a row of numbered buttons near
      the bottom-left, usually labelled 1 through 8, plus a bunch of
      checkboxes (Disable Turbo, SpeedStep, C1E, etc.) and sliders.
      These numbered buttons are your profile slots.

  3c. SET UP PROFILE 1 = PERFORMANCE
      - Click the "1" button to select that slot.
      - Check the box labeled "Disable Turbo" (this stops the CPU
        boosting above base clock -- cooler, quieter).
      - Leave other boxes at their defaults for now.
      - Click "Save" (bottom right area of the window) so this
        profile sticks.
      - (optional) Set Speed Shift EPP to a middle value like 128
        ("balanced") instead of 0, so the CPU doesn't chase max clock
        even with Turbo already off.

  3d. SET UP PROFILE 2 = GAME
      - Click the "2" button.
      - Make sure "Disable Turbo" is UNCHECKED here (you want full
        boost while gaming).
      - Click "Save".

  3e. SET UP PROFILE 4 = WORK / BATTERY
      - Click the "4" button.
      - Check "Disable Turbo", "SpeedStep", and "C1E".
      - Also check "Power Saver" if you see it, and set Speed Shift
        EPP toward 255 -- this forces the CPU to its lowest gear,
        best for light tasks like browsing or office work.
      - Click "Save".

  3f. ASSIGN HOTKEYS TO EACH PROFILE
      - Go to the "Options" menu at the top, choose "Hotkeys".
      - You'll see rows for each profile number, each with a set of
        checkboxes (CTRL, ALT, SHIFT, WIN, NUMPAD) and a dropdown or
        box to pick a digit.
      - For Profile 1: tick CTRL, ALT, and NUMPAD, and set the digit
        to 2. This means "Ctrl+Alt+Numpad2" switches to Profile 1.
      - For Profile 2: tick CTRL, ALT, NUMPAD, digit = 1
        ("Ctrl+Alt+Numpad1").
      - For Profile 4: tick CTRL, ALT, NUMPAD, digit = 3
        ("Ctrl+Alt+Numpad3").
      - Make sure the "Enable Hotkeys" checkbox (usually near the top
        of this window) is ticked, or none of this will work.
      - Click OK / Save to close this window.

  IMPORTANT: Keep NumLock turned ON on your keyboard. The Numpad
  hotkeys can misbehave if NumLock is off.

  These three combinations (Ctrl+Alt+Numpad2, Numpad1, Numpad3) are
  exactly what the script will "press" automatically for you later --
  you don't need to remember them, just make sure they're set up
  exactly like this so the script's automatic key-presses land on the
  right profile.

  Once everything above is done and saved, ThrottleStop will have
  created a file called ThrottleStop.ini in the same folder as
  ThrottleStop.exe -- that file is what remembers all these settings.
  If you ever reinstall Windows again, you can just copy that one
  .ini file back into the folder instead of redoing steps 3a-3f.


  --- WHAT EACH SETTING ABOVE ACTUALLY DOES ---

  Quick disclaimer: I (the person who set this up) haven't dug into
  the CPU internals myself -- this is a summary of what these
  settings are commonly documented to do, gathered from ThrottleStop
  guides online. Treat it as "why this probably works", not gospel.

  Disable Turbo
    Stops the CPU from boosting above its base clock. Turbo is what
    lets a CPU spike way above its normal speed for short bursts --
    great for gaming, but it's also the main reason a laptop gets
    hot and loud. Turning it off caps you at base clock permanently.

  SpeedStep
    An older Intel mechanism (largely superseded by "Speed Shift" on
    newer CPUs) that lets Windows scale the CPU's clock speed up and
    down based on load, at the software level. Usually best left on
    -- disabling it can lock the CPU at a fixed frequency/voltage,
    which isn't necessarily lower, just less flexible.

  C1E
    Controls whether the CPU is allowed to drop into a deeper idle
    state when there's nothing to do. Leaving it ON generally means
    better idle efficiency and lower idle temps. Turning it OFF
    keeps clocks "ready" at all times at the cost of higher idle
    power draw -- mainly useful for latency-sensitive work, not
    something you'd usually want in a "quiet/cool" profile, but we
    use it here mainly to reinforce that Work mode should never
    randomly spike.

  Power Saver (checkbox, not the Windows power plan)
    Forces the CPU toward its lowest available multiplier/gear
    instead of letting it pick dynamically. This is the setting
    doing most of the heavy lifting for how low Work mode's clock
    speed goes.

  Speed Shift EPP (0-255 slider)
    A newer, hardware-level version of SpeedStep. 0 means "prefer
    maximum frequency" (closest to Turbo behaviour even with Turbo
    off), 255 means "prefer minimum frequency / most efficient".
    Low values (0-32) suit a Perf-but-still-responsive profile;
    high values (128-255) suit a low-power Work profile.


  --- WHAT I ACTUALLY MEASURED (my B12UC, your numbers may differ) ---

  These are real numbers off my own machine, watched live in
  ThrottleStop's monitoring panel, task manager and a bit of msi afterburener(no relevant data found) -- not manufacturer specs, and not
  independently verified beyond "this is what I saw happen":

  GAME (Turbo ON)
    Sat around 2.20 GHz with light load, but jumped up to 3.8 GHz 
    once more programs/load were active -- this is Turbo doing its (can go beyond 3.8 i think i Elden ring i got close to 4.2ghz)
    job, ramping up only when something actually demands it.

  PERF (Turbo OFF)
    Held steady around 1.5/1.1 GHz with just Brave open and nothing else
    heavy running.

  WORK (Turbo OFF + Power Saver)
    Dropped to about 1 GHz, sometimes as low as 0.60 GHz.

  These numbers are specific to my CPU, my BIOS and modified ssd ram ect,
  and what was running at the time -- yours will land somewhere in the same
  general shape (Game > Perf > Work) but don't expect identical
  figures. If you want to check your own, ThrottleStop's main window
  shows live clock speed per core while a profile is active and task manager.


------------------------------------------------------------
STEP 4 -- SET UP THE NVIDIA GPU PROFILES (from scratch)
------------------------------------------------------------

This controls whether your NVIDIA GPU stays "boosted" or idles down
to save power -- it's a legitimate NVIDIA driver setting, we're just
making it switchable with one click instead of digging through menus.

  4a. Open nvidiaProfileInspector.exe (from the nvidiaprofileinspec
      folder). You may need to right-click -> Run as administrator.

  4b. At the top, there's a dropdown for choosing which "profile" you
      are editing. Leave it on "Base Profile" (this is the global
      default that applies everywhere unless a game has its own
      override).

  4c. In the long list of settings below, find the section called
      "0x1 - Common", and inside it find "Power Management Mode".

  4d. CREATE THE GAME VERSION:
      - Set "Power Management Mode" to "Prefer Maximum Performance".
      - Click the small floppy-disk / save icon near the top
        (labeled something like "Apply changes") to save it into
        your NVIDIA driver.
      - Now go to File (or the top toolbar) and look for an option
        like "Export Customized Settings" -- or just close and reopen
        the program and use the -exportCustomized command explained
        below. The simplest way:
          - Close the program.
          - Open a Command Prompt (search "cmd" in the Start Menu).
          - Type: cd C:\Users\<you>\app\nvidiaprofileinspec
          - Press Enter.
          - Type: nvidiaProfileInspector.exe -exportCustomized
          - Press Enter. This creates a new file with a long
            timestamp-style name in that same folder. 
          - Find that new file in File Explorer, and rename it to:
            global_profile_game.nip

  4e. CREATE THE PERF/WORK VERSION:
      - Reopen nvidiaProfileInspector.exe.
      - Change "Power Management Mode" back to "Optimal Power".
      - Click the save/apply icon again.
      - Repeat the same export steps as above (close it, use the
        same -exportCustomized command in Command Prompt), and rename
        the newly created file to:
            global_profile_perf.nip

  You should now have both files sitting in:
    C:\Users\<you>\app\nvidiaprofileinspec\global_profile_game.nip
    C:\Users\<you>\app\nvidiaprofileinspec\global_profile_perf.nip

  These two small files are what the script silently "imports" every
  time you switch modes -- that's what actually flips the GPU setting
  without you having to open the program each time.


------------------------------------------------------------
STEP 5 -- EDIT THE SCRIPT'S PATHS
------------------------------------------------------------

Right-click CopilotThrottleStopToggle.ahk and choose "Edit Script"
(or open it with Notepad). Near the top you'll see a block that looks
like this:

  TS_PATH   := "C:\Users\place holder\app\ThrottleStop.exe"
  NVI_PATH  := "C:\Users\place holder\app\nvidiaprofileinspec\nvidiaProfileInspector.exe"
  NIP_GAME  := "C:\Users\place holder\app\nvidiaprofileinspec\global_profile_game.nip"
  NIP_PERF  := "C:\Users\place holder\app\nvidiaprofileinspec\global_profile_perf.nip"
  MSI_CENTER_PATH := "C:\Program Files\MSI Center\MSI Center.exe"

Change "place holder" to your own actual Windows username in all four lines
if it's different. To find your username: open File Explorer, your
personal folder under "This PC > Local Disk (C:) > Users" shows it.

For the MSI_CENTER_PATH line: find your MSI Center icon (Start Menu
or Desktop), right-click it, choose "Open file location", right-click
the .exe you land on, choose Properties, and copy the exact "Target"
path shown there into that line, keeping the quote marks.

Save the file when done (Ctrl + S), then close Notepad.


------------------------------------------------------------
STEP 6 -- MAKE THE SCRIPT RUN AUTOMATICALLY AND SILENTLY
------------------------------------------------------------

We want ThrottleStop and the script to both start automatically every
time you log into Windows, running with admin rights, without a
popup asking you to approve it each time. Windows' "Task Scheduler"
does this.

  6a. Open Task Scheduler (search for it in the Start Menu).

  6b. On the right-hand side, click "Create Task..." (NOT "Create
      Basic Task" -- that simpler wizard doesn't have the option we need).

  6c. FIRST TASK -- for ThrottleStop:
      - General tab: Name it "ThrottleStopAutoStart".
        Tick the box "Run with highest privileges".
      - Triggers tab: click New. Set "Begin the task" to "At log on".
        Choose "Specific user" and make sure it's your account.
        Click OK.
      - Actions tab: click New. In "Program/script", click Browse and
        select your ThrottleStop.exe. In "Start in (optional)", enter
        the folder it's in (e.g. C:\Users\<you>\app\). Click OK.
      - Conditions tab: UNTICK "Start the task only if the computer
        is on AC power" (important for a laptop).
      - Settings tab: tick "Allow task to be run on demand".
      - Click OK to save. Windows may ask for your account password
        once -- enter it, this lets the task run silently later.

  6d. SECOND TASK -- for the script:
      - Repeat the same steps, but name it "CopilotToggleAutoStart".
      - Actions tab -> New:
          Program/script: browse to
            C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
          Add arguments (optional): type exactly (with quotes):
            "C:\Users\<you>\app\CopilotThrottleStopToggle.ahk"
          Start in (optional):
            C:\Users\<you>\app\
      - Everything else (highest privileges, at log on, AC power
        unchecked) is the same as the first task.

  You now have two tasks that will silently start both programs,
  fully admin-elevated, every time you log in -- no clicking, no
  popups.


------------------------------------------------------------
STEP 7 -- TEST EVERYTHING
------------------------------------------------------------

You don't have to restart your PC to test -- do this instead:

  7a. In Task Scheduler, find "ThrottleStopAutoStart" in the list,
      right-click it, choose "Run".
  7b. Do the same for "CopilotToggleAutoStart".
  7c. Open Task Manager (Ctrl+Shift+Esc), go to the "Details" tab.
      Right-click any column header, choose "Select columns", and
      tick "Elevated". Find ThrottleStop.exe and AutoHotkey64.exe in
      the list -- both should now show "Yes" under Elevated.
  7d. Tap the Copilot key once. You should see a small popup appear
      in the top-right corner saying GAME MODE or PERF MODE, with no
      Windows security popup interrupting you.
  7e. Hold the Copilot key down for a full second (count "one
      one-thousand"). You should see the WORK MODE popup appear
      BEFORE the screen flickers to 60Hz, MSI Center should open on
      its own, and your speakers should go silent.
  7f. Tap the Copilot key again while in Work mode -- it should jump
      back to Game mode, unmute your sound, and restore the normal
      144Hz screen.

If all of that worked, you're done -- log off and back on once just
to confirm it still all starts up cleanly on its own.


------------------------------------------------------------
TROUBLESHOOTING
------------------------------------------------------------

- Popup shows but the profile doesn't actually change:
  Double check the ThrottleStop hotkeys in step 3f match exactly --
  wrong digit, missing NUMPAD tick, or NumLock being off are the
  most common causes.

- A Windows security prompt appears when switching modes:
  This means the script or ThrottleStop isn't running elevated.
  Redo step 6, especially "Run with highest privileges", and make
  sure you entered your password when prompted while saving the task.

- Nothing happens at all when pressing the Copilot key:
  Some MSI models have MSI Center itself grabbing that key. Open
  MSI Center's settings and look for anything bound to the Copilot
  key or "AI key", and disable it there.

- Screen doesn't actually change to 60Hz in Work mode:
  This can vary slightly by display driver. Not a sign anything else
  is broken -- everything else (CPU/GPU/mute/MSI Center) will still
  work correctly.


------------------------------------------------------------
NOTES FOR LATER
------------------------------------------------------------

- ts_profile_state.txt appears automatically next to the script once
  you use it for the first time -- it just remembers which mode you
  were last in, so the popup stays accurate even after a restart.
  Don't delete it.

- MSI Afterburner is not connected to the script yet. If you finish
  setting up a Profile 1 (+0 offset) and Profile 2 (negative offset,
  e.g. Core -300) inside Afterburner later, you can add GPU
  underclocking to Work mode by adding this one line inside the
  ApplyProfile() function in the script:

    Run('"C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe" -profile2',, "Hide")

- If MSI Center ever updates and moves its install location, just
  redo the path-finding part of step 5 for MSI_CENTER_PATH.

(keep in mind all of this is made by one person on their free time, made that for me but wanted to help other people with this laptop, if there is any problem with the project or something you want changed or updated tell me or you can try your self. it was really fun for me honestly)