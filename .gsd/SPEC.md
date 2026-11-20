# SPECIFICATION — AetherSSH (Next-Gen Orbit-Inspired SSH Management Application)

Status: FINALIZED
Date: 2026-11-20

## 1. Project Overview & Identity
- **Application Name**: AetherSSH
- **Package Identifier**: `com.aetherssh.app`
- **Branding**: Modern, clean, dark-themed cybernetic identity with custom Aether logo and launcher icons.
- **Base Foundation**: Built upon the architecture of Orbit, preserving all existing screens, layouts, and UX patterns while fixing critical bugs and introducing major new capabilities.

## 2. Platform & OS Support
- **Target OS**: Android (minSdk 24, targetSdk 34+)
- **Remote Host Environments**:
  - Linux (Ubuntu, Debian, Linux Mint, Fedora, CentOS, Arch, openSUSE, etc.)
  - Windows (Windows 10, Windows 11, Windows Server with OpenSSH Server & PowerShell/CMD)
- **Automatic OS Detection**:
  - Automatically identifies remote OS (Linux distro vs Windows edition, kernel/version, shell).
  - Shows corresponding OS logos (Ubuntu, Debian, Fedora, Mint, Linux, Windows) in the server list and detail cards.

## 3. SSH Connection Management
- Saved server configurations with Hive (metadata) + Android Keystore backed `FlutterSecureStorage` (passwords/private keys).
- Connection status tracking, timeout handling, and reconnect.
- Password and private key (with passphrase support) authentication.

## 4. SFTP File Manager & Bug Fix
- **Root Cause of Original Download Bug**: `FilePicker.getDirectoryPath()` returns SAF Document Tree URI or non-writable paths on Android 10+ (API 29+), causing raw POSIX `File.openWrite()` to fail with permission denied.
- **Solution & Architecture**:
  - Provide direct streaming to standard Android Downloads directory (`/storage/emulated/0/Download` or `path_provider.getDownloadsDirectory()`), with fallback to app documents/cache and custom folder picker.
  - Implement full-featured **Download Manager**:
    - Progress callback streaming from SFTP without buffering entire files in memory.
    - Speed calculation (KB/s, MB/s), transferred vs total bytes.
    - Active, Completed, Failed states.
    - Duplicate filename handling (`file (1).ext` or prompt).
    - File integrity check.
    - Cancellation and retry support.
    - User notification & accessibility directly from Android Files app.
  - Preserve working upload streaming mechanism intact.

## 5. AI-Powered Terminal
- **AI Commands Button**: Placed in the terminal keyboard toolbar / quick keys bar immediately above the soft keyboard.
- **Input Flow**: User enters natural language request (e.g. "turn off pc", "restart docker", "check disk space").
- **Strict Command-Only Output**: AI responds with the exact executable command ONLY (no Markdown code fences, no conversational prose, no instructions).
- **OS-Aware Command Generation**:
  - Target Linux: Generates bash/sh commands (`systemctl`, `free -h`, `ip a`, etc.).
  - Target Windows: Generates PowerShell commands (`Get-Service`, `Stop-Computer`, `Get-Process`, etc.).
- **Run Card & Safety**:
  - Command preview card with "RUN" button.
  - Dangerous commands (shutdown, reboot, rm -rf, mkfs, format, process kill) require explicit confirmation dialog.
  - When confirmed, pastes into active terminal session and executes, displaying output in real time.

## 6. AI Providers & NVIDIA NIM Integration
- **Default Provider**: NVIDIA NIM (`https://integrate.api.nvidia.com/v1`).
- **Custom Provider**: Any OpenAI-compatible endpoint (URL, API Key, Model).
- **First-Time Setup**: Prompt dialog when user first opens AI Commands if unconfigured.
- **AI Settings**: Provider selection, API Key (masked), Model name, Endpoint, Test Connection button, Delete credentials.
- **Security**: Keystore-backed secure storage, zero hardcoded keys.

## 7. Active Service Management
- Dedicated service viewer screen for connected servers.
- **Linux**: Parses `systemctl list-units --type=service` or `service --status-all`.
- **Windows**: Executes PowerShell `Get-Service | Select-Object Name, Status, DisplayName`.
- Displays service name, status (Running/Stopped), description.
- Actions: Start, Stop, Restart, Refresh with confirmation dialogs.
- Search and filter (All, Running, Stopped).

## 8. Shared Clipboard (Mobile to PC)
- Transfers text from Android clipboard to remote PC clipboard through existing SSH session with ZERO remote agent installation.
- **Linux**: Probes for `wl-copy` (Wayland), `xclip` (X11), or `xsel` (X11).
- **Windows**: Executes PowerShell `Set-Clipboard` over SSH.
- Supports Unicode, multiline text, Bengali / international characters.
- Detects and explains clearly when display server / interactive desktop session is not accessible over SSH.

## 9. Live Resource Monitoring (Linux & Windows + GPU)
- Monitoring interval: default 1 second, configurable in Settings (1s, 2s, 3s, 5s, 10s).
- Metrics: CPU usage %, RAM usage & breakdown, Disk usage, Network throughput, Running processes, Uptime, Hostname, IP.
- **GPU Metrics**: Model, utilization, memory, temperature via `nvidia-smi` or sysfs DRM (Linux) or `Win32_VideoController`/`nvidia-smi` (Windows) where hardware & drivers expose them. If unavailable, clearly marked as unsupported without fake data.

## 10. Verification Criteria
- Flutter unit and widget tests pass.
- APK builds successfully (`flutter build apk`).
- All screens functional: Dashboard, Terminal, SFTP, Service Management, Shared Clipboard, Settings, AI Setup.
