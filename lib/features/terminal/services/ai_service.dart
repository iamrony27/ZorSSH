import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:zorssh/core/config/secrets.dart';
import 'package:zorssh/core/services/os_detector.dart';

class AiConfig {
  final String provider; // 'nvidia' or 'custom'
  final String apiKey;
  final String endpoint;
  final String model;

  const AiConfig({
    required this.provider,
    required this.apiKey,
    required this.endpoint,
    required this.model,
  });

  bool get isNvidia => provider == 'nvidia';

  factory AiConfig.defaultNvidia({String? apiKey}) {
    return AiConfig(
      provider: 'nvidia',
      apiKey: apiKey ?? AiService.embeddedNvidiaApiKey,
      endpoint: AiService.defaultNvidiaEndpoint,
      model: AiService.defaultNvidiaModel,
    );
  }
}

class CommandSafetyAssessment {
  final bool isDangerous;
  final String? warningMessage;

  const CommandSafetyAssessment({
    required this.isDangerous,
    this.warningMessage,
  });

  static const safe = CommandSafetyAssessment(isDangerous: false);
}

class AiConnectionResult {
  final bool isSuccess;
  final String message;

  const AiConnectionResult._({required this.isSuccess, required this.message});

  factory AiConnectionResult.success([String message = 'Connection verified successfully']) =>
      AiConnectionResult._(isSuccess: true, message: message);

  factory AiConnectionResult.failure(String message) =>
      AiConnectionResult._(isSuccess: false, message: message);
}

class AiService {
  static const String defaultNvidiaEndpoint = 'https://integrate.api.nvidia.com/v1';
  static const String defaultNvidiaModel = 'nvidia/nemotron-3.5-super-vl-120b-a12b';
  static const String embeddedNvidiaApiKey = AppSecrets.defaultNvidiaApiKey;

  /// Convenience alias for cleanCommandOutput
  static String cleanCommand(String raw) => cleanCommandOutput(raw);

  /// Test connection to NVIDIA NIM or OpenAI-compatible endpoint
  static Future<AiConnectionResult> testConnection({
    String endpoint = defaultNvidiaEndpoint,
    String apiKey = embeddedNvidiaApiKey,
    String model = defaultNvidiaModel,
  }) async {
    final effectiveApiKey =
        apiKey.trim().isEmpty ? embeddedNvidiaApiKey : apiKey.trim();
    final effectiveEndpoint =
        endpoint.trim().isEmpty ? defaultNvidiaEndpoint : endpoint.trim();
    final effectiveModel =
        model.trim().isEmpty ? defaultNvidiaModel : model.trim();

    final cleanEndpoint = effectiveEndpoint.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanEndpoint/chat/completions');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $effectiveApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': effectiveModel,
              'messages': [
                {'role': 'user', 'content': 'echo test'},
              ],
              'max_tokens': 5,
              'temperature': 0.1,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return AiConnectionResult.success(
          'Connected successfully to $effectiveModel',
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return AiConnectionResult.failure(
          'Authentication failed: Invalid API Key (${response.statusCode})',
        );
      } else if (response.statusCode == 404) {
        return AiConnectionResult.failure(
          'Endpoint or Model "$effectiveModel" not found (404)',
        );
      } else if (response.statusCode == 429) {
        return AiConnectionResult.failure(
          'API Rate limit exceeded or quota exhausted (429)',
        );
      } else {
        String detail = response.body;
        try {
          final bodyJson = jsonDecode(response.body);
          if (bodyJson is Map && bodyJson['error'] != null) {
            detail = bodyJson['error']['message'] ?? detail;
          }
        } catch (_) {}
        return AiConnectionResult.failure(
          'Provider returned error ${response.statusCode}: $detail',
        );
      }
    } on SocketException catch (e) {
      return AiConnectionResult.failure('Network connection error: ${e.message}');
    } on TimeoutException {
      return AiConnectionResult.failure('Connection timed out after 12s');
    } catch (e) {
      return AiConnectionResult.failure('Failed to connect: $e');
    }
  }

  /// Generates a strict, executable single command tailored for the target OS and shell.
  static Future<String> generateCommand({
    required String userPrompt,
    required OsInfo osInfo,
    String endpoint = defaultNvidiaEndpoint,
    String apiKey = embeddedNvidiaApiKey,
    String model = defaultNvidiaModel,
  }) async {
    final effectiveApiKey =
        apiKey.trim().isEmpty ? embeddedNvidiaApiKey : apiKey.trim();
    final effectiveEndpoint =
        endpoint.trim().isEmpty ? defaultNvidiaEndpoint : endpoint.trim();
    final effectiveModel =
        model.trim().isEmpty ? defaultNvidiaModel : model.trim();

    final cleanEndpoint = effectiveEndpoint.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanEndpoint/chat/completions');

    final targetOsLabel = osInfo.isWindows
        ? 'Windows (Shell: PowerShell / CMD)'
        : 'Linux (${osInfo.distroName}, Shell: ${osInfo.shell})';

    final systemPrompt = '''
You are an expert operating system engineer and CLI command generator.
The target server environment is: $targetOsLabel.

STRICT INSTRUCTIONS:
1. OUTPUT ONLY THE SINGLE EXECUTABLE COMMAND ON ONE LINE.
2. ABSOLUTELY NO CONVERSATIONAL TEXT, NO GREETINGS, NO EXPLANATIONS.
3. ABSOLUTELY NO MARKDOWN CODE FENCES (DO NOT USE ``` OR `).
4. STRICT OS COMPLIANCE:
   ${osInfo.isWindows ? '- Generate ONLY valid Windows PowerShell commands (e.g. Stop-Computer, Restart-Computer, Get-Process, Get-Service, Stop-Service, Remove-Item). NEVER generate Linux bash commands.' : '- Generate ONLY valid Linux shell commands (e.g. shutdown -h now, reboot, free -h, ps aux, systemctl, rm -rf). NEVER generate Windows cmdlets.'}
5. If administrative permissions are needed on Linux, prefix with sudo.
6. The user must be able to directly execute this exact output in the terminal.
''';

    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $effectiveApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': effectiveModel,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt.trim()},
            ],
            'temperature': 0.1,
            'max_tokens': 512,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('AI request timed out after 15s'),
        );

    if (response.statusCode != 200) {
      String err = 'Error ${response.statusCode}';
      try {
        final j = jsonDecode(response.body);
        if (j is Map && j['error'] != null) {
          err = j['error']['message'] ?? err;
        }
      } catch (_) {}
      throw Exception(err);
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty response from AI provider');
    }

    final messageObj = choices[0]['message'] as Map?;
    var rawContent = messageObj?['content'] as String? ?? '';
    if (rawContent.isEmpty && messageObj?['reasoning_content'] != null) {
      rawContent = messageObj!['reasoning_content'] as String;
    }
    final cleaned = cleanCommandOutput(rawContent);

    if (cleaned.isEmpty) {
      throw Exception('No command could be generated');
    }

    // Safety validation against OS mismatch
    validateOsCompatibility(cleaned, osInfo);

    return cleaned;
  }

  /// Post-process and sanitize raw LLM output to guarantee clean executable command
  static String cleanCommandOutput(String raw) {
    var text = raw.trim();

    // Remove markdown code fences
    text = text.replaceAll(RegExp(r'^```[a-zA-Z0-9_-]*\n?', multiLine: true), '');
    text = text.replaceAll(RegExp(r'```$', multiLine: true), '');
    text = text.replaceAll('`', '');

    // Split lines and find the first non-empty command line
    final lines = text.split('\n');
    for (final line in lines) {
      var trimmed = line.trim();
      if (trimmed.startsWith(r'$ ')) {
        trimmed = trimmed.substring(2).trim();
      } else if (trimmed.startsWith('# ')) {
        trimmed = trimmed.substring(2).trim();
      }
      if (trimmed.isNotEmpty &&
          !trimmed.toLowerCase().startsWith('note:') &&
          !trimmed.toLowerCase().startsWith('here is') &&
          !trimmed.toLowerCase().startsWith('this command') &&
          !trimmed.toLowerCase().startsWith('sure')) {
        return trimmed;
      }
    }

    return text.trim();
  }

  /// Rejects commands that are fundamentally incompatible with the target OS
  static void validateOsCompatibility(String command, OsInfo osInfo) {
    final lower = command.toLowerCase();

    if (osInfo.isWindows) {
      // Reject obvious linux commands on Windows
      if (lower.startsWith('sudo ') ||
          lower.startsWith('apt ') ||
          lower.startsWith('apt-get ') ||
          lower.startsWith('yum ') ||
          lower.startsWith('systemctl ') ||
          lower == 'reboot' ||
          lower.startsWith('reboot ') ||
          lower == 'shutdown -h now' ||
          lower.startsWith('free -')) {
        throw Exception(
          'Generated command is a Linux command and cannot be executed on Windows: "$command"',
        );
      }
    } else if (osInfo.isLinux) {
      // Reject obvious Windows PowerShell commands on Linux
      if (lower.startsWith('get-') ||
          lower.startsWith('stop-') ||
          lower.startsWith('start-') ||
          lower.startsWith('restart-') ||
          lower.startsWith('set-') ||
          lower.startsWith('new-item') ||
          lower.startsWith('remove-item')) {
        throw Exception(
          'Generated command is a Windows PowerShell command and cannot be executed on Linux: "$command"',
        );
      }
    }
  }

  /// Evaluates command risk and determines if user confirmation is mandatory
  static CommandSafetyAssessment assessSafety(String command) {
    final lower = command.toLowerCase().trim();

    // 1. Shutdown / Reboot
    if (lower.contains('shutdown') ||
        lower.contains('reboot') ||
        lower.contains('poweroff') ||
        lower.contains('stop-computer') ||
        lower.contains('restart-computer') ||
        lower.contains('init 0') ||
        lower.contains('init 6')) {
      return const CommandSafetyAssessment(
        isDangerous: true,
        warningMessage:
            'This command will SHUTDOWN or REBOOT the remote system. Any active sessions or unsaved data will be lost.',
      );
    }

    // 2. Destructive Deletion
    if (lower.contains('rm -rf') ||
        lower.contains('rm -r') ||
        lower.contains('remove-item -recurse') ||
        lower.contains('del /s') ||
        lower.contains('rmdir /s')) {
      return const CommandSafetyAssessment(
        isDangerous: true,
        warningMessage:
            'This command performs RECURSIVE FILE DELETION. Deleted files cannot be restored.',
      );
    }

    // 3. Disk formatting or block device writes
    if (lower.contains('mkfs') ||
        lower.contains('fdisk') ||
        lower.contains('parted') ||
        lower.contains('dd if=') ||
        lower.contains('format-volume') ||
        lower.contains('clear-disk')) {
      return const CommandSafetyAssessment(
        isDangerous: true,
        warningMessage:
            'This command modifies DISK PARTITIONS or FORMATS STORAGE. This causes permanent data destruction.',
      );
    }

    // 4. Force process or service kill
    if (lower.contains('kill -9') ||
        lower.contains('killall') ||
        lower.contains('stop-process -force')) {
      return const CommandSafetyAssessment(
        isDangerous: true,
        warningMessage:
            'This command FORCE KILLS running processes, which may cause data corruption.',
      );
    }

    return CommandSafetyAssessment.safe;
  }
}
