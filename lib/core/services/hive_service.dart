import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zorssh/core/data/entities/hive_server.dart';

final hiveProvider = FutureProvider<Box<HiveServer>>((ref) async {
  return Hive.box<HiveServer>('servers');
});
