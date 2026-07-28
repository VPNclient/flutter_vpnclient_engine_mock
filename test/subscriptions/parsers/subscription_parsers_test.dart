import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/config/transport_config.dart';
import 'package:vpnclient_engine/src/subscriptions/parsers/json_array_parser.dart';
import 'package:vpnclient_engine/src/subscriptions/parsers/share_link_list_parser.dart';
import 'package:vpnclient_engine/src/subscriptions/parsers/sing_box_config_parser.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';

const shareLinkListParser = ShareLinkListParser();
const jsonArrayParser = JsonArrayParser();
const singBoxConfigParser = SingBoxConfigParser();

void main() {
  group('ShareLinkListParser', () {
    test('recognizes and parses a mixed share-link + full-JSON-per-line body', () {
      const shareLine = 'ss://YWVzLTI1Ni1nY206c2VjcmV0@ss.example.com:8388#My-SS';
      final jsonLine = jsonEncode({
        'protocol': 'trojan',
        'address': 'trojan.example.com',
        'port': 443,
        'password': 'pw',
        'name': 'My-Trojan',
      });
      final body = base64Encode(utf8.encode('$shareLine\n$jsonLine'));

      expect(shareLinkListParser.canParse(body), isTrue);
      final servers = shareLinkListParser.parse(body);

      expect(servers, hasLength(2));
      expect(servers[0].definition, isA<ShareLinkDefinition>());
      expect(servers[0].name, 'My-SS');
      expect(servers[1].definition, isA<FullConfigDefinition>());
      expect(servers[1].name, 'My-Trojan');
      expect((servers[1].protocolConfig as TrojanConfig).address, 'trojan.example.com');
    });

    test('rejects non-base64 / non-share-link bodies', () {
      expect(shareLinkListParser.canParse('[{"a":1}]'), isFalse);
      expect(shareLinkListParser.canParse('{"outbounds":[]}'), isFalse);
    });
  });

  group('JsonArrayParser', () {
    final body = jsonEncode([
      {
        'protocol': 'shadowsocks',
        'address': 'ss.example.com',
        'port': 8388,
        'method': 'aes-256-gcm',
        'password': 'secret',
        'name': 'Array-SS',
      },
    ]);

    test('recognizes and parses a whole-document JSON array', () {
      expect(jsonArrayParser.canParse(body), isTrue);
      final servers = jsonArrayParser.parse(body);
      expect(servers, hasLength(1));
      expect(servers.single.name, 'Array-SS');
      expect(servers.single.definition, isA<FullConfigDefinition>());
    });

    test('rejects non-array bodies', () {
      expect(jsonArrayParser.canParse('{"outbounds":[]}'), isFalse);
      final shareLinkBody = base64Encode(utf8.encode('ss://x@host:1#r'));
      expect(jsonArrayParser.canParse(shareLinkBody), isFalse);
    });
  });

  group('SingBoxConfigParser', () {
    final body = jsonEncode({
      'outbounds': [
        {
          'type': 'vless',
          'tag': 'proxy',
          'server': 'vless.example.com',
          'server_port': 443,
          'uuid': 'uuid-1',
          'flow': 'xtls-rprx-vision',
          'tls': {
            'enabled': true,
            'server_name': 'sni.example.com',
            'reality': {
              'enabled': true,
              'public_key': 'pbk',
              'short_id': 'sid',
            },
          },
          'transport': {'type': 'ws', 'path': '/ws'},
        },
        {'type': 'direct', 'tag': 'direct'},
      ],
    });

    test('recognizes and parses outbounds, skipping unsupported types', () {
      expect(singBoxConfigParser.canParse(body), isTrue);
      final servers = singBoxConfigParser.parse(body);
      expect(servers, hasLength(1));
      expect(servers.single.name, 'proxy');
      final config = servers.single.protocolConfig as VlessConfig;
      expect(config.address, 'vless.example.com');
      expect(config.tls?.reality?.publicKey, 'pbk');
      expect(config.transport?.type, TransportType.ws);
    });

    test('rejects non-sing-box bodies', () {
      expect(singBoxConfigParser.canParse('[]'), isFalse);
      final shareLinkBody = base64Encode(utf8.encode('ss://x@host:1#r'));
      expect(singBoxConfigParser.canParse(shareLinkBody), isFalse);
    });
  });
}
