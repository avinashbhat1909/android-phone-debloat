# Tested Phone Profiles

One folder per phone model, each containing a `debloat.txt` listing the safe-to-disable packages for that specific firmware, verified on real hardware.

| Folder | Device Model | Platform / SoC | OS / Skin | Packages | Key Notes & Verified Results |
| :--- | :--- | :--- | :--- | :---: | :--- |
| [`xiaomi-mi-11x-pro/`](xiaomi-mi-11x-pro/) | Xiaomi Mi 11X Pro (`haydn_in`, `M2012K11I`) | Qualcomm Snapdragon 888 5G | Android 14 / Xiaomi HyperOS 1.0 (V816) | **35 packages** | Active wake locks dropped from 4 to 0; standby CPU drain dropped >55%; stock launcher dormant for Recent Apps switcher; Themes AppOps lockdown. |
| [`vivo-x200/`](vivo-x200/) | vivo X200 / X200s (`V2561`, `PD2458F_EX`) | MediaTek Dimensity 9400 3nm | Android 16 / OriginOS 16 & FuntouchOS 16 | **Gallery AI + Apps** | Tamed runaway gallery AI indexing (~127% CPU drain); eliminated ghost `User 999` clone space polling; lockscreen poster sync stopped. |

---

## How to Apply Any Device Profile

Connect your phone with USB Debugging enabled, open PowerShell in the repository root, and run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-disable.ps1 devices\<folder-name>\debloat.txt
```

*Example:*
```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-disable.ps1 devices\xiaomi-mi-11x-pro\debloat.txt
```

---

## How to Restore

```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-restore.ps1 devices\<folder-name>\debloat.txt
```

*Example:*
```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-restore.ps1 devices\xiaomi-mi-11x-pro\debloat.txt
```

---

## Contributing a New Device
See [CONTRIBUTING.md](../CONTRIBUTING.md) to add a profile for your device.
