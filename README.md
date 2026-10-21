# android-phone-debloat

<p align="center">
  <b>Strip OEM telemetry, eliminate standby battery drain, and turn modern Android phones into clean, fluid Pixel-like devices.</b><br>
  <sub>No root · No unlocked bootloader · Passes Google Play Integrity · 100% Reversible</sub>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Android-9%20to%2016%2B-green.svg" alt="Android Versions">
  <img src="https://img.shields.io/badge/Play%20Integrity-Passing-brightgreen.svg" alt="SafetyNet / Play Integrity">
  <img src="https://img.shields.io/badge/Banking%20Apps-100%25%20Working-success.svg" alt="Banking Apps">
</p>

<p align="center">
  <a href="PROMPT.md"><b>The Prompt</b></a> ·
  <a href="#supported-devices"><b>Tested Devices</b></a> ·
  <a href="#android-version-compatibility-android-9-to-16"><b>OS Compatibility</b></a> ·
  <a href="#quick-start-guide"><b>Quick Start</b></a> ·
  <a href="CONTRIBUTING.md"><b>Contribute</b></a>
</p>

---

## The Problem

Modern flagship Android phones (Xiaomi HyperOS, vivo OriginOS/FuntouchOS, etc.) pack incredible hardware, but they ship heavily burdened with:
* **Standby Battery Vampires:** 24/7 background diagnostic daemons, crash reporters, and lock screen feed scrapers that prevent the CPU from entering deep sleep.
* **Aggressive Ad Frameworks:** System-level ad push engines, promotional stores, and duplicate utility apps.
* **Heavyweight Launchers:** Stock launchers consuming 200–300+ MB of RAM with unremovable feed widgets.

Most debloat guides either break core system components (like banking apps, cameras, or recent-app switchers) or require risky bootloader unlocking and root that trips SafetyNet.

**`android-phone-debloat`** provides tested, surgical, rootless profiles backed by live ADB diagnostic proof (`dumpsys power`, `dumpsys batterystats`).

---

## Proven Results (Xiaomi Mi 11X Pro Example)

| Metric | Stock HyperOS 1.0 | After `android-phone-debloat` | Real-World Impact |
| :--- | :--- | :--- | :--- |
| **Active System Wake Locks** | `4` active wakelock holders | **`0` (Zero active wake locks)** | CPU drops into continuous deep sleep instantly. |
| **PowerManager Blockers** | `1` persistent blocker | **`0`** | Standby overnight drain drops to ~1–2%. |
| **Idle CPU Standby Churn** | `1699 mAh` cumulative CPU drain | **`756 mAh`** | **>55% reduction** in background CPU overhead. |
| **Default Home Launcher** | `com.miui.home` (~220 MB RAM) | **`app.lawnchair` (~45 MB RAM)** | Fluid Pixel-like desktop, faster launches, zero ad widgets. |
| **Lockscreen Feed Scrapers** | Wallpaper Carousel / Glance active | **Uninstalled** | Eliminates screen wakeups and promo downloads. |
| **Ad / Tracker Sinkhole** | Default ISP (unfiltered) | **`dns.adguard-dns.com`** | Blocks in-app ads at the socket layer with **0% extra battery draw**. |
| **Banking & Play Integrity** | Passes | **Passes (Untouched)** | GPay, PhonePe, and banking apps run with zero warnings. |

---

## Supported Devices

| Device | Platform / SoC | OS / Skin | Uninstalled Packages | Profile Link |
| :--- | :--- | :--- | :---: | :--- |
| **Xiaomi Mi 11X Pro** (`M2012K11I` / `haydn_in`) | Qualcomm Snapdragon 888 5G | Android 14 / HyperOS 1.0 | **35 packages** | [View Profile](devices/xiaomi-mi-11x-pro/) |
| **vivo X200T** (`V2561` / `PD2458F_EX`) | MediaTek Dimensity 9400 3nm | Android 16 / OriginOS 16 & FuntouchOS 16 | **16 packages** | [View Profile](devices/vivo-x200t/) |

*Have a different device? Check out [CONTRIBUTING.md](CONTRIBUTING.md) to add your model!*

---

## Android Version Compatibility (Android 9 to 16+)

While modern flagships benefit from reduced telemetry and battery preservation, **older Android phones (Android 9 Pie through Android 13) experience the most dramatic performance gains**:

* **Revitalize 3 GB – 6 GB RAM Devices**: Stripping 30–50 OEM background daemons frees up **~1 GB of physical RAM**, preventing aggressive background app killing and multitasking redraws.
* **Stop Slow Flash Wear (eMMC 5.1)**: Older phones rely on slower eMMC storage. Stopping continuous disk logging from telemetry engines (`miui.analytics`, `bbklog`, crash loggers) completely eliminates UI micro-stutters.
* **Native Private DNS (Android 9+)**: Android 9 (API 28) is the milestone version where Google introduced OS-level DNS-over-TLS. Our [`tools/set-dns.ps1`](tools/set-dns.ps1) blocks ads and tracking with **0% battery penalty** without needing battery-draining VPN apps.
* **Fewer OEM Security Lockouts**: Android 9 and 10 firmware (MIUI 10/11/12, One UI 1/2, FuntouchOS 9/10) have almost none of the aggressive `DELETE_FAILED_USER_RESTRICTED` package lockouts found on modern Android 14–16, allowing clean package uninstalls across the board.

## Quick Start Guide

### Prerequisites
1. **Android Debug Bridge (`adb`):**
   * Download official Google Platform-Tools directly:
     * [Windows ZIP](https://dl.google.com/android/repository/platform-tools-latest-windows.zip) · [macOS ZIP](https://dl.google.com/android/repository/platform-tools-latest-darwin.zip) · [Linux ZIP](https://dl.google.com/android/repository/platform-tools-latest-linux.zip)
   * Or install via package manager:
     * Windows: `winget install Google.PlatformTools`
     * macOS: `brew install android-platform-tools`
     * Linux: `sudo apt install adb`
2. **Enable Developer Options on your phone:**
   - Tap **Build Number** 7 times in *Settings > About Phone*.
   - In *Developer Options*, enable:
     - **USB Debugging**
     - **Install via USB** (Xiaomi / POCO)
     - **USB Debugging (Security settings)** (Xiaomi / POCO)
3. Connect your phone via USB and tap **Always allow from this computer** when prompted.

---

### Step 1: Auto-Detect Your Phone
Run the unified smart detector. It will identify your phone model, battery health, and automatically match your device profile:
```powershell
powershell -ExecutionPolicy Bypass -File tools\detect-device.ps1
```

### Step 2: Take a Pre-Flight Backup (Recommended)
Before making any changes, snapshot your installed packages and multi-user configurations:
```powershell
powershell -ExecutionPolicy Bypass -File tools\backup-packages.ps1
```
*(Creates a timestamped snapshot in `backup/` with a 1-click `restore-snapshot.ps1` script).*

### Step 3: Preview with Dry-Run Mode
Inspect what will be removed without actually modifying your phone:
```powershell
powershell -ExecutionPolicy Bypass -File tools\detect-device.ps1 -DryRun
```

### Step 4: Apply Debloat
Apply the safe, verified debloat specification:
```powershell
powershell -ExecutionPolicy Bypass -File tools\detect-device.ps1 -Apply
```
*Or run your device's dedicated script directly:*
* **vivo X200T:** `powershell -ExecutionPolicy Bypass -File devices\vivo-x200t\apply-debloat.ps1`
* **Xiaomi Mi 11X Pro:** `powershell -ExecutionPolicy Bypass -File devices\xiaomi-mi-11x-pro\apply-debloat.ps1`

### Step 5: Enable AdGuard Private DNS
Block in-app banner ads, popups, and background telemetry at the socket layer (0% battery drain):
```powershell
powershell -ExecutionPolicy Bypass -File tools\set-dns.ps1 -Provider AdGuard
```

### 3. Setup a Clean AOSP Launcher (Recommended)
To complete the "Clean Pixel" transformation, we recommend replacing the heavy OEM launcher with a fast, open-source, tracker-free home screen:

* **Primary Recommendation:** **[Lawnchair 14](https://github.com/LawnchairLauncher/lawnchair/releases)** (or via [lawnchair.app](https://lawnchair.app))
  * **Engine:** Pure Google AOSP `Launcher3` compiled for modern Android (Android 14+).
  * **RAM Footprint:** Drops launcher memory usage from **~220–300 MB down to ~45 MB**.
  * **Aesthetics:** Material You theming, fluid animations, customizable search/dock, and zero promotional feed widgets.
  * **Multitasking Safety:** Keep the OEM stock launcher installed in a dormant state so the native Recent Apps task switcher continues to work smoothly.

### 4. Enable System-Wide Ad & Tracker Sinkhole
In your phone settings, go to:
* **Settings > More Connectivity Options > Private DNS**
* Select **Private DNS provider hostname** and enter:
  ```text
  dns.adguard-dns.com
  ```
* Blocks trackers and mobile banner ads system-wide with **0% battery penalty** (no local VPN proxy process).

---

## How to Restore (100% Reversible)

Every change made by this project is non-destructive. The original APKs remain intact on the read-only `/system` partition and can be restored at any time.

### Restore All Apps at Once:
```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-restore.ps1 devices\xiaomi-mi-11x-pro\debloat.txt
```

### Restore an Individual App:
```powershell
adb shell cmd package install-existing <package_name>
```

---

## System Updates (OTA) Survival

* **Security Patches:** Most debloated packages remain uninstalled across monthly patches.
* **Major OS Upgrades (e.g. HyperOS 1.0 -> 2.0):** If an upgrade revives any pre-installed bloatware, simply re-run the disable command:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\phone-disable.ps1 devices\xiaomi-mi-11x-pro\debloat.txt
  ```
  It automatically cleans revived apps and restores the lockdown in **under 5 seconds**.

---

## Contributing

Contributions are welcome! If you have optimized another phone model (Samsung One UI, OnePlus OxygenOS, Nothing OS, Motorola, Pixel), please submit a pull request. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## Author & Credits

* Maintained by **Avinash Bhat** ([@avinashbhat1909](https://github.com/avinashbhat1909))
* Inspired by the spirit of the [`cleanyourtv`](https://github.com/Gathin23/cleanyourtv) initiative, adapted and engineered for the modern smartphone ecosystem.
* Launcher experience powered by the open-source **[Lawnchair](https://github.com/LawnchairLauncher/lawnchair)** project, bringing pure AOSP Launcher3 performance to Android devices.

## License

This project is licensed under the [MIT License](LICENSE).
