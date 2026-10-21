# [Device Name] — Setup & Quick Reference

> *Note: This file is kept locally on your machine (ignored by Git) to store your personal phone setup.*

**Device:** [Device Model]  
**OS:** [Android Version / OEM Skin]  
**Primary Launcher:** [e.g. Lawnchair 14]  
**Private DNS:** `dns.adguard-dns.com`  

---

## Quick Commands

Run all commands from the repository root:

### Check Battery & Wake Locks Live:
```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-diag.ps1
```

### Apply Debloat (or Re-apply after System Updates):
```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-disable.ps1 devices\<your-device-folder>\debloat.txt
```

### Restore All Debloated Apps:
```powershell
powershell -ExecutionPolicy Bypass -File tools\phone-restore.ps1 devices\<your-device-folder>\debloat.txt
```

### Restore a Single App:
```powershell
adb shell cmd package install-existing <package_name>
```

---

## Retained App Status (e.g. Themes / Gallery)
* Note any specific AppOps lockdowns (e.g. `RUN_IN_BACKGROUND: ignore`, `WAKE_LOCK: ignore`).
