# Contributing to android-phone-debloat

Thank you for contributing! Our goal is to make modern Android smartphones feel like clean, lightweight Pixel/AOSP devices—eliminating standby battery drain, thermal throttling, and telemetry without breaking banking apps, cameras, or requiring root.

---

## Contribution Guidelines

### Adding a New Device Profile
Create a new directory under `devices/<brand>-<model>/` (e.g. `devices/samsung-galaxy-s24`, `devices/oneplus-12`):

Each device directory should contain:
1. **`debloat.txt`** (or `applied_debloat.txt`):
   - Package names with comments explaining what each package does.
   - Categorized by purpose (Telemetry, Ad engines, Duplicate apps, Media bloat, Lockscreen scrapers).
2. **`REPORT.md`**:
   - Device hardware specifications (SoC, RAM, battery size, Android & OS version).
   - Before vs. After diagnostics (active wake locks, battery drain, memory usage).
3. **`apply-debloat.ps1`**:
   - 1-click script that reads the package list and runs `pm uninstall -k --user 0 <pkg>`.
4. **`restore.ps1`**:
   - 1-click script that re-enables all uninstalled packages via `cmd package install-existing <pkg>`.

---

## Critical Safety Rules

1. **Zero-Brick Guarantee:**
   - Never disable or remove critical system infrastructure:
     - `com.android.systemui`
     - `com.android.settings`
     - Telephony providers / SIM services
     - Essential OEM security cores that manage the lock screen
2. **Banking & Integrity Preservation:**
   - All debloating must be 100% rootless via standard ADB (`--user 0`).
   - Do NOT require unlocked bootloader or system partition modifications.
3. **100% Reversible:**
   - Every change must have an exact, tested restore command.

---

## Submitting Pull Requests

1. Fork this repository.
2. Create a feature branch: `git checkout -b feat/add-<device-model>`.
3. Commit your changes with clear descriptions.
4. Open a Pull Request referencing the device specifications and before/after verification logs.
