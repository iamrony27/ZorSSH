# ROADMAP — AetherSSH Implementation

## Phase 1: Repository Foundation & New Branding
- Setup Flutter application files in root project directory.
- Define application identity: AetherSSH (`com.aetherssh.app`).
- Create high-resolution launcher icons, logos, vector assets, and brand assets.
- Configure `pubspec.yaml` with all required dependencies and assets.
- Configure Android project (`AndroidManifest.xml`, `build.gradle`, permissions, package name, application label).

## Phase 2: Core Architecture & Fix SFTP Download
- Port core services (`ssh_service`, `secure_storage_service`, `server_service`, `host_key_service`, `hive_service`).
- Implement OS Detection Engine (`os_detector.dart` for Linux & Windows).
- Re-architect SFTP Download Manager:
  - Streaming direct-to-file download to standard Android Downloads directory.
  - Download state tracking (progress, speed, bytes, active/done/failed).
  - Download Manager UI Sheet & dialogs.
  - Duplicate file handling, cancellation, retry.
  - Keep upload functionality intact.

## Phase 3: AI Engine & NVIDIA NIM Integration
- Implement `AiService` supporting NVIDIA NIM and custom OpenAI-compatible endpoints.
- Secure storage for API Key, Model, and Endpoint.
- AI Provider Settings UI & First-time setup modal.
- Test connection API logic with descriptive error handling.
- OS-aware command generation prompt engineering (strict command output only, no markdown, no conversational text).
- Dangerous command detector and safety confirmation system.
- Terminal integration: "AI Commands" button in `_QuickKeysBar`, Command preview card with "RUN" action.

## Phase 4: Active Service Management & Shared Clipboard
- Implement `ServiceManagementService`:
  - Linux `systemctl` / Windows PowerShell `Get-Service`.
  - Start, Stop, Restart actions with confirmation and output feedback.
- Service Management screen with search, status filters (Running / Stopped), and refresh.
- Implement `ClipboardSyncService`:
  - Linux `wl-copy`, `xclip`, `xsel` detection & execution.
  - Windows `Set-Clipboard` execution.
  - Unicode/Bengali multiline text support.
  - Clear user guidance when remote display is unavailable.
- Shared Clipboard UI dialog / bottom sheet in Terminal and Server Details.

## Phase 5: Enhanced Resource Monitoring (Linux & Windows + GPU & Processes)
- Extend `ServerStats` and monitoring viewmodel to support:
  - Linux & Windows command pipelines.
  - Real GPU metrics (NVIDIA / DRM / Windows CimInstance).
  - Top running processes (CPU %, MEM %, PID, Name).
  - Configurable 1s update interval.
- Dashboard enhancements for GPU, processes, and OS icons in server summary cards.

## Phase 6: Navigation, Settings, UI Polish & Verification
- Integrate all new screens into `app_router.dart`, `server_details_screen.dart`, `dashboard_screen.dart`, `terminal_screen.dart`, and `settings_screen.dart`.
- Ensure theme consistency, smooth transitions, proper error mapper.
- Run tests (`flutter test`).
- Build APK (`flutter build apk`).
- Verify complete functionality and generate final development report.
