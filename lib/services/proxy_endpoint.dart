/// Only public IPv4 endpoints from the existing opt-in proxy sources are valid.
bool isPublicProxyAddress(String address) {
  final parts = address.split(':');
  if (parts.length != 2) return false;
  final port = int.tryParse(parts[1]);
  if (port == null || port < 1 || port > 65535) return false;
  final octets = parts[0].split('.');
  if (octets.length != 4 ||
      octets.any((p) => !RegExp(r'^\d{1,3}$').hasMatch(p)))
    return false;
  final values = octets.map(int.parse).toList();
  if (values.any((n) => n > 255)) return false;
  final [a, b, c, _] = values;
  return !(a == 0 ||
      a == 10 ||
      a == 127 ||
      a >= 224 ||
      (a == 169 && b == 254) ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 192 && (b == 168 || (b == 0 && (c == 0 || c == 2)))) ||
      (a == 100 && b >= 64 && b <= 127) ||
      (a == 198 && (b == 18 || b == 19 || (b == 51 && c == 100))) ||
      (a == 203 && b == 0 && c == 113));
}
