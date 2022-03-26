import 'dart:convert';
import 'dart:io';

Future<void> sendWakeUpPacket(String macAddressStr, String ipAddressStr, int port, String? password) async {
  final macAddressBytes = parseMacAddress(macAddressStr);
  final data = buildMagicPacket(password, macAddressBytes);

  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.broadcastEnabled = true;
  final ipAddress = InternetAddress.tryParse(ipAddressStr);
  if (ipAddress == null) throw new SocketException("Invalid IP address");
  final sentBytes = socket.send(data, ipAddress, port);
  if (sentBytes != data.length) throw new SocketException("Error sending packet");
  socket.close();
}

List<int> buildMagicPacket(String? password, List<int> macAddressBytes) {
  final data = List.filled(102 + (password?.length ?? 0), 0);
  data.fillRange(0, 6, 0xFF);
  for (int i = 0; i < 16; ++i) {
    data.setRange(6 + 6 * i, 12 + 6 * i, macAddressBytes);
  }
  if (password != null) {
    final encoder = new Utf8Encoder();
    final utf8Bytes = encoder.convert(password);
    data.setRange(102, 102 + password.length, utf8Bytes);
  }
  return data;
}

List<int> parseMacAddress(String str) {
  str = str.trim().replaceAll(":", "").replaceAll("-", "");
  if (str.length != 12) throw new FormatException("Invalid MAC address");

  final result = List.filled(6, 0);
  for (int i = 0; i < 6; ++i) {
    result[i] = int.parse(str.substring(i * 2, (i + 1) * 2), radix: 16);
  }
  return result;
}
