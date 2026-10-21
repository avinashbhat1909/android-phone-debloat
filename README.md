# android-phone-debloat

<p align="center">
  <b>Strip OEM telemetry, eliminate standby battery drain, and turn modern Android phones into clean, fluid Pixel-like devices.</b><br>
  <sub>No root · No unlocked bootloader · Passes Google Play Integrity · 100% Reversible</sub>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Android-14%20%7C%2015%20%7C%2016-green.svg" alt="Android Versions">
  <img src="https://img.shields.io/badge/Play%20Integrity-Passing-brightgreen.svg" alt="SafetyNet / Play Integrity">
  <img src="https://img.shields.io/badge/Banking%20Apps-100%25%20Working-success.svg" alt="Banking Apps">
</p>

<p align="center">
  <a href="PROMPT.md"><b>The Prompt</b></a> ·
  <a href="#supported-devices"><b>Tested Devices</b></a> ·
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
| **vivo X200 Series** (`V2561` / `PD2458F_EX`) | MediaTek Dimensity 9400 3nm | Android 16 / OriginOS 16 | Gallery AI Tamer & Audit | [View Profile](devices/vivo-x200/) |

*Have a different device? Check out [CONTRIBUTING.md](CONTRIBUTING.md) to add your model!*

---

## Quick Start Guide

### Prerequisites
1. **Android Debug Bridge (`adb`):**
   * Download the official Google Platform-Tools directly:
     * [Windows ZIP](https://dl.google.com/android/repository/platform-tools-latest-windows.zip)
     * [macOS ZIP](https://dl.google.com/android/repository/platform-tools-latest-darwin.zip)
     * [Linux ZIP](https://dl.google.com/android/repository/platform-tools-latest-linux.zip)
   * Or install via package manager:
     * Windows: `winget install Google.PlatformTools`
     * macOS: `brew install android-platform-tools`
     * Linux: `sudo apt install adb`
2. **Enable Developer Options on your phone:**
   - Tap **Build Number** 7 times in *Settings > About Phone*.
   - In *Developer Options*, enable:
     - **USB Debugging**
     - **Install via USB** (Xiaomi / POCO: enable in Developer Options)
     - **USB Debugging (Security settings)** (Xiaomi / POCO: allows permission automation)
3. Connect your phone via USB and tap **Always allow from this computer** when prompted.

---

### 1. Run Live Diagnostics
Check your device's current battery status and see which apps are holding the CPU awake right now:
```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-diag.ps1
```

### 2. Apply Debloat for Your Device
Run `tools\phone-disable.ps1` pointing to your device's `debloat.txt`:

```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-disable.ps1 devices\xiaomi-mi-11x-pro\debloat.txt
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
