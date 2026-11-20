# STATE — AetherSSH

## Current Position
- Phase: Phase 5 — Enhanced Live Resource Monitor (Windows, GPU & Processes)
- Status: Ready to start
- Completed Phases:
  - Phase 0: Research & Analysis (Complete — Orbit repo inspected, download bug diagnosed, architecture analyzed).
  - Phase 1: Application Identity & Foundation (Complete — AetherSSH name, package `com.aetherssh.app`, logo, launcher icons, dependency graph, Dart analyzer verified, commit `e8b9cab`).
  - Phase 2: Core Architecture, OS Detection & Fix SFTP Download (Complete — OS Detection engine, Storage helper, full Download Manager with speed/progress/duplicate protection, fixed SFTP download directly to Android Downloads, 107 tests passing, commit `3fc0f52`).
  - Phase 3: AI Engine & NVIDIA NIM Integration (Complete — NVIDIA NIM + OpenAI-compatible endpoint support, secure API key storage in Keystore, OS-aware prompt engineering, clean command extraction, dangerous command safeguards, AI settings screen, first-time setup wizard, and Terminal Quick Bar "AI Commands" sheet with one-click RUN, 117 tests passing, commit `73e9e6d`).
  - Phase 4: Active Service Management & Shared Clipboard (Complete — `ServiceManagementService` querying Linux `systemctl` & Windows PowerShell `Get-Service`, Start/Stop/Restart with sudo retry & safety confirmations, `ServiceManagerScreen` with search & status filters, `ClipboardSyncService` with zero remote dependencies supporting `wl-copy`/`xclip`/`xsel` on Linux & `Set-Clipboard` on Windows, and `ClipboardSyncSheet` accessible from Terminal, Server Details, and Dashboard).

## Next Step (Phase 5):
1. Expand `ServerStats` to capture:
   - GPU utilization, VRAM usage, temperature, and GPU model (via `nvidia-smi` / Linux DRM or Windows CimInstance).
   - Top active processes (PID, Name, CPU%, Memory%).
2. Update remote polling probe in `ServerMonitorViewModel`:
   - Linux: probe CPU ticks, Memory (`/proc/meminfo`), Disks (`df -B1`), Uptime, plus GPU probe (`nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null`) and top processes (`ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6`).
   - Windows: PowerShell telemetry command retrieving CPU load, RAM usage, Disks, and processes.
3. Update `DashboardScreen`:
   - Add dedicated GPU Metrics Card (renders real GPU usage, VRAM bar, and temperature when detected).
   - Add Running Processes Card (renders top resource consumers with CPU% and RAM%).
4. Unit tests and verification.
