import 'package:flutter_test/flutter_test.dart';

import 'package:wol_app/packet_sender.dart';

void main() {
  test('MAC parsing', () {
    expect(parseMacAddress("12:34:56:78:9A:BC"),
        equals([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]));
    expect(parseMacAddress("12-34-56-78-9A-BC"),
        equals([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]));
    expect(parseMacAddress("FF00FF112233"),
        equals([0xFF, 0x00, 0xFF, 0x11, 0x22, 0x33]));
    expect(() => parseMacAddress("12:34:56:78:9A:BC:EF"),
        throwsA(isInstanceOf<FormatException>()));
    expect(() => parseMacAddress("12:34:56:78:9A:BG"),
        throwsA(isInstanceOf<FormatException>()));
    expect(() => parseMacAddress("12:34:56:78:9A:-2"),
        throwsA(isInstanceOf<FormatException>()));
  });
}
