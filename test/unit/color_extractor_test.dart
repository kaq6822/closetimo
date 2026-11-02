// 005 FR-504 — 대표 색상 추출(순수 함수 + 엔진 코덱 디코딩).

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:closetimo/core/vision/color_extractor.dart';
import 'package:closetimo/data/suggestions/attribute_suggester.dart';
import 'package:flutter_test/flutter_test.dart';

/// [regions]의 (색, 비율) 순서로 가로 띠를 칠한 RGBA 이미지. [alpha]가 0인 띠는 투명.
Uint8List _stripes(
  int width,
  int height,
  List<(int argb, double share)> regions,
) {
  final bytes = Uint8List(width * height * 4);
  var row = 0;
  for (final (i, (argb, share)) in regions.indexed) {
    final rows = i == regions.length - 1
        ? height - row
        : (height * share).round();
    for (var y = row; y < row + rows && y < height; y++) {
      for (var x = 0; x < width; x++) {
        final o = (y * width + x) * 4;
        bytes[o] = argb >> 16 & 0xFF;
        bytes[o + 1] = argb >> 8 & 0xFF;
        bytes[o + 2] = argb & 0xFF;
        bytes[o + 3] = argb >> 24 & 0xFF;
      }
    }
    row += rows;
  }
  return bytes;
}

Uint8List _solid(int width, int height, int argb) =>
    _stripes(width, height, [(argb, 1)]);

final _palette = AttributeSuggester.palette;

void main() {
  test('단색 사진은 가장 가까운 팔레트 색 하나', () {
    // 진한 남색 → 네이비
    final px = _solid(40, 40, 0xFF1B2440);
    expect(
      dominantPaletteColors(px, width: 40, height: 40, palette: _palette),
      ['navy'],
    );
    // 청바지 색 → 데님
    expect(
      dominantPaletteColors(
        _solid(40, 40, 0xFF5C7EA8),
        width: 40,
        height: 40,
        palette: _palette,
      ),
      ['denim'],
    );
  });

  test('불투명 사진은 가운데 60%만 본다(배경 무시)', () {
    // 위·아래 20%는 흰 배경, 가운데 60%는 빨강.
    final px = _stripes(50, 50, [
      (0xFFF5F5F5, 0.2),
      (0xFFC2302E, 0.6),
      (0xFFF5F5F5, 0.2),
    ]);
    expect(
      dominantPaletteColors(px, width: 50, height: 50, palette: _palette),
      ['red'],
    );
  });

  test('투명 PNG는 불투명 픽셀만 보고 비중 순으로 최대 3색', () {
    final px = _stripes(60, 60, [
      (0x00000000, 0.3), // 투명 배경
      (0xFF1E1E1E, 0.35), // 검정
      (0xFFC0302F, 0.2), // 빨강
      (0xFFF4F4F2, 0.15), // 흰색
    ]);
    final colors = dominantPaletteColors(
      px,
      width: 60,
      height: 60,
      palette: _palette,
    );
    expect(colors.first, 'black');
    expect(colors.toSet(), {'black', 'red', 'white'});
  });

  test('비중 15% 미만 색은 버린다', () {
    final px = _stripes(60, 60, [
      (0x00000000, 0.2),
      (0xFFD3BC9A, 0.72), // 베이지
      (0xFF2F5DA8, 0.08), // 파랑(작음)
    ]);
    expect(
      dominantPaletteColors(px, width: 60, height: 60, palette: _palette),
      ['beige'],
    );
  });

  test('모두 투명하거나 크기가 맞지 않으면 빈 목록', () {
    expect(
      dominantPaletteColors(
        _solid(10, 10, 0x00000000),
        width: 10,
        height: 10,
        palette: _palette,
      ),
      isEmpty,
    );
    expect(
      dominantPaletteColors(
        Uint8List(8),
        width: 10,
        height: 10,
        palette: _palette,
      ),
      isEmpty,
    );
  });

  testWidgets('엔진 코덱으로 PNG를 디코딩해 추출한다', (tester) async {
    final png = await tester.runAsync(() async {
      final completer = ui.ImmutableBuffer.fromUint8List(
        _solid(120, 160, 0xFF6B6A3C), // 카키
      );
      final buffer = await completer;
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: 120,
        height: 160,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      final codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final colors = await tester.runAsync(
      () => const ColorExtractor().extract(png!, _palette),
    );
    expect(colors, ['khaki']);
  });
}
