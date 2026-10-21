# The Prompt

Paste the prompt below into **Claude Code**, **Antigravity**, **Cursor**, or any coding assistant with shell access on a computer connected to your Android phone via USB.

Supports **Android 9 (Pie) through Android 16+** across **Xiaomi / POCO / Redmi** (HyperOS / MIUI), **vivo / iQOO** (OriginOS / FuntouchOS), **Samsung** (One UI), **OnePlus / OPPO / Realme** (OxygenOS / ColorOS), **Motorola**, **Nothing OS**, and more. Ideal for revitalizing older devices by freeing physical RAM and eliminating background storage I/O.

---

## Prerequisites: Official ADB Tools

Before running the prompt, ensure Android Debug Bridge (`adb`) is installed or downloaded from Google's official source:

* **Official Google Platform-Tools (Direct Downloads):**
  * [Windows ZIP](https://dl.google.com/android/repository/platform-tools-latest-windows.zip)
  * [macOS ZIP](https://dl.google.com/android/repository/platform-tools-latest-darwin.zip)
  * [Linux ZIP](https://dl.google.com/android/repository/platform-tools-latest-linux.zip)
* **Or via Package Manager:**
  * Windows: `winget install Google.PlatformTools`
  * macOS: `brew install android-platform-tools`
  * Linux: `sudo apt install adb`

---

## On the Phone (Enable USB Debugging)

1. Go to **Settings → About Phone** and tap **Build Number** 7 times until you see *"You are now a developer!"*.
2. Open **Developer Options** and enable:
   * **USB Debugging**
   * **Install via USB** *(Xiaomi / POCO / Redmi)*
   * **USB Debugging (Security settings)** *(Xiaomi / POCO / Redmi)*
3. Plug the phone into your PC via USB and tap **"Always allow from this computer"** when prompted.

---

## Copy & Paste This Prompt into Your AI Assistant

```markdown
I want to eliminate standby battery drain, strip OEM telemetry/ads, and optimize my Android smartphone to feel like a clean, lightweight Pixel/AOSP device.
My phone model is: <MODEL NAME / BRAND HERE>.
Work step-by-step on the real connected device via ADB. Supports Android 9 (API 28) through Android 16+. Do NOT unlock the bootloader, do NOT root, and ensure Google Play Integrity, banking apps, and camera pipelines remain 100% functional. All changes must be fully reversible.

### 1. Connection & Live Baseline Diagnostics
- Run `tools/detect-device.ps1` to automatically inspect connected model (`ro.product.model`), SoC platform, Android / OS build version, battery health, and match against verified profiles in `devices/`.
- Check if ADB is in PATH or present in `tools/platform-tools/adb`. If missing, notify user to install it via winget/brew or provide the direct Google download link.
- Capture a live baseline power dump before touching anything:
  - `dumpsys battery` (temperature, health, level)
  - `dumpsys power` (check active wake locks preventing deep sleep)
  - `dumpsys cpuinfo` (find runaway background services or CPU thrashers)
  - `pm list users` (detect phantom second space or app clone containers like User 10 or User 999)

### 2. Backup First (Pre-Flight Snapshot)
- Run `tools/backup-packages.ps1` to capture a complete device snapshot:
  - Full installed packages with APK filesystem paths: `pm list packages -f -u`
  - Current disabled packages: `pm list packages -d`
  - Active multi-user profile states: `pm list users`
  - Auto-generated 1-click restore script: `backup/<model>_<timestamp>/restore-snapshot.ps1`
- Prepare or verify a device-specific `restore.ps1` script immediately that can re-enable every package modified.

### 3. Safe Debloat & Optimization Rules
- Preview First: Run a dry-run preview (`tools/detect-device.ps1 -DryRun` or `tools/phone-disable.ps1 <list> -DryRun`) so the user can inspect which packages are currently active vs already clean before modifying the phone.
- Categorize candidate packages into:
  1. OEM Telemetry & Diagnostics (background loggers, analytics, survey agents)
  2. Ad Delivery Engines & Feed Scrapers (lock screen wallpaper carousel / Glance, promo feed cards)
  3. Preloaded Partner Bloat (Facebook daemons, third-party shopping/games)
  4. Redundant Duplicate Apps (OEM messaging, calendar, or browser when Google / Brave is installed)
- Package Removal & Lockdown Methods:
  - Clean Uninstalls: Use `pm uninstall -k --user 0 <pkg>` for User 0 removal.
  - Package Manager Disabling: Use `pm disable-user --user 0 <pkg>` for system services that reject uninstall (e.g. `com.vivo.magazine`).
  - AppOps Neutering: For ROM-protected packages where the OEM blocks uninstall/disable with security exceptions (e.g. Xiaomi Themes, vivo V-Appstore, Global Search, HiBoard), use AppOps to freeze them permanently in deep sleep:
    `cmd appops set <pkg> RUN_IN_BACKGROUND ignore`
    `cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore`
    `cmd appops set <pkg> WAKE_LOCK ignore`
    `cmd appops set <pkg> SYSTEM_ALERT_WINDOW ignore`
  - CRITICAL SAFETY: NEVER touch or disable:
    - `com.android.systemui`
    - `com.android.settings`
    - Core telephony / dialer / emergency call providers
    - Core OEM security infrastructure that hosts lockscreen security or fingerprint auth
- Device-Specific Guardrails:
  - Xiaomi / HyperOS: Preserve `com.miui.home` in a dormant state if the user wants native Recent Apps multitasking gestures. Use AppOps to freeze background drain on Themes (`com.android.thememanager`).
  - vivo / OriginOS & FuntouchOS: Disable Lockscreen Poster (`com.vivo.magazine`), neuter V-Appstore and Global Search via AppOps, check charging AI gallery indexing behavior, and terminate ghost clone containers (`User 999`) if unused.
  - Samsung / One UI: Preserve Samsung Knox and biometric unlock services.

### 4. Optional Enhancements
- Clean AOSP Launcher: To complete the "Clean Pixel" makeover, recommend installing [Lawnchair 14](https://github.com/LawnchairLauncher/lawnchair/releases) (open-source AOSP Launcher3 base). Guide the user to set it as default while keeping the OEM stock launcher dormant so the native Recent Apps multitasking switcher is preserved.
- System-Wide Tracker Sinkhole: Offer configuring Private DNS to AdGuard (`tools/set-dns.ps1 -Provider AdGuard`) or Cloudflare (`tools/set-dns.ps1 -Provider Cloudflare`) for 0% battery penalty socket-level ad/tracker blocking (native on Android 9+).

### 5. Verification & Deliverables (Reports & Personal Setup Guide)
- Re-run `dumpsys power` to confirm:
  - `Wake Locks: size=0` (or minimal active wake locks)
  - Device drops cleanly into deep sleep (`mWakefulness=Asleep`)
- Automatically generate the following files locally on the user's machine (defined in `docs/` templates and kept local via `.gitignore`):
  1. `MY_PHONE_SETUP.md`: Personal quick-reference cheat sheet for the user following `docs/SETUP_TEMPLATE.md` (active launcher, private DNS address, quick PowerShell commands to check live battery stats, re-apply debloat after updates, and restore apps).
  2. `REPORT.md`: Comprehensive technical benchmark report following `docs/REPORT_TEMPLATE.md` with before/after diagnostic tables (active wake locks, CPU churn mAh, memory savings, safety audit).
  3. `debloat.txt`: Clean, reusable debloat package list with header specs, quirks, and load-bearing protections to commit to `devices/<model>/debloat.txt` when contributing back.
```

