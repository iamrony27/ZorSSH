import 'package:flutter_test/flutter_test.dart';
import 'package:aetherssh/core/services/os_detector.dart';

void main() {
  group('OsInfo.fromDistroString', () {
    test('identifies Ubuntu correctly', () {
      final info = OsInfo.fromDistroString('Ubuntu 24.04 LTS');
      expect(info.type, OsType.linux);
      expect(info.distroKey, 'ubuntu');
      expect(info.shell, 'bash');
      expect(info.isLinux, isTrue);
      expect(info.isWindows, isFalse);
    });

    test('identifies Debian correctly', () {
      final info = OsInfo.fromDistroString('Debian GNU/Linux 12 (bookworm)');
      expect(info.type, OsType.linux);
      expect(info.distroKey, 'debian');
      expect(info.shell, 'bash');
    });

    test('identifies Linux Mint correctly', () {
      final info = OsInfo.fromDistroString('Linux Mint 22 Wilma');
      expect(info.type, OsType.linux);
      expect(info.distroKey, 'mint');
      expect(info.shell, 'bash');
    });

    test('identifies Fedora correctly', () {
      final info = OsInfo.fromDistroString('Fedora Linux 40 (Server Edition)');
      expect(info.type, OsType.linux);
      expect(info.distroKey, 'fedora');
      expect(info.shell, 'bash');
    });

    test('identifies Arch Linux correctly', () {
      final info = OsInfo.fromDistroString('Arch Linux rolling');
      expect(info.type, OsType.linux);
      expect(info.distroKey, 'arch');
      expect(info.shell, 'bash');
    });

    test('identifies Windows Server / PC correctly', () {
      final info = OsInfo.fromDistroString('Microsoft Windows 11 Pro');
      expect(info.type, OsType.windows);
      expect(info.distroKey, 'windows');
      expect(info.shell, 'powershell');
      expect(info.isWindows, isTrue);
      expect(info.isLinux, isFalse);
    });

    test('identifies macOS correctly', () {
      final info = OsInfo.fromDistroString('Darwin Kernel 23.4.0');
      expect(info.type, OsType.macos);
      expect(info.distroKey, 'mac');
      expect(info.isMac, isTrue);
    });

    test('handles unknown or empty distro safely', () {
      final info = OsInfo.fromDistroString('');
      expect(info.type, OsType.unknown);
    });
  });
}
