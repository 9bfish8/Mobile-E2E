import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'wifi_connector.dart';
import 'wifi_qr.dart';

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

  /// Machine-readable state read by the Appium suite in e2e/:
  /// `IDLE`, `SCANNING`, `CONNECTING`, `CONNECTED:<ssid>`, `FAILED:<reason>`.
  String _status = 'IDLE';

  void _log(String message) {
    final t = TimeOfDay.now().format(context);
    debugPrint('[E2E] $message');
    if (mounted) setState(() => _logs.add('$t  $message'));
  }

  void _setStatus(String status) {
    debugPrint('[E2E] status=$status');
    if (mounted) setState(() => _status = status);
  }

  Future<void> _runFlow() async {
    setState(() {
      _running = true;
      _logs.clear();
    });
    _setStatus('SCANNING');
    try {
      final cred = await Navigator.of(context).push<WifiCredential>(
        MaterialPageRoute(builder: (_) => const QrScanPage()),
      );
      if (cred == null) {
        _log('QR 스캔 취소');
        _setStatus('FAILED:SCAN_CANCELLED');
        return;
      }
      _log('QR 인식: ${cred.ssid} / ${cred.security}');

      _setStatus('CONNECTING');
      if (!await _connector.connect(cred)) {
        _log('❌ 와이파이 연결 실패');
        _setStatus('FAILED:WIFI');
        return;
      }
      _log('✅ 완료');
      _setStatus('CONNECTED:${cred.ssid}');
    } catch (e) {
      _log('❌ 오류: $e');
      _setStatus('FAILED:ERROR');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR → Wi-Fi 연결')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `identifier` is exposed as the Android resource-id, so Appium can
          // find these with UiSelector().resourceId("status").
          Semantics(
            identifier: 'status',
            container: true,
            label: _status,
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '상태: $_status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (_, i) => Text(_logs[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        identifier: 'btn_start',
        container: true,
        child: FloatingActionButton.extended(
          onPressed: _running ? null : _runFlow,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(_running ? '진행 중...' : 'QR 스캔 시작'),
        ),
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
