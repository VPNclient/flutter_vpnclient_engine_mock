import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/config/transport_config.dart';

void main() {
  test('parses a VLESS + Reality + ws share-link', () {
    const link = 'vless://2d4e5f6a-1234-5678-9abc-def012345678@example.com:443'
        '?encryption=none&security=reality&pbk=abcPublicKey123&fp=chrome'
        '&sni=www.microsoft.com&sid=0123456789abcdef&spx=%2F'
        '&type=ws&path=%2Fpath&host=cdn.example.com&flow=xtls-rprx-vision'
        '#My-Server';

    final config = ProtocolConfig.parseShareLink(link);

    expect(config, isA<VlessConfig>());
    final vless = config as VlessConfig;
    expect(vless.address, 'example.com');
    expect(vless.port, 443);
    expect(vless.uuid, '2d4e5f6a-1234-5678-9abc-def012345678');
    expect(vless.flow, 'xtls-rprx-vision');
    expect(vless.transport?.type, TransportType.ws);
    expect(vless.transport?.path, '/path');
    expect(vless.transport?.host, 'cdn.example.com');
    expect(vless.tls?.sni, 'www.microsoft.com');
    expect(vless.tls?.reality?.publicKey, 'abcPublicKey123');
    expect(vless.tls?.reality?.shortId, '0123456789abcdef');
    expect(vless.tls?.reality?.spiderX, '/');
  });

  test('parses a VMess + ws + tls share-link', () {
    final json = jsonEncode({
      'v': '2',
      'ps': 'vmess-server',
      'add': 'vmess.example.com',
      'port': '443',
      'id': 'b831381d-6324-4d53-ad4f-8cda48b30811',
      'aid': '0',
      'net': 'ws',
      'type': 'none',
      'host': 'cdn.vmess.com',
      'path': '/vmesspath',
      'tls': 'tls',
      'sni': 'sni.vmess.com',
    });
    final link = 'vmess://${base64Encode(utf8.encode(json))}';

    final config = ProtocolConfig.parseShareLink(link);

    expect(config, isA<VmessConfig>());
    final vmess = config as VmessConfig;
    expect(vmess.address, 'vmess.example.com');
    expect(vmess.port, 443);
    expect(vmess.uuid, 'b831381d-6324-4d53-ad4f-8cda48b30811');
    expect(vmess.alterId, 0);
    expect(vmess.transport?.type, TransportType.ws);
    expect(vmess.transport?.path, '/vmesspath');
    expect(vmess.transport?.host, 'cdn.vmess.com');
    expect(vmess.tls?.sni, 'sni.vmess.com');
  });

  test('parses a Trojan + tls + ws share-link', () {
    const link = 'trojan://mypassword123@trojan.example.com:443'
        '?security=tls&sni=sni.trojan.com&type=ws'
        '&path=%2Ftrojanpath&host=cdn.trojan.com#Trojan-Server';

    final config = ProtocolConfig.parseShareLink(link);

    expect(config, isA<TrojanConfig>());
    final trojan = config as TrojanConfig;
    expect(trojan.address, 'trojan.example.com');
    expect(trojan.port, 443);
    expect(trojan.password, 'mypassword123');
    expect(trojan.transport?.type, TransportType.ws);
    expect(trojan.transport?.path, '/trojanpath');
    expect(trojan.tls?.sni, 'sni.trojan.com');
  });

  test('parses a Shadowsocks (SIP002) share-link', () {
    final userInfo = base64Encode(utf8.encode('aes-256-gcm:p@ssw0rd'));
    final link = 'ss://$userInfo@ss.example.com:8388#SS-Server';

    final config = ProtocolConfig.parseShareLink(link);

    expect(config, isA<ShadowsocksConfig>());
    final ss = config as ShadowsocksConfig;
    expect(ss.address, 'ss.example.com');
    expect(ss.port, 8388);
    expect(ss.method, 'aes-256-gcm');
    expect(ss.password, 'p@ssw0rd');
  });

  test('rejects an unsupported scheme', () {
    expect(
      () => ProtocolConfig.parseShareLink('socks://user@host:1080'),
      throwsFormatException,
    );
  });

  test('WireGuardConfig equality is value-based', () {
    const a = WireGuardConfig(
      address: 'wg.example.com',
      port: 51820,
      publicKey: 'pub',
      privateKey: 'priv',
      allowedIps: ['0.0.0.0/0'],
    );
    const b = WireGuardConfig(
      address: 'wg.example.com',
      port: 51820,
      publicKey: 'pub',
      privateKey: 'priv',
      allowedIps: ['0.0.0.0/0'],
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
