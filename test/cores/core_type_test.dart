import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/cores/core_type.dart';

void main() {
  test('needsExternalDriver is correct for every CoreType', () {
    expect(CoreType.singbox.needsExternalDriver, isFalse);
    expect(CoreType.wireguard.needsExternalDriver, isFalse);
    expect(CoreType.libxray.needsExternalDriver, isTrue);
    expect(CoreType.v2ray.needsExternalDriver, isTrue);
    expect(CoreType.h2.needsExternalDriver, isTrue);
  });

  test('CoreType has exactly the 5 expected values', () {
    expect(CoreType.values, hasLength(5));
  });
}
