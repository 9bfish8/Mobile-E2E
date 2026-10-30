import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

import 'wifi_qr.dart';

typedef Log = void Function(String message);

class WifiConnector {
  WifiConnector(this.log);

  final Log log;

  /// Saves the network system-wide (Android 11+ shows a "Save network?" dialog)
  /// so other apps like Chrome/YouTube can use it, then waits until it's active.
  Future<bool> connect(
    WifiCredential cred, {
    Duration timeout = const Duration(seconds: 40),
  }) async {
    if (!await Permission.locationWhenInUse.request().isGranted) {
      log('위치 권한이 없어 현재 SSID를 확인할 수 없습니다.');
      return false;
    }

    final security = cred.isOpen
        ? NetworkSecurity.NONE
        : cred.security.toUpperCase() == 'WEP'
            ? NetworkSecurity.WEP
            : NetworkSecurity.WPA;

    log('네트워크 등록 요청: ${cred.ssid} ($security)');
    // registerWifiNetwork always returns false in wifi_iot 0.3.x; verify by polling instead.
    await WiFiForIoTPlugin.registerWifiNetwork(
      cred.ssid,
      password: cred.password,
      security: security,
      isHidden: cred.hidden,
    );

    log('연결 대기 중... (시스템 팝업에서 "저장"을 눌러주세요)');
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final current = await currentSsid();
      if (current == cred.ssid) {
        log('연결 완료: $current');
        return true;
      }
    }
    log('시간 초과: 현재 SSID = ${await currentSsid()}');
    return false;
  }

  Future<String?> currentSsid() async {
    final ssid = await WiFiForIoTPlugin.getSSID();
    return ssid?.replaceAll('"', '');
  }
}
