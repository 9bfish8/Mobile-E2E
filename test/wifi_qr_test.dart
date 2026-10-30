import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e2e/wifi_qr.dart';

void main() {
  test('parses standard WPA QR', () {
    final c = parseWifiQr('WIFI:T:WPA;S:KT_GiGA_2G_1234;P:pass1234;;')!;
    expect(c.ssid, 'KT_GiGA_2G_1234');
    expect(c.password, 'pass1234');
    expect(c.security, 'WPA');
    expect(c.isOpen, isFalse);
    expect(c.hidden, isFalse);
  });

  test('handles any field order, hidden flag and escaped characters', () {
    final c = parseWifiQr(r'WIFI:S:AA\:BB\:CC;H:true;P:a\;b\\c;T:WPA;;')!;
    expect(c.ssid, 'AA:BB:CC');
    expect(c.password, r'a;b\c');
    expect(c.hidden, isTrue);
  });

  test('open network without T or P', () {
    final c = parseWifiQr('WIFI:S:guest;;')!;
    expect(c.isOpen, isTrue);
    expect(c.password, isNull);
  });

  test('rejects non-wifi payloads and missing SSID', () {
    expect(parseWifiQr('https://example.com'), isNull);
    expect(parseWifiQr('WIFI:T:WPA;P:x;;'), isNull);
  });
}
