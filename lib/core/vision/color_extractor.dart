// 005 FR-504 — 사진의 대표 색상 추출. 기기 안에서만 계산하며 네트워크를 쓰지 않는다.
//
// 1. 엔진 코덱으로 사진을 작게(가로 [sampleWidth]px) 디코딩한다(네이티브, 빠름).
// 2. 투명 PNG(배경 제거본)는 불투명 픽셀만, 일반 사진은 가운데 60%만 본다.
// 3. CIELAB 공간에서 k-means(k=4)로 묶고, 각 묶음을 팔레트의 가장 가까운 색으로 바꾼다.
// 4. 비중이 [minShare] 이상인 색을 비중 순으로 최대 [maxColors]개 돌려준다.
//
// 팔레트(코드·ARGB)는 호출자가 준다. core는 데이터 카탈로그를 알지 못한다.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// 추출에 쓰는 축소 가로 크기. 64px이면 4,096픽셀 안팎이라 k-means가 수 ms에 끝난다.
const int sampleWidth = 64;

/// 대표 색상으로 인정하는 최소 비중.
const double minShare = 0.15;

/// 돌려줄 최대 색상 수.
const int maxColors = 3;

class ColorExtractor {
  const ColorExtractor();

  /// [bytes](JPEG·PNG 등)의 대표 색을 [palette] 키 목록으로 돌려준다. 실패하면 빈 목록.
  Future<List<String>> extract(
    Uint8List bytes,
    Map<String, int> palette,
  ) async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: sampleWidth,
    );
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final data = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        if (data == null) return const [];
        return dominantPaletteColors(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          width: image.width,
          height: image.height,
          palette: palette,
        );
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}

/// RGBA 픽셀([rgba], 행 우선)에서 [palette] 대표 색을 고른다. 순수 함수라 단위 테스트한다.
List<String> dominantPaletteColors(
  Uint8List rgba, {
  required int width,
  required int height,
  required Map<String, int> palette,
}) {
  if (palette.isEmpty || width <= 0 || height <= 0) return const [];
  final pixelCount = width * height;
  if (rgba.length < pixelCount * 4) return const [];

  // 알파가 있는 픽셀이 하나라도 있으면(배경 제거본) 불투명 픽셀만 쓴다.
  var hasTransparency = false;
  for (var i = 3; i < pixelCount * 4; i += 4) {
    if (rgba[i] < 250) {
      hasTransparency = true;
      break;
    }
  }
  final points = <_Lab>[];
  final x0 = (width * 0.2).floor(), x1 = (width * 0.8).ceil();
  final y0 = (height * 0.2).floor(), y1 = (height * 0.8).ceil();
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final o = (y * width + x) * 4;
      if (hasTransparency) {
        if (rgba[o + 3] < 128) continue;
      } else if (x < x0 || x >= x1 || y < y0 || y >= y1) {
        continue;
      }
      points.add(_Lab.fromRgb(rgba[o], rgba[o + 1], rgba[o + 2]));
    }
  }
  if (points.isEmpty) return const [];

  final paletteLab = {
    for (final e in palette.entries)
      e.key: _Lab.fromRgb(
        e.value >> 16 & 0xFF,
        e.value >> 8 & 0xFF,
        e.value & 0xFF,
      ),
  };
  final centers = _kMeans(points, k: math.min(4, points.length));
  final share = <String, double>{};
  for (final (center, count) in centers) {
    var best = paletteLab.keys.first;
    var bestDistance = double.infinity;
    for (final e in paletteLab.entries) {
      final d = center.distanceSquared(e.value);
      if (d < bestDistance) {
        bestDistance = d;
        best = e.key;
      }
    }
    share[best] = (share[best] ?? 0) + count / points.length;
  }
  final ranked = share.entries.where((e) => e.value >= minShare).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [for (final e in ranked.take(maxColors)) e.key];
}

/// 결정적 k-means. 초기 중심은 밝기 순으로 고르게 뽑아 실행마다 결과가 같다.
List<(_Lab, int)> _kMeans(List<_Lab> points, {required int k}) {
  final sorted = [...points]..sort((a, b) => a.l.compareTo(b.l));
  var centers = [
    for (var i = 0; i < k; i++) sorted[((i + 0.5) * sorted.length / k).floor()],
  ];
  final assignment = List<int>.filled(points.length, 0);
  for (var iteration = 0; iteration < 12; iteration++) {
    var changed = false;
    for (var i = 0; i < points.length; i++) {
      var best = 0;
      var bestDistance = double.infinity;
      for (var j = 0; j < centers.length; j++) {
        final d = points[i].distanceSquared(centers[j]);
        if (d < bestDistance) {
          bestDistance = d;
          best = j;
        }
      }
      if (assignment[i] != best) {
        assignment[i] = best;
        changed = true;
      }
    }
    final sums = List.generate(centers.length, (_) => [0.0, 0.0, 0.0, 0.0]);
    for (var i = 0; i < points.length; i++) {
      final s = sums[assignment[i]];
      s[0] += points[i].l;
      s[1] += points[i].a;
      s[2] += points[i].b;
      s[3] += 1;
    }
    centers = [
      for (var j = 0; j < centers.length; j++)
        sums[j][3] == 0
            ? centers[j]
            : _Lab(
                sums[j][0] / sums[j][3],
                sums[j][1] / sums[j][3],
                sums[j][2] / sums[j][3],
              ),
    ];
    if (!changed && iteration > 0) break;
  }
  final counts = List<int>.filled(centers.length, 0);
  for (final a in assignment) {
    counts[a]++;
  }
  return [
    for (var j = 0; j < centers.length; j++)
      if (counts[j] > 0) (centers[j], counts[j]),
  ];
}

/// CIELAB(D65) 색 좌표.
class _Lab {
  const _Lab(this.l, this.a, this.b);

  factory _Lab.fromRgb(int r, int g, int b) {
    double linear(int c) {
      final v = c / 255.0;
      return v <= 0.04045
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final rl = linear(r), gl = linear(g), bl = linear(b);
    final x = (rl * 0.4124 + gl * 0.3576 + bl * 0.1805) / 0.95047;
    final y = rl * 0.2126 + gl * 0.7152 + bl * 0.0722;
    final z = (rl * 0.0193 + gl * 0.1192 + bl * 0.9505) / 1.08883;
    double f(double t) =>
        t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
    return _Lab(116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)));
  }

  final double l;
  final double a;
  final double b;

  double distanceSquared(_Lab o) {
    final dl = l - o.l, da = a - o.a, db = b - o.b;
    return dl * dl + da * da + db * db;
  }
}
