# The Prompt

Paste the prompt below into **Claude Code**, **Antigravity**, **Cursor**, or any coding assistant with shell access on a computer connected to your Android phone via USB.

Works on **Xiaomi / POCO / Redmi** (HyperOS / MIUI), **vivo / iQOO** (OriginOS / FuntouchOS), **Samsung** (One UI), **OnePlus / OPPO / Realme** (OxygenOS / ColorOS), **Motorola**, **Nothing OS**, and more.

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
Work step-by-step on the real connected device via ADB. Do NOT unlock the bootloader, do NOT root, and ensure Google Play Integrity, banking apps, and camera pipelines remain 100% functional. All changes must be fully reversible.

### 1. Connection & Live Baseline Diagnostics
- Verify device connection with `adb get-state` and inspect model (`ro.product.model`), SoC platform, and Android / OS build version.
- Check if ADB is in PATH or present in `tools/platform-tools/adb`. If missing, notify me to install it via winget/brew or provide the direct Google download link.
- Capture a live baseline power dump before touching anything:
  - `dumpsys battery` (temperature, health, level)
  - `dumpsys power` (check active wake locks preventing deep sleep)
  - `dumpsys cpuinfo` (find runaway background services)
  - `pm list users` (detect phantom second space or app clone containers like User 10 or User 999)

### 2. Backup First
- Create a backup directory and dump:
  - Full installed packages: `pm list packages -f`
  - Current disabled packages: `pm list packages -d`
  - System settings: `settings list system`, `settings list global`
- Prepare a `restore.ps1` (or `restore.sh`) script immediately that can re-enable every package modified.

### 3. Safe Debloat & Optimization Rules
- Categorize candidate packages into:
  1. OEM Telemetry & Diagnostics (background loggers, analytics, catchlog)
  2. Ad Delivery Engines & Feed Scrapers (lock screen wallpaper carousel / Glance, promo feed cards)
  3. Preloaded Partner Bloat (Facebook daemons, third-party shopping/games)
  4. Redundant Duplicate Apps (OEM messaging, calendar, or browser when Google / Brave is installed)
- Package Removal Method:
  - Use `pm uninstall -k --user 0 <pkg>` (or `pm disable-user --user 0` where supported).
  - CRITICAL SAFETY: NEVER touch or disable:
    - `com.android.systemui`
    - `com.android.settings`
    - Core telephony / dialer / emergency call providers
    - Core OEM security infrastructure that hosts lockscreen security or fingerprint auth
- Device-Specific Guardrails:
  - Xiaomi / HyperOS: Preserve `com.miui.home` in a dormant state if the user wants native Recent Apps multitasking gestures. Use AppOps (`RUN_IN_BACKGROUND: ignore`, `WAKE_LOCK: ignore`) to freeze background drain on retained system apps (like Themes).
  - vivo / OriginOS: Tame runaway background media indexing in `com.vivo.gallery` via AppOps and terminate ghost clone containers (`User 999`) if unused.
  - Samsung / One UI: Preserve Samsung Knox and biometric unlock services.

### 4. Optional Enhancements
- Clean AOSP Launcher: To complete the "Clean Pixel" makeover, recommend installing [Lawnchair 14](https://github.com/LawnchairLauncher/lawnchair/releases) (open-source AOSP Launcher3 base). Guide the user to set it as default while keeping the OEM stock launcher dormant so the native Recent Apps multitasking switcher is preserved.
- System-Wide Tracker Sinkhole: Offer configuring Private DNS to `dns.adguard-dns.com` (`settings put global private_dns_specifier dns.adguard-dns.com` and `settings put global private_dns_mode hostname`) for 0% battery penalty socket-level ad/tracker blocking.

### 5. Verification & Deliverables (Reports & Personal Setup Guide)
- Re-run `dumpsys power` to confirm:
  - `Wake Locks: size=0` (or minimal active wake locks)
  - Device drops cleanly into deep sleep (`mWakefulness=Asleep`)
- Automatically generate the following files locally on the user's machine (defined in `docs/` templates and kept local via `.gitignore`):
  1. `MY_PHONE_SETUP.md`: Personal quick-reference cheat sheet for the user following `docs/SETUP_TEMPLATE.md` (active launcher, private DNS address, quick PowerShell commands to check live battery stats, re-apply debloat after updates, and restore apps).
  2. `REPORT.md`: Comprehensive technical benchmark report following `docs/REPORT_TEMPLATE.md` with before/after diagnostic tables (active wake locks, CPU churn mAh, memory savings, safety audit).
  3. `debloat.txt`: Clean, reusable debloat package list with header specs, quirks, and load-bearing protections to commit to `devices/<model>/debloat.txt` when contributing back.
```

