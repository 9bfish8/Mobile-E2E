import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wifi_connector.dart';
import 'wifi_qr.dart';

const _afterConnectUrl = 'https://www.youtube.com';

void main() => runApp(const MobileE2EApp());

class MobileE2EApp extends StatelessWidget {
  const MobileE2EApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile E2E',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _logs = <String>[];
  late final _connector = WifiConnector(_log);
  bool _running = false;

  void _log(String message) {
    final t = TimeOfDay.now().format(context);
    debugPrint('[E2E] $message');
    if (mounted) setState(() => _logs.add('$t  $message'));
  }

  Future<void> _runFlow() async {
    setState(() {
      _running = true;
      _logs.clear();
    });
    try {
      final cred = await Navigator.of(context).push<WifiCredential>(
        MaterialPageRoute(builder: (_) => const QrScanPage()),
      );
      if (cred == null) {
        _log('QR 스캔 취소');
        return;
      }
      _log('QR 인식: ${cred.ssid} / ${cred.security}');

      if (!await _connector.connect(cred)) {
        _log('❌ 와이파이 연결 실패');
        return;
      }

      _log('앱 실행: $_afterConnectUrl');
      final launched = await launchUrl(
        Uri.parse(_afterConnectUrl),
        mode: LaunchMode.externalApplication,
      );
      _log(launched ? '✅ 완료' : '❌ 앱 실행 실패');
    } catch (e) {
      _log('❌ 오류: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR → Wi-Fi → 앱 실행')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (_, i) => Text(_logs[i]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _running ? null : _runFlow,
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(_running ? '진행 중...' : 'QR 스캔 시작'),
      ),
    );
  }
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;
  String? _hint;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final cred = parseWifiQr(raw);
      if (cred != null) {
        _done = true;
        Navigator.of(context).pop(cred);
        return;
      }
      setState(() => _hint = '와이파이 QR이 아닙니다: $raw');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AP의 와이파이 QR을 비춰주세요')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (_hint != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                color: Colors.black54,
                padding: const EdgeInsets.all(12),
                child: Text(_hint!, style: const TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
