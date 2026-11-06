import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One front-and-back figure for a whole session.
/// Trained muscles are filled in; everything else stays the body color.
class SessionMuscleMap extends StatelessWidget {
  final Set<String> muscles;
  final Color accent;
  final Color body;
  final Color outline;
  final Color caption;

  const SessionMuscleMap({
    super.key,
    required this.muscles,
    required this.accent,
    required this.body,
    required this.outline,
    required this.caption,
  });

  static const _labels = <String, String>{
    'chest': 'Chest',
    'back': 'Back',
    'shoulders': 'Shoulders',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'abs': 'Abs',
    'legs': 'Legs',
  };

  static const _order = [
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'abs',
    'legs',
  ];

  static String? canonical(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('chest') || m.contains('pec')) return 'chest';
    if (m.contains('back') || m.contains('lat') || m.contains('trap')) return 'back';
    if (m.contains('shoulder') || m.contains('delt')) return 'shoulders';
    if (m.contains('bicep')) return 'biceps';
    if (m.contains('tricep')) return 'triceps';
    if (m.contains('ab') || m.contains('core')) return 'abs';
    if (m.contains('leg') ||
        m.contains('quad') ||
        m.contains('ham') ||
        m.contains('glute') ||
        m.contains('calf')) {
      return 'legs';
    }
    return null;
  }

  static Set<String> fromLabels(Iterable<String> raw) {
    return raw.map(canonical).whereType<String>().toSet();
  }

  @override
  Widget build(BuildContext context) {
    final active = muscles.map(canonical).whereType<String>().toSet();
    final names = [
      for (final key in _order)
        if (active.contains(key)) _labels[key]!,
    ];

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _figure(back: false, active: active)),
            const SizedBox(width: 16),
            Expanded(child: _figure(back: true, active: active)),
          ],
        ),
        if (names.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            names.join('  ·  '),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _figure({required bool back, required Set<String> active}) {
    return Column(
      children: [
        SizedBox(
          height: 148,
          width: double.infinity,
          child: CustomPaint(
            painter: _BodyPainter(
              back: back,
              active: active,
              accent: accent,
              body: body,
              outline: outline,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          back ? 'Back' : 'Front',
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: caption,
          ),
        ),
      ],
    );
  }
}

class _BodyPainter extends CustomPainter {
  final bool back;
  final Set<String> active;
  final Color accent;
  final Color body;
  final Color outline;

  const _BodyPainter({
    required this.back,
    required this.active,
    required this.accent,
    required this.body,
    required this.outline,
  });

  bool _on(String group) => active.contains(group);

  @override
  void paint(Canvas canvas, Size size) {
    const dw = 72.0;
    const dh = 128.0;
    final scale = math.min(size.width / dw, size.height / dh);
    canvas.save();
    canvas.translate((size.width - dw * scale) / 2, (size.height - dh * scale) / 2);
    canvas.scale(scale);

    final fill = Paint()..color = body;
    final hot = Paint()..color = accent;
    final stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final silhouette = _silhouette();
    canvas.drawPath(silhouette, fill);
    canvas.drawPath(silhouette, stroke);

    void muscle(bool on, Path path) {
      if (!on) return;
      canvas.save();
      canvas.clipPath(silhouette);
      canvas.drawPath(path, hot);
      canvas.restore();
    }

    muscle(_on('shoulders'), _shoulders());
    if (!back) {
      muscle(_on('chest'), _chest());
      muscle(_on('abs'), _abs());
      muscle(_on('biceps'), _upperArms(inner: true));
    } else {
      muscle(_on('back'), _back());
      muscle(_on('triceps'), _upperArms(inner: false));
    }
    muscle(_on('legs'), _thighs());

    canvas.restore();
  }

  Path _silhouette() {
    Path shape = Path();
    void add(Path part) {
      shape = Path.combine(PathOperation.union, shape, part);
    }

    Path round(Rect rect, double radius) =>
        Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    add(Path()..addOval(Rect.fromCircle(center: const Offset(36, 13), radius: 9)));
    add(round(const Rect.fromLTWH(32, 18, 8, 12), 3));
    add(Path()..addOval(Rect.fromCircle(center: const Offset(20, 32), radius: 8)));
    add(Path()..addOval(Rect.fromCircle(center: const Offset(52, 32), radius: 8)));
    add(round(const Rect.fromLTWH(20, 26, 32, 48), 12));
    add(round(const Rect.fromLTWH(8, 30, 14, 40), 7));
    add(round(const Rect.fromLTWH(50, 30, 14, 40), 7));
    add(round(const Rect.fromLTWH(22, 66, 13, 54), 6.5));
    add(round(const Rect.fromLTWH(37, 66, 13, 54), 6.5));
    return shape;
  }

  Path _shoulders() {
    return Path()
      ..addOval(Rect.fromCircle(center: const Offset(20, 32), radius: 7.5))
      ..addOval(Rect.fromCircle(center: const Offset(52, 32), radius: 7.5));
  }

  Path _chest() {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 31, 11, 15), const Radius.circular(5)))
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(37, 31, 11, 15), const Radius.circular(5)));
  }

  Path _abs() {
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final y = 48.0 + i * 7.2;
      path
        ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(28, y, 6.2, 5.2), const Radius.circular(1.6)))
        ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(37.6, y, 6.2, 5.2), const Radius.circular(1.6)));
    }
    return path;
  }

  Path _upperArms({required bool inner}) {
    if (inner) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 32, 8, 18), const Radius.circular(4)))
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52, 32, 8, 18), const Radius.circular(4)));
    }
    return Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 32, 7, 18), const Radius.circular(4)))
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(56, 32, 7, 18), const Radius.circular(4)));
  }

  Path _back() {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, 28, 20, 12), const Radius.circular(4)))
      ..moveTo(23, 40)
      ..lineTo(49, 40)
      ..quadraticBezierTo(51, 54, 42, 62)
      ..lineTo(30, 62)
      ..quadraticBezierTo(21, 54, 23, 40)
      ..close();
  }

  Path _thighs() {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 70, 10, 26), const Radius.circular(4)))
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, 70, 10, 26), const Radius.circular(4)));
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) {
    return oldDelegate.back != back ||
        oldDelegate.accent != accent ||
        oldDelegate.body != body ||
        oldDelegate.outline != outline ||
        oldDelegate.active.length != active.length ||
        !oldDelegate.active.containsAll(active);
  }
}
