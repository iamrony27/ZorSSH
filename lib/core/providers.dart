import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zorssh/core/models/server.dart';
import 'package:zorssh/core/services/server_service.dart';
import 'package:zorssh/core/services/ssh_service.dart';
import 'package:zorssh/core/services/hive_service.dart';
import 'package:zorssh/features/dashboard/repositories/server_repository.dart';
import 'package:zorssh/core/services/secure_storage_service.dart';
import 'package:zorssh/core/services/host_key_service.dart';

final serverServiceProvider = FutureProvider<ServerService>((ref) async {
  final repository = await ref.watch(serverRepositoryProvider.future);
  return ServerService(repository);
});

final sshServiceProvider = Provider((ref) {
  final secureStorage = ref.read(secureStorageServiceProvider);
  final hostKeyService = ref.watch(hostKeyServiceProvider);
  return SshService(secureStorage, hostKeyService);
});

// Legacy serverListProvider removed in favor of MVVM stream provider.

// --- New MVVM Providers ---

/// Repository provider - single source of truth for server data
final serverRepositoryProvider = FutureProvider<ServerRepository>((ref) async {
  final hiveBox = await ref.watch(hiveProvider.future);
  final secureStorage = ref.read(secureStorageServiceProvider);
  return ServerRepository(hiveBox, secureStorage);
});

/// Stream provider for reactive UI updates
/// UI should watch this instead of serverListProvider
final serverListStreamProvider = StreamProvider<List<Server>>((ref) async* {
  final repository = await ref.watch(serverRepositoryProvider.future);
  yield* repository.watchAllServers();
});
