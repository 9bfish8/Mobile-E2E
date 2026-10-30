class WifiCredential {
  const WifiCredential({
    required this.ssid,
    this.password,
    this.security = 'nopass',
    this.hidden = false,
  });

  final String ssid;
  final String? password;

  /// QR `T:` value as-is: WPA, WEP, SAE, nopass...
  final String security;
  final bool hidden;

  bool get isOpen => security.toLowerCase() == 'nopass' || security.isEmpty;

  @override
  String toString() =>
      'WifiCredential(ssid: $ssid, security: $security, hidden: $hidden)';
}

/// Parses the standard `WIFI:T:WPA;S:ssid;P:pass;H:false;;` QR payload.
WifiCredential? parseWifiQr(String raw) {
  const prefix = 'WIFI:';
  if (!raw.toUpperCase().startsWith(prefix)) return null;

  final fields = <String, String>{};
  for (final field in _splitUnescaped(raw.substring(prefix.length), ';')) {
    final sep = field.indexOf(':');
    if (sep <= 0) continue;
    fields[field.substring(0, sep).toUpperCase()] =
        _unescape(field.substring(sep + 1));
  }

  final ssid = fields['S'];
  if (ssid == null || ssid.isEmpty) return null;

  return WifiCredential(
    ssid: ssid,
    password: fields['P'],
    security: fields['T'] ?? 'nopass',
    hidden: fields['H']?.toLowerCase() == 'true',
  );
}

List<String> _splitUnescaped(String input, String delimiter) {
  final parts = <String>[];
  final buf = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (c == r'\' && i + 1 < input.length) {
      buf
        ..write(c)
        ..write(input[++i]);
    } else if (c == delimiter) {
      parts.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  if (buf.isNotEmpty) parts.add(buf.toString());
  return parts;
}

String _unescape(String value) {
  final buf = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    if (value[i] == r'\' && i + 1 < value.length) i++;
    buf.write(value[i]);
  }
  return buf.toString();
}
