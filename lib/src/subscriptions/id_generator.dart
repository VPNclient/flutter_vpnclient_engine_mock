import 'dart:math';

/// Generates a globally-unique-enough string id, without pulling in a
/// dedicated uuid dependency for a mock package.
String generateId(String prefix) {
  final random = Random();
  final suffix = List.generate(8, (_) => random.nextInt(16).toRadixString(16)).join();
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$suffix';
}
