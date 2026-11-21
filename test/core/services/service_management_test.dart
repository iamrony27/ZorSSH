import 'package:flutter_test/flutter_test.dart';
import 'package:zorssh/core/services/service_management_service.dart';

void main() {
  group('ServiceManagementService - Linux Parser', () {
    test('parses systemctl list-units output accurately', () {
      const sampleOutput = '''
cron.service                     loaded active running Regular background program processing daemon
docker.service                   loaded active running Docker Application Container Engine
nginx.service                    loaded active running A high performance web server
postgresql@14-main.service       loaded inactive dead    PostgreSQL RDBMS
failed-worker.service            loaded failed failed  Background Worker Queue
ufw.service                      loaded active exited  CLI to firewall
''';

      final services = ServiceManagementService.parseLinuxServices(sampleOutput);

      expect(services.length, 6);

      // Check cron
      final cron = services.firstWhere((s) => s.name == 'cron.service');
      expect(cron.status, ServiceStatus.running);
      expect(cron.displayName, 'Regular background program processing daemon');
      expect(cron.loadState, 'loaded');
      expect(cron.subState, 'running');
      expect(cron.isWindows, isFalse);

      // Check docker
      final docker = services.firstWhere((s) => s.name == 'docker.service');
      expect(docker.status, ServiceStatus.running);
      expect(docker.displayName, 'Docker Application Container Engine');

      // Check dead postgres
      final postgres = services.firstWhere((s) => s.name == 'postgresql@14-main.service');
      expect(postgres.status, ServiceStatus.stopped);
      expect(postgres.displayName, 'PostgreSQL RDBMS');

      // Check failed worker
      final failedWorker = services.firstWhere((s) => s.name == 'failed-worker.service');
      expect(failedWorker.status, ServiceStatus.failed);

      // Check exited ufw
      final ufw = services.firstWhere((s) => s.name == 'ufw.service');
      expect(ufw.status, ServiceStatus.stopped);
    });

    test('ignores non-service units and empty lines', () {
      const sample = '''
sys-devices-virtual.device        loaded active running Virtual Device
● docker.socket                   loaded active listening Docker Socket
emergency.target                  loaded active active  Emergency Mode
''';
      final services = ServiceManagementService.parseLinuxServices(sample);
      expect(services, isEmpty);
    });
  });

  group('ServiceManagementService - Windows Parser', () {
    test('parses Windows PowerShell Get-Service JSON array', () {
      const sampleJson = '''
[
  {
    "Name": "wuauserv",
    "Status": "Running",
    "DisplayName": "Windows Update"
  },
  {
    "Name": "Spooler",
    "Status": "Running",
    "DisplayName": "Print Spooler"
  },
  {
    "Name": "XboxGipSvc",
    "Status": "Stopped",
    "DisplayName": "Xbox Accessory Management Service"
  }
]
''';

      final services = ServiceManagementService.parseWindowsServices(sampleJson);
      expect(services.length, 3);

      final wuauserv = services.firstWhere((s) => s.name == 'wuauserv');
      expect(wuauserv.status, ServiceStatus.running);
      expect(wuauserv.displayName, 'Windows Update');
      expect(wuauserv.isWindows, isTrue);

      final xbox = services.firstWhere((s) => s.name == 'XboxGipSvc');
      expect(xbox.status, ServiceStatus.stopped);
      expect(xbox.displayName, 'Xbox Accessory Management Service');
    });

    test('handles single object JSON from PowerShell', () {
      const singleJson = '''
{
  "Name": "sshd",
  "Status": "Running",
  "DisplayName": "OpenSSH SSH Server"
}
''';

      final services = ServiceManagementService.parseWindowsServices(singleJson);
      expect(services.length, 1);
      expect(services.first.name, 'sshd');
      expect(services.first.status, ServiceStatus.running);
    });

    test('handles empty or malformed JSON gracefully', () {
      expect(ServiceManagementService.parseWindowsServices(''), isEmpty);
      expect(ServiceManagementService.parseWindowsServices('{invalid json'), isEmpty);
    });
  });
}
