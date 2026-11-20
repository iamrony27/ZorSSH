# Privacy Policy for Zor SSH

**Last updated: November 2026**

Zor SSH ("the App") is developed as a privacy-first, secure mobile server administration and SSH management application. This service is provided to enable developers and system administrators to securely manage remote infrastructure directly from their mobile devices.

### 1. Information Collection and Storage

Zor SSH is engineered with an uncompromising offline-first, zero-telemetry architecture. **The application does not collect, store, transmit, analytics-track, or share any personal information, telemetry, or server usage data with the Developer or any third parties.**

All sensitive data handled by the application—including:
- Server hostnames and IP addresses
- SSH usernames, passwords, and private key passphrases
- Cryptographic private keys (RSA, Ed25519, ECDSA)
- Master PIN hashes and biometric unlock tokens

...are encrypted using hardware-backed keystores (AES-256-GCM / PBKDF2) and stored strictly locally on your physical device. Zor SSH establishes direct, peer-to-peer SSH/SFTP network connections exclusively to your configured servers without routing through any intermediate, proxy, or relay servers.

### 2. Optional Features & Third-Party APIs

- **AI Terminal Assistance:** If you utilize the integrated AI command generation feature, only your non-sensitive command intent and target OS name are sent to the AI engine to synthesize shell commands. Server passwords, private keys, and terminal contents are never transmitted.
- **Server Geolocation:** If you choose to enable optional Server Geolocation in Settings, the app queries the public `ipwho.is` service over encrypted HTTPS to retrieve approximate server country/city coordinates. No credentials, server keys, or identifiers are transmitted.

### 3. Biometric Security

Zor SSH requests access to your device's biometric authentication hardware (Fingerprint, Face Unlock) strictly to authorize local unlocking of the application and your stored credentials. Biometric verification is handled entirely by your device's operating system security enclave (Android BiometricPrompt). Zor SSH never reads, records, or exports your biometric biometric data.

### 4. Changes to This Privacy Policy

The Privacy Policy may be updated periodically to reflect application enhancements or security updates. Review this page periodically for updates.

### 5. Contact & Support

For questions, feedback, or support regarding Zor SSH, please reach out through the official application repository or developer contact channels.
