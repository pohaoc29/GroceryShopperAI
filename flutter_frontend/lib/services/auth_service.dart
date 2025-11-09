import 'dart:convert';

String? getUsernameFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final decoded =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final json = jsonDecode(decoded);
    return json['sub'];
  } catch (e) {
    print('[JWT] Error parsing token: $e');
    return null;
  }
}
