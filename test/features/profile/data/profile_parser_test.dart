import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:uuid/uuid.dart';

void main() {
  const validBaseUrl = "https://example.com/configurations/user1/filename.yaml";
  const validExtendedUrl = "https://example.com/configurations/user1/filename.yaml?test#b";
  const validSupportUrl = "https://example.com/support";
  const shadowrocketGostNode =
      "socks://cHJvJTNBdTIwMjU4ODc6M2RlNzkxMTMtODMyZC00MzZjLWEyYzYtZGNmNjJmMGJlMzhlQHQtdWMyMjItMTAwNjcuY2ktbGFiLmNvbTo4MA==?remarks=%E9%A6%99%E6%B8%AF%E9%AB%98%E9%80%9F%E4%B8%93%E7%BA%BF1%5B4K%5D&gost=eyJwYXRoIjoiXC9nb3N0IiwiaG9zdCI6InQtdWMyMjItMTAwNjcuY2ktbGFiLmNvbSIsInJvdXRlIjoid3MifQ==";
  const shadowrocketGostNodeWithRemarkAlias =
      "socks://cHJvJTNBdTIwMjU4ODc6M2RlNzkxMTMtODMyZC00MzZjLWEyYzYtZGNmNjJmMGJlMzhlQHQtdWMyMjItMTAwNjcuY2ktbGFiLmNvbTo4MA==?remark=AliasName&gost=eyJ3c19wYXRoIjoiL2FsaWFzIiwid3NfaG9zdCI6ImFsaWFzLmV4YW1wbGUuY29tIiwibmV0d29yayI6IndzIn0=";
  const shadowrocketGostNodeIpv6 =
      "socks://ZFZlcjE6cCUzQXNzQFtmZDAwOjoxXTo0NDM=?remarks=IPv6Node&gost=eyJwYXRoIjoiLmlwdjYiLCJob3N0IjoiaXB2Ni5leGFtcGxlLmNvbSIsInJvdXRlIjoid3MifQ==";

  group("parse", () {
    test("Should use filename in url with no headers and fragment", () {
      final profile = ProfileParser.parse(
        tempFilePath: '',
        profile: ProfileEntity.remote(
          id: const Uuid().v4(),
          active: true,
          name: '',
          url: validBaseUrl,
          lastUpdate: DateTime.now(),
        ),
      );
      expect(profile.isRight(), true);
      profile.match((l) {}, (r) {
        expect(r is RemoteProfileEntity, true);
        r.map(
          remote: (rp) {
            expect(rp.name, equals("filename"));
            expect(rp.url, equals(validBaseUrl));
            expect(rp.options, isNull);
            expect(rp.subInfo, isNull);
          },
          local: (lp) {},
        );
      });
    });

    test("Should use fragment in url with no headers", () {
      final profile = ProfileParser.parse(
        tempFilePath: '',
        profile: ProfileEntity.remote(
          id: const Uuid().v4(),
          active: true,
          name: '',
          url: validExtendedUrl,
          lastUpdate: DateTime.now(),
        ),
      );
      expect(profile.isRight(), true);
      profile.match((l) {}, (r) {
        expect(r is RemoteProfileEntity, true);
        r.map(
          remote: (rp) {
            expect(rp.name, equals("b"));
            expect(rp.url, equals(validExtendedUrl));
            expect(rp.options, isNull);
            expect(rp.subInfo, isNull);
          },
          local: (lp) {},
        );
      });
    });

    test("Should use base64 title in headers", () {
      final headers = <String, List<String>>{
        "profile-title": ["base64:ZXhhbXBsZVRpdGxl"],
        "profile-update-interval": ["1"],
        "connection-test-url": [validBaseUrl],
        "remote-dns-address": [validBaseUrl],
        "subscription-userinfo": ["upload=0;download=1024;total=10240.5;expire=1704054600.55"],
        "profile-web-page-url": [validBaseUrl],
        "support-url": [validSupportUrl],
      };
      // This fix occurs in the _downloadProfile method within ProfileParser, and the fixed headers are passed to populateHeaders
      final fixedHeaders = headers.map((key, value) {
        if (value.length == 1) return MapEntry(key, value.first);
        return MapEntry(key, value);
      });
      final allHeaders = ProfileParser.populateHeaders(content: '', remoteHeaders: fixedHeaders);
      expect(allHeaders.isRight(), true);
      allHeaders.match((l) {}, (r) {
        final profile = ProfileParser.parse(
          tempFilePath: '',
          profile: ProfileEntity.remote(
            id: const Uuid().v4(),
            active: true,
            name: '',
            url: validExtendedUrl,
            lastUpdate: DateTime.now(),
            populatedHeaders: r,
          ),
        );
        expect(profile.isRight(), true);
        profile.match((l) {}, (r) {
          expect(r is RemoteProfileEntity, true);
          r.map(
            remote: (rp) {
              expect(rp.name, equals("exampleTitle"));
              expect(rp.url, equals(validExtendedUrl));
              expect(rp.options, equals(const ProfileOptions(updateInterval: Duration(hours: 1))));
              expect(
                rp.subInfo,
                equals(
                  SubscriptionInfo(
                    upload: 0,
                    download: 1024,
                    total: 10240,
                    expire: DateTime.fromMillisecondsSinceEpoch(1704054600 * 1000),
                    webPageUrl: validBaseUrl,
                    supportUrl: validSupportUrl,
                  ),
                ),
              );
            },
            local: (lp) {},
          );
        });
      });
    });

    test("Should use infinite when given 0 for subscription properties", () {
      final headers = <String, List<String>>{
        "profile-title": ["title"],
        "profile-update-interval": ["1"],
        "subscription-userinfo": ["upload=0;download=1024;total=0;expire=0"],
        "profile-web-page-url": [validBaseUrl],
        "support-url": [validSupportUrl],
      };
      // This fix occurs in the _downloadProfile method within ProfileParser, and the fixed headers are passed to populateHeaders
      final fixedHeaders = headers.map((key, value) {
        if (value.length == 1) return MapEntry(key, value.first);
        return MapEntry(key, value);
      });
      final allHeaders = ProfileParser.populateHeaders(content: '', remoteHeaders: fixedHeaders);
      expect(allHeaders.isRight(), true);
      allHeaders.match((l) {}, (r) {
        final profile = ProfileParser.parse(
          tempFilePath: '',
          profile: RemoteProfileEntity(
            id: const Uuid().v4(),
            active: true,
            name: '',
            url: validBaseUrl,
            lastUpdate: DateTime.now(),
            populatedHeaders: r,
          ),
        );
        expect(profile.isRight(), true);
        profile.match((l) {}, (r) {
          expect(r is RemoteProfileEntity, true);
          r.map(
            remote: (rp) {
              expect(rp.subInfo, isNotNull);
              expect(rp.subInfo!.total, equals(ProfileParser.infiniteTrafficThreshold + 1));
              expect(
                rp.subInfo!.expire,
                equals(DateTime.fromMillisecondsSinceEpoch(ProfileParser.infiniteTimeThreshold * 1000)),
              );
            },
            local: (lp) {},
          );
        });
      });
    });
  });

  group("normalizeShadowrocketGostContent", () {
    test("Should convert Shadowrocket GOST socks nodes into xray outbounds", () {
      final normalized = ProfileParser.normalizeShadowrocketGostContent(shadowrocketGostNode);

      expect(normalized, isNotNull);
      final jsonStart = normalized!.indexOf('{');
      expect(jsonStart, greaterThanOrEqualTo(0));
      expect(normalized.substring(0, jsonStart), contains("#profile-title: base64:"));

      final config = normalized.substring(jsonStart);
      final decoded = jsonDecode(config) as Map<String, dynamic>;
      final outbounds = decoded["outbounds"] as List<dynamic>;
      final outbound = outbounds.single as Map<String, dynamic>;
      final xconfig = outbound["xconfig"] as Map<String, dynamic>;
      final xrayOutbound = (xconfig["outbounds"] as List<dynamic>).single as Map<String, dynamic>;
      final settings = xrayOutbound["settings"] as Map<String, dynamic>;
      final server = (settings["servers"] as List<dynamic>).single as Map<String, dynamic>;
      final user = (server["users"] as List<dynamic>).single as Map<String, dynamic>;
      final streamSettings = xrayOutbound["streamSettings"] as Map<String, dynamic>;
      final wsSettings = streamSettings["wsSettings"] as Map<String, dynamic>;
      final headers = wsSettings["headers"] as Map<String, dynamic>;

      expect(outbound["type"], equals("xray"));
      expect(outbound["tag"], equals("香港高速专线1[4K]"));
      expect(xrayOutbound["protocol"], equals("socks"));
      expect(server["address"], equals("t-uc222-10067.ci-lab.com"));
      expect(server["port"], equals(80));
      expect(user["user"], equals("pro:u2025887"));
      expect(user["pass"], equals("3de79113-832d-436c-a2c6-dcf62f0be38e"));
      expect(streamSettings["network"], equals("ws"));
      expect(wsSettings["path"], equals("/gost"));
      expect(headers["Host"], equals("t-uc222-10067.ci-lab.com"));
    });

    test("Should deduplicate generated outbound tags", () {
      final normalized = ProfileParser.normalizeShadowrocketGostContent(
        "$shadowrocketGostNode\n$shadowrocketGostNode",
      );

      expect(normalized, isNotNull);
      final config = normalized!.substring(normalized.indexOf('{'));
      final decoded = jsonDecode(config) as Map<String, dynamic>;
      final outbounds = decoded["outbounds"] as List<dynamic>;

      expect((outbounds[0] as Map<String, dynamic>)["tag"], equals("香港高速专线1[4K]"));
      expect((outbounds[1] as Map<String, dynamic>)["tag"], equals("香港高速专线1[4K] #2"));
    });

    test("Should support base64-wrapped shadowrocket gost content", () {
      final wrapped = base64Encode(utf8.encode(shadowrocketGostNode));
      final normalized = ProfileParser.normalizeShadowrocketGostContent(utf8.decode(base64Decode(wrapped)));

      expect(normalized, isNotNull);
      final decoded = jsonDecode(normalized!.substring(normalized.indexOf('{'))) as Map<String, dynamic>;
      final outbounds = decoded['outbounds'] as List<dynamic>;

      expect(outbounds, hasLength(1));
      expect((outbounds.single as Map<String, dynamic>)['tag'], equals('香港高速专线1[4K]'));
    });

    test("Should support remark alias and ws field aliases", () {
      final normalized = ProfileParser.normalizeShadowrocketGostContent(shadowrocketGostNodeWithRemarkAlias);

      expect(normalized, isNotNull);
      final decoded = jsonDecode(normalized!.substring(normalized.indexOf('{'))) as Map<String, dynamic>;
      final outbound = (decoded['outbounds'] as List<dynamic>).single as Map<String, dynamic>;
      final xrayOutbound = ((outbound['xconfig'] as Map<String, dynamic>)['outbounds'] as List<dynamic>).single
          as Map<String, dynamic>;
      final wsSettings = xrayOutbound['streamSettings'] as Map<String, dynamic>;
      final innerWs = wsSettings['wsSettings'] as Map<String, dynamic>;

      expect(outbound['tag'], equals('AliasName'));
      expect(innerWs['path'], equals('/alias'));
      expect((innerWs['headers'] as Map<String, dynamic>)['Host'], equals('alias.example.com'));
    });

    test("Should support IPv6 endpoints and passwords containing colon", () {
      final normalized = ProfileParser.normalizeShadowrocketGostContent(shadowrocketGostNodeIpv6);

      expect(normalized, isNotNull);
      final decoded = jsonDecode(normalized!.substring(normalized.indexOf('{'))) as Map<String, dynamic>;
      final outbound = (decoded['outbounds'] as List<dynamic>).single as Map<String, dynamic>;
      final xrayOutbound = ((outbound['xconfig'] as Map<String, dynamic>)['outbounds'] as List<dynamic>).single
          as Map<String, dynamic>;
      final server = (((xrayOutbound['settings'] as Map<String, dynamic>)['servers'] as List<dynamic>).single)
          as Map<String, dynamic>;
      final user = ((server['users'] as List<dynamic>).single) as Map<String, dynamic>;

      expect(outbound['tag'], equals('IPv6Node'));
      expect(server['address'], equals('fd00::1'));
      expect(server['port'], equals(443));
      expect(user['user'], equals('dVer1'));
      expect(user['pass'], equals('p:ss'));
    });
  });
}
