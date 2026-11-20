import 'package:flutter_test/flutter_test.dart';
import 'package:aetherssh/features/terminal/services/ai_service.dart';

void main() {
  group('AiService - Command Cleaning', () {
    test('cleans raw command correctly', () {
      expect(AiService.cleanCommand('  ls -la  '), 'ls -la');
    });

    test('strips bash code fence blocks', () {
      const input = '```bash\napt update && apt upgrade -y\n```';
      expect(AiService.cleanCommand(input), 'apt update && apt upgrade -y');
    });

    test('strips generic code fences and extra text', () {
      const input = '```sh\nsystemctl restart nginx\n```\nHere is your command.';
      expect(AiService.cleanCommand(input), 'systemctl restart nginx');
    });

    test('strips shell prompts like dollar or hash', () {
      expect(AiService.cleanCommand('\$ htop'), 'htop');
      expect(AiService.cleanCommand('# systemctl status docker'), 'systemctl status docker');
    });

    test('strips inline backticks', () {
      expect(AiService.cleanCommand('`df -h`'), 'df -h');
    });
  });

  group('AiService - Dangerous Command Safety Detection', () {
    test('flags dangerous Linux destruction commands', () {
      final rmCheck = AiService.assessSafety('rm -rf /var/log/*');
      expect(rmCheck.isDangerous, isTrue);

      final mkfsCheck = AiService.assessSafety('mkfs.ext4 /dev/sda1');
      expect(mkfsCheck.isDangerous, isTrue);

      final ddCheck = AiService.assessSafety('dd if=/dev/zero of=/dev/nvme0n1');
      expect(ddCheck.isDangerous, isTrue);
    });

    test('flags dangerous reboot and shutdown commands', () {
      final shutdownCheck = AiService.assessSafety('shutdown -h now');
      expect(shutdownCheck.isDangerous, isTrue);

      final rebootCheck = AiService.assessSafety('reboot');
      expect(rebootCheck.isDangerous, isTrue);

      final initCheck = AiService.assessSafety('init 0');
      expect(initCheck.isDangerous, isTrue);
    });

    test('flags dangerous Windows PowerShell commands', () {
      final stopCheck = AiService.assessSafety('Stop-Computer -Force');
      expect(stopCheck.isDangerous, isTrue);

      final restartCheck = AiService.assessSafety('Restart-Computer');
      expect(restartCheck.isDangerous, isTrue);

      final formatCheck = AiService.assessSafety('Format-Volume -DriveLetter D');
      expect(formatCheck.isDangerous, isTrue);
    });

    test('allows safe informational commands without warning', () {
      final lsCheck = AiService.assessSafety('ls -la /var/www');
      expect(lsCheck.isDangerous, isFalse);

      final dockerCheck = AiService.assessSafety('docker ps -a');
      expect(dockerCheck.isDangerous, isFalse);

      final psCheck = AiService.assessSafety('Get-Process');
      expect(psCheck.isDangerous, isFalse);
    });
  });

  group('AiConfig', () {
    test('default Nvidia config has correct endpoint and model', () {
      final config = AiConfig.defaultNvidia();
      expect(config.isNvidia, isTrue);
      expect(config.endpoint, 'https://integrate.api.nvidia.com/v1');
      expect(config.model, 'nvidia/nemotron-3.5-lightning-30b-a3b');
      expect(config.apiKey, 'nvapi-placeholder');
    });
  });
}
